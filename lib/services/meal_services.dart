import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Core/constants.dart';

class MealService {
  static const _mealBase = 'https://www.themealdb.com/api/json/v1/1';
  static const _usdaBase = 'https://api.nal.usda.gov/fdc/v1';

  // USDA nutrient IDs we care about
  static const _nidCalories = 1008;
  static const _nidProtein = 1003;
  static const _nidCarbs = 1005;
  static const _nidFat = 1004;
  static const _nidFiber = 1079;
  static const _nidSugar = 2000;
  static const _nidSodium = 1093;
  static const _nidCholesterol = 1253;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchMealsByIngredients(
    List<String> ingredients,
  ) async {
    final Map<String, int> idMatchCount = {};
    for (final ingredient in ingredients) {
      final searchTerm = _simplifyIngredient(ingredient);
      final encoded = Uri.encodeComponent(searchTerm);
      final res = await http.get(Uri.parse('$_mealBase/filter.php?i=$encoded'));
      if (res.statusCode != 200) continue;
      final meals = jsonDecode(res.body)['meals'];
      if (meals == null) continue;
      for (final meal in meals as List) {
        final id = meal['idMeal'] as String;
        idMatchCount[id] = (idMatchCount[id] ?? 0) + 1;
      }
    }

    if (idMatchCount.isEmpty) return [];

    // Only keep meals that matched AT LEAST ONE of the user's ingredients
    // (idMatchCount only contains meals that appeared in at least one filter result,
    // so all entries already have count >= 1 — but we sort best matches first)
    final topIds =
        (idMatchCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .map((e) => e.key)
            .toList();

    final results = await Future.wait(topIds.map(_lookupMealWithNutrition));
    final meals = results.whereType<Map<String, dynamic>>().toList();

    // Secondary filter — after full lookup, verify at least one recipe ingredient
    // actually matches back to the user's simplified ingredient list
    final simplifiedUserIngredients = ingredients
        .map((i) => _simplifyIngredient(i).toLowerCase())
        .toList();

    return meals.where((meal) {
      final recipeIngredients = (meal['ingredients'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (e) =>
                _simplifyIngredient((e['name'] ?? '').toString().toLowerCase()),
          )
          .toList();

      return recipeIngredients.any(
        (ri) => simplifiedUserIngredients.any(
          (ui) => ri.contains(ui) || ui.contains(ri),
        ),
      );
    }).toList();
  }

  /// Strips adjectives and descriptors so "boneless chicken breast" → "chicken"
  static String _simplifyIngredient(String ingredient) {
    const descriptors = [
      'boneless',
      'skinless',
      'fresh',
      'frozen',
      'dried',
      'ground',
      'chopped',
      'sliced',
      'diced',
      'minced',
      'cooked',
      'raw',
      'whole',
      'half',
      'large',
      'small',
      'medium',
      'big',
      'lean',
      'thick',
      'thin',
      'baby',
      'organic',
      'ripe',
      'breast',
      'thigh',
      'fillet',
      'wing',
      'leg',
    ];

    final words = ingredient.toLowerCase().trim().split(RegExp(r'\s+'));
    final filtered = words.where((w) => !descriptors.contains(w)).toList();

    // Return the filtered result, fallback to original if nothing left
    return filtered.isEmpty ? ingredient : filtered.join(' ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — MealDB
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _lookupMealWithNutrition(
    String id,
  ) async {
    final res = await http.get(Uri.parse('$_mealBase/lookup.php?i=$id'));
    if (res.statusCode != 200) return null;

    final meals = jsonDecode(res.body)['meals'] as List?;
    if (meals == null || meals.isEmpty) return null;

    final raw = meals[0] as Map<String, dynamic>;
    final meal = _parseMeal(raw);

    // Fetch USDA nutrition for every ingredient in this meal
    final ingredients = meal['ingredients'] as List<Map<String, String>>;
    final nutrition = await _fetchNutritionForMeal(ingredients);
    meal['nutrition'] = nutrition;

    return meal;
  }

  static Map<String, dynamic> _parseMeal(Map<String, dynamic> raw) {
    final List<Map<String, String>> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final name = (raw['strIngredient$i'] ?? '').toString().trim();
      final measure = (raw['strMeasure$i'] ?? '').toString().trim();
      if (name.isNotEmpty) ingredients.add({'name': name, 'measure': measure});
    }

    return {
      'id': raw['idMeal'] ?? '',
      'name': raw['strMeal'] ?? '',
      'category': raw['strCategory'] ?? '',
      'area': raw['strArea'] ?? '',
      'instructions': raw['strInstructions'] ?? '',
      'thumbnail': raw['strMealThumb'] ?? '',
      'youtubeUrl': raw['strYoutube'] ?? '',
      'tags': raw['strTags'] ?? '',
      'ingredients': ingredients,
      'description': '${raw['strCategory'] ?? ''} · ${raw['strArea'] ?? ''}',
      'time': _estimateTime(ingredients.length),
      'difficulty': _estimateDifficulty(ingredients.length),
      'calories': 'Loading…', // replaced after USDA fetch
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — USDA FoodData Central
  // ─────────────────────────────────────────────────────────────────────────

  /// Queries USDA for each ingredient and sums nutrients across all of them.
  static Future<Map<String, dynamic>> _fetchNutritionForMeal(
    List<Map<String, String>> ingredients,
  ) async {
    // Run all ingredient lookups in parallel
    final results = await Future.wait(
      ingredients.map((ing) => _fetchNutrientsForIngredient(ing['name']!)),
    );

    // Sum all nutrients
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    double fiber = 0, sugar = 0, sodium = 0, cholesterol = 0;

    for (final n in results) {
      if (n == null) continue;
      calories += n['calories'] ?? 0;
      protein += n['protein'] ?? 0;
      carbs += n['carbs'] ?? 0;
      fat += n['fat'] ?? 0;
      fiber += n['fiber'] ?? 0;
      sugar += n['sugar'] ?? 0;
      sodium += n['sodium'] ?? 0;
      cholesterol += n['cholesterol'] ?? 0;
    }

    return {
      'calories': '${calories.round()} kcal',
      'protein': '${protein.round()}g',
      'carbs': '${carbs.round()}g',
      'fat': '${fat.round()}g',
      'fiber': '${fiber.round()}g',
      'sugar': '${sugar.round()}g',
      'sodium': '${sodium.round()}mg',
      'cholesterol': '${cholesterol.round()}mg',
    };
  }

  /// Searches USDA for one ingredient name and returns its nutrient values
  /// per 100g (the default serving USDA returns).
  static Future<Map<String, double>?> _fetchNutrientsForIngredient(
    String ingredientName,
  ) async {
    try {
      final uri = Uri.parse(
        '$_usdaBase/foods/search'
        '?query=${Uri.encodeComponent(ingredientName)}'
        '&dataType=Foundation,SR%20Legacy' // raw/whole foods only
        '&pageSize=1'
        '&api_key=${AppConstants.usdaApiKey}',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = body['foods'] as List?;
      if (foods == null || foods.isEmpty) return null;

      final food = foods[0] as Map<String, dynamic>;
      final nutrients = food['foodNutrients'] as List? ?? [];

      double? _get(int nutrientId) {
        for (final n in nutrients) {
          if (n['nutrientId'] == nutrientId) {
            return (n['value'] as num?)?.toDouble();
          }
        }
        return null;
      }

      return {
        'calories': _get(_nidCalories) ?? 0,
        'protein': _get(_nidProtein) ?? 0,
        'carbs': _get(_nidCarbs) ?? 0,
        'fat': _get(_nidFat) ?? 0,
        'fiber': _get(_nidFiber) ?? 0,
        'sugar': _get(_nidSugar) ?? 0,
        'sodium': _get(_nidSodium) ?? 0,
        'cholesterol': _get(_nidCholesterol) ?? 0,
      };
    } catch (_) {
      return null;
    }
  }

  static String _estimateTime(int n) => n <= 5
      ? '~15 min'
      : n <= 10
      ? '~30 min'
      : '~45 min';

  static String _estimateDifficulty(int n) => n <= 5
      ? 'Easy'
      : n <= 10
      ? 'Medium'
      : 'Advanced';
}
