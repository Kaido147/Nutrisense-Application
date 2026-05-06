import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionService {
  const NutritionService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get _uid => _auth.currentUser?.uid;

  // Save meal to recentMeals.
  Future<void> saveMeal(Map<String, dynamic> meal) async {
    final uid = _uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final recentMealRef = userRef.collection('recentMeals').doc();
    final mealLogRef = userRef.collection('mealLogs').doc(recentMealRef.id);
    final nutrition = _safeNutritionMap(meal['nutrition']);
    final calories = _parseCalories(meal);
    final protein = _parseNutrient(nutrition['protein']);
    final dateKey = _todayKey();
    final timestamp = FieldValue.serverTimestamp();

    final recentMeal = {
      'name': meal['name'] ?? '',
      'type': meal['category'] ?? meal['type'] ?? 'Meal',
      'calories': calories,
      'thumbnail': meal['thumbnail'] ?? '',
      'ingredients': meal['ingredients'] ?? [],
      'servingAmount': meal['servingAmount'] ?? '',
      'servingUnit': meal['servingUnit'] ?? '',
      'time': meal['time'] ?? '',
      'notes': meal['notes'] ?? '',
      'nutritionBasis': meal['nutritionBasis'] ?? '',
      'nutrition': {
        'calories': nutrition['calories'] ?? calories,
        // Core macros
        'protein': nutrition['protein'] ?? '0g',
        'carbs': nutrition['carbs'] ?? '0g',
        'fat': nutrition['fat'] ?? '0g',
        // Fats
        'saturatedFat': nutrition['saturatedFat'] ?? '0g',
        'transFat': nutrition['transFat'] ?? '0g',
        // Carbs
        'fiber': nutrition['fiber'] ?? '0g',
        'sugar': nutrition['sugar'] ?? '0g',
        // Minerals & other
        'sodium': nutrition['sodium'] ?? '0mg',
        'cholesterol': nutrition['cholesterol'] ?? '0mg',
        'potassium': nutrition['potassium'] ?? '0mg',
        'calcium': nutrition['calcium'] ?? '0mg',
        'iron': nutrition['iron'] ?? '0mg',
        'vitaminD': nutrition['vitaminD'] ?? '0mcg',
      },
      'dateKey': dateKey,
      'savedAt': timestamp,
      'initialized': false,
    };

    final mealLog = {
      'mealName': meal['name'] ?? '',
      'mealType': meal['category'] ?? meal['type'] ?? 'Meal',
      'ingredients': _ingredientNames(meal['ingredients']),
      'caloriesEstimate': calories.round(),
      'proteinEstimate': protein.round(),
      'tags': const <String>[],
      'matchedMood': null,
      'dietaryPreference': null,
      'avoidedAllergies': const <String>[],
      'medicalNotes': const <String>[],
      'source': 'nutrition log',
      'dateKey': dateKey,
      'loggedAt': timestamp,
    };

    final batch = _firestore.batch();
    batch.set(recentMealRef, recentMeal);
    batch.set(mealLogRef, mealLog);
    await batch.commit();
  }

  // Get recent meals.
  Future<List<Map<String, dynamic>>> getRecentMeals() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('recentMeals')
        .orderBy('savedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => {'docId': doc.id, ...doc.data()})
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchRecentMeals() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('recentMeals')
        .orderBy('savedAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'docId': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Delete a meal by its Firestore doc ID.
  Future<void> deleteMeal(String docId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('recentMeals')
          .doc(docId)
          .delete();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('mealLogs')
          .doc(docId)
          .delete();
    } catch (e) {
      // ignore
    }
  }

  // Helpers.

  /// Safely converts any map type returned by Firestore or JSON decoding
  /// into a string-keyed map without throwing a cast error.
  static Map<String, dynamic> _safeNutritionMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  num _parseCalories(Map<String, dynamic> meal) {
    final raw = meal['nutrition']?['calories'] ?? meal['calories'] ?? 0;
    if (raw is int) return raw;
    if (raw is double) return raw % 1 == 0 ? raw.toInt() : raw;
    if (raw is String) {
      final value = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (value == null) return 0;
      return value % 1 == 0 ? value.toInt() : value;
    }
    return 0;
  }

  double _parseNutrient(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  List<String> _ingredientNames(dynamic raw) {
    if (raw is! List) return const <String>[];

    return raw
        .map((item) {
          if (item is String) return item.trim();
          if (item is Map) {
            return (item['name'] ?? item['ingredient'] ?? '').toString().trim();
          }
          return '';
        })
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
