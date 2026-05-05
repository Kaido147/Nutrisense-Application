import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Core/constants.dart';

class MealService {
  static const _mealBase = 'https://www.themealdb.com/api/json/v1/1';
  static const _usdaBase = 'https://api.nal.usda.gov/fdc/v1';

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
    List<String> ingredients, {
    String mealType = 'Any',
    List<String> dietaryPrefs = const [],
  }) async {
    // ── STEP 1: Query TheMealDB once per ingredient ──────────────────────────
    // TheMealDB filter only supports ONE ingredient per request.
    // We fetch each separately and track how many user ingredients each meal matches.
    final Map<String, int> idMatchCount = {};

    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final searchTerm = _simplifyIngredient(ingredient);
      if (searchTerm.isEmpty) continue;

      // ── Avoid rate-limiting on rapid sequential requests ──────────────────
      if (i > 0) await Future.delayed(const Duration(milliseconds: 300));

      final encoded = Uri.encodeComponent(searchTerm);
      final res = await http.get(Uri.parse('$_mealBase/filter.php?i=$encoded'));
      if (res.statusCode != 200) continue;

      final meals = jsonDecode(res.body)['meals'];
      if (meals == null) continue;

      for (final meal in meals as List) {
        final id = meal['idMeal'] as String;
        // Each ingredient search that returns this meal adds 1 to its count.
        idMatchCount[id] = (idMatchCount[id] ?? 0) + 1;
      }
    }

    if (idMatchCount.isEmpty) return [];

    // ── STEP 2: Take top 10 meals by match count ─────────────────────────────
    // Meals matched by more of the user's ingredients rank higher.
    final topIds =
        (idMatchCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .map((e) => e.key)
            .toList();

    // ── STEP 3: Fetch full detail + nutrition for each ───────────────────────
    final results = await Future.wait(topIds.map(_lookupMealWithNutrition));

    // ── STEP 4: Remove nulls ─────────────────────────────────────────────────
    var filtered = results.whereType<Map<String, dynamic>>().toList();

    // ── STEP 5: Filter by meal type ──────────────────────────────────────────
    if (mealType != 'Any') {
      filtered = filtered.where((meal) {
        final category = (meal['category'] as String).toLowerCase();
        switch (mealType) {
          case 'Breakfast':
            return category == 'breakfast';
          case 'Lunch':
            return [
              'beef',
              'chicken',
              'lamb',
              'pork',
              'seafood',
              'pasta',
              'vegetarian',
              'vegan',
              'goat',
              'miscellaneous',
              'side',
            ].contains(category);
          case 'Dinner':
            return [
              'beef',
              'chicken',
              'lamb',
              'pork',
              'seafood',
              'pasta',
              'vegetarian',
              'vegan',
              'goat',
            ].contains(category);
          case 'Snack':
            return [
              'starter',
              'miscellaneous',
              'side',
              'dessert',
            ].contains(category);
          default:
            return true;
        }
      }).toList();
    }

    // ── STEP 6: Filter by dietary preferences ────────────────────────────────
    if (dietaryPrefs.isNotEmpty) {
      filtered = filtered.where((meal) {
        final category = (meal['category'] as String).toLowerCase();
        final ingredientNames =
            (meal['ingredients'] as List<Map<String, String>>)
                .map((i) => (i['name'] ?? '').toLowerCase())
                .toList();

        for (final pref in dietaryPrefs) {
          if (!_matchesDietaryPref(pref, category, ingredientNames)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // ── STEP 7: Sort by dietary preference nutrition ──────────────────────────
    if (dietaryPrefs.isNotEmpty) {
      filtered.sort((a, b) {
        final aNut = a['nutrition'] as Map<String, dynamic>? ?? {};
        final bNut = b['nutrition'] as Map<String, dynamic>? ?? {};

        // Helper to parse "120g" → 120.0
        double parse(dynamic val) =>
            double.tryParse(
              val?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
            ) ??
            0;

        if (dietaryPrefs.contains('High-Protein')) {
          return parse(bNut['protein']).compareTo(parse(aNut['protein']));
        }
        if (dietaryPrefs.contains('Low-Carb')) {
          return parse(aNut['carbs']).compareTo(parse(bNut['carbs']));
        }
        if (dietaryPrefs.contains('Vegan') ||
            dietaryPrefs.contains('Vegetarian')) {
          // Sort by lowest calories — lighter plant-based meals first
          return parse(aNut['calories']).compareTo(parse(bNut['calories']));
        }
        if (dietaryPrefs.contains('Gluten-free') ||
            dietaryPrefs.contains('Dairy-free')) {
          // Sort by highest fiber — whole food focus
          return parse(bNut['fiber']).compareTo(parse(aNut['fiber']));
        }
        return 0;
      });
    }

    return filtered;
  }

  static bool _matchesDietaryPref(
    String pref,
    String category,
    List<String> ingredients,
  ) {
    bool hasAny(List<String> keywords) =>
        ingredients.any((i) => keywords.any((k) => i.contains(k)));

    switch (pref) {
      case 'Vegetarian':
        return category == 'vegetarian' || category == 'vegan';
      case 'Vegan':
        return category == 'vegan';
      case 'Gluten-free':
        return !hasAny([
          'flour',
          'wheat',
          'barley',
          'rye',
          'bread',
          'pasta',
          'noodle',
        ]);
      case 'Dairy-free':
        return !hasAny(['milk', 'cheese', 'butter', 'cream', 'yogurt', 'whey']);
      case 'Low-Carb':
        return !hasAny([
          'rice',
          'pasta',
          'bread',
          'potato',
          'flour',
          'sugar',
          'noodle',
        ]);
      case 'High-Protein':
        return [
          'beef',
          'chicken',
          'lamb',
          'pork',
          'seafood',
          'goat',
        ].contains(category);
      default:
        return true;
    }
  }

  /// Strips adjectives/descriptors so "boneless chicken breast" → "chicken".
  /// Kept minimal — only strips words that TheMealDB won't understand anyway.
  static String _simplifyIngredient(String ingredient) {
    const descriptors = {
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
    };

    final words = ingredient.toLowerCase().trim().split(RegExp(r'\s+'));
    final filtered = words.where((w) => !descriptors.contains(w)).toList();
    return filtered.isEmpty
        ? ingredient.toLowerCase().trim()
        : filtered.join(' ');
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
      'calories': 'Loading…',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — USDA FoodData Central
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _fetchNutritionForMeal(
    List<Map<String, String>> ingredients,
  ) async {
    final results = await Future.wait(
      ingredients.map((ing) => _fetchNutrientsForIngredient(ing['name']!)),
    );

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

  static Future<Map<String, double>?> _fetchNutrientsForIngredient(
    String ingredientName,
  ) async {
    try {
      final uri = Uri.parse(
        '$_usdaBase/foods/search'
        '?query=${Uri.encodeComponent(ingredientName)}'
        '&dataType=Foundation,SR%20Legacy'
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
