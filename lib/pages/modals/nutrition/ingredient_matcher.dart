// ingredient_matcher.dart
//
// Name-only ingredient matching with GREEN / ORANGE / RED classification.
// Quantity is NEVER used for matching — only for optional display hints.
//
// ── Match status ──────────────────────────────────────────────────────────────
//
//  GREEN  — same base food AND same form  (exact after normalization)
//           e.g. "whole chicken"          vs "whole chicken"
//               "chicken breast"         vs "chicken breast"
//
//  ORANGE — same base food, different form  (one normalizes into the other)
//           e.g. "chicken"               vs "chicken breast"
//               "boneless chicken breast" vs "chicken thigh"
//
//  RED    — different ingredient entirely  (user chip not used in recipe)
//           e.g. "tomato"                vs recipe that has no tomato
//
//  MISSING — recipe ingredient not found in user's fridge
//           e.g. recipe needs "garlic" but user didn't add it
//
// IMPORTANT RULE: "chicken" ≠ "chicken stock" / "chicken sauce" / "chicken broth"
// Compound qualifiers create a brand-new food identity.
//
// ─────────────────────────────────────────────────────────────────────────────

// ── 1. COMPOUND-WORD BLOCKLIST ────────────────────────────────────────────────
//
// Any ingredient containing one of these words is a DISTINCT ingredient.
// "chicken" shares a word with "chicken stock", but stock is a qualifier →
// they will NEVER match unless both sides normalize to exactly the same string.
//
const _compoundQualifiers = {
  // Liquid / processed derivatives
  'stock', 'broth', 'sauce', 'gravy', 'powder', 'paste', 'extract',
  'concentrate', 'syrup', 'juice', 'vinegar', 'oil', 'butter',
  'cream', 'milk', 'cheese', 'yogurt', 'yoghurt', 'spread',
  'jam', 'jelly', 'puree', 'purée', 'soup', 'stew', 'curry',

  // Processed / manufactured forms
  'flakes', 'chips', 'crackers', 'biscuit', 'biscuits',
  'flour', 'starch', 'sugar', 'salt', 'seasoning', 'spice',
  'mix', 'blend', 'dressing', 'marinade', 'relish', 'chutney',

  // Structural qualifiers that make a new food identity
  'noodles', 'noodle', 'pasta', 'rice', 'bread', 'cake',
  'wrap', 'roll', 'dumpling', 'patty', 'nugget', 'nuggets',
  'sausage', 'meatball', 'burger',
};

// ── 2. DESCRIPTOR WORDS — stripped during normalization ──────────────────────
//
// Describe the state/quality of an ingredient, not its identity.
// Stripping these lets "boneless chicken breast" → "chicken breast".
//
const _descriptors = {
  // Prep state
  'boneless', 'skinless', 'deboned', 'trimmed',
  'fresh', 'frozen', 'dried', 'dehydrated', 'canned', 'tinned',
  'ground', 'minced', 'chopped', 'sliced', 'diced', 'grated', 'shredded',
  'cooked', 'raw', 'blanched', 'roasted', 'smoked', 'pickled', 'fermented',

  // Size / shape
  'whole', 'half', 'large', 'small', 'medium', 'big', 'mini',
  'thick', 'thin', 'baby', 'jumbo',

  // Quality / origin
  'organic', 'ripe', 'lean', 'fat-free', 'low-fat',
  'white', 'brown', 'dark', 'light', 'wild', 'farmed',
};

// ── 3. CUT WORDS — kept in fullNorm, stripped in baseNorm ────────────────────
//
// These identify a specific cut or part. They survive in fullNorm (so
// "chicken breast" ≠ "chicken thigh" = ORANGE, not GREEN), but are stripped
// in baseNorm (so both still share base "chicken" → qualify for ORANGE at all).
//
const _cutWords = {
  'breast',
  'thigh',
  'leg',
  'wing',
  'drumstick',
  'loin',
  'belly',
  'rib',
  'ribs',
  'shank',
  'shoulder',
  'neck',
  'fillet',
  'filet',
  'steak',
  'chop',
  'rack',
  'liver',
  'heart',
  'kidney',
  'tongue',
  'cheek',
};

// ── 4. UNIT TOKENS — quantity parsing only ────────────────────────────────────
const _unitTokens = {
  'g',
  'kg',
  'ml',
  'l',
  'cup',
  'cups',
  'tbsp',
  'tsp',
  'tablespoon',
  'tablespoons',
  'teaspoon',
  'teaspoons',
  'oz',
  'lb',
  'lbs',
  'pound',
  'pounds',
  'pinch',
  'clove',
  'cloves',
  'slice',
  'slices',
  'pcs',
  'pc',
};

// ─────────────────────────────────────────────────────────────────────────────
// Public enums & data classes
// ─────────────────────────────────────────────────────────────────────────────

enum MatchStatus {
  green, // exact same food + form
  orange, // same base food, different form
  red, // user ingredient not used in this recipe
  missing, // recipe ingredient not found in user's fridge
}

/// Match detail for a single recipe ingredient.
class IngredientMatchDetail {
  /// Original recipe ingredient name (e.g. "chicken breast").
  final String recipeIngredient;

  /// The user ingredient string that matched, or null if missing.
  final String? matchedUserIngredient;

  final MatchStatus status;

  /// Quantity hint — never affects matching.
  final QuantityHint? quantityHint;

  const IngredientMatchDetail({
    required this.recipeIngredient,
    required this.matchedUserIngredient,
    required this.status,
    this.quantityHint,
  });
}

/// Status of a single user ingredient when viewed against a recipe.
class UserIngredientStatus {
  final String userIngredient;

  /// green / orange = used in recipe (different fidelity)
  /// red            = not used in this recipe at all
  final MatchStatus status;

  final QuantityHint? quantityHint;

  const UserIngredientStatus({
    required this.userIngredient,
    required this.status,
    this.quantityHint,
  });
}

/// Top-level result returned by [matchIngredients].
class MatchResult {
  /// 0.0 – 1.0
  final double score;

  /// Recipe ingredient names that were matched (GREEN or ORANGE).
  final List<String> matchedIngredients;

  /// Recipe ingredient names that were NOT found in the user's fridge.
  final List<String> missingIngredients;

  /// Per-recipe-ingredient detail (status, matched user ingredient, hint).
  final List<IngredientMatchDetail> recipeDetails;

  /// Per-user-ingredient status against this recipe.
  final List<UserIngredientStatus> userStatuses;

  const MatchResult({
    required this.score,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.recipeDetails,
    required this.userStatuses,
  });

  /// 0–100 rounded percentage.
  int get scorePercent => (score * 100).round();

  @override
  String toString() =>
      'MatchResult(score: $scorePercent%, '
      'matched: $matchedIngredients, '
      'missing: $missingIngredients)';
}

/// Optional quantity comparison — NEVER affects match status.
class QuantityHint {
  final String ingredientName;
  final double userAmount;
  final double recipeAmount;
  final String unit;

  bool get mayNotBeEnough => userAmount < (recipeAmount - 0.001);

  const QuantityHint({
    required this.ingredientName,
    required this.userAmount,
    required this.recipeAmount,
    required this.unit,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Matches [userIngredients] against [recipeIngredients] by name only.
///
/// [userIngredients]   — `[{'ingredient': 'chicken', 'quantity': '100 g'}, ...]`
/// [recipeIngredients] — `[{'name': 'chicken breast', 'measure': '200 g'}, ...]`
MatchResult matchIngredients({
  required List<Map<String, String>> userIngredients,
  required List<Map<String, String>> recipeIngredients,
}) {
  final recipeItems = recipeIngredients.map(_RecipeItem.from).toList();
  final userItems = userIngredients.map(_UserItem.from).toList();

  final recipeDetails = <IngredientMatchDetail>[];
  final matched = <String>[];
  final missing = <String>[];

  // Track the best status per user ingredient across all recipe ingredients.
  final Map<String, MatchStatus> userIngToStatus = {};

  for (final recipe in recipeItems) {
    _UserItem? bestUser;
    MatchStatus bestStatus = MatchStatus.missing;

    for (final user in userItems) {
      final status = _classify(user, recipe);
      if (status == MatchStatus.green) {
        bestUser = user;
        bestStatus = MatchStatus.green;
        break; // can't improve on GREEN
      }
      if (status == MatchStatus.orange && bestStatus != MatchStatus.green) {
        bestUser = user;
        bestStatus = MatchStatus.orange;
      }
    }

    QuantityHint? hint;
    if (bestUser != null) {
      matched.add(recipe.original);
      hint = _buildHint(recipe, bestUser);

      // Keep highest-fidelity status for each user ingredient.
      final prev = userIngToStatus[bestUser.original];
      if (prev == null || _statusRank(bestStatus) > _statusRank(prev)) {
        userIngToStatus[bestUser.original] = bestStatus;
      }
    } else {
      missing.add(recipe.original);
    }

    recipeDetails.add(
      IngredientMatchDetail(
        recipeIngredient: recipe.original,
        matchedUserIngredient: bestUser?.original,
        status: bestUser != null ? bestStatus : MatchStatus.missing,
        quantityHint: hint,
      ),
    );
  }

  // User-side statuses: anything not matched to a recipe ingredient → RED.
  final userStatuses = userItems.map((u) {
    final status = userIngToStatus[u.original] ?? MatchStatus.red;
    final relatedDetail = recipeDetails.firstWhereOrNull(
      (d) => d.matchedUserIngredient == u.original,
    );
    return UserIngredientStatus(
      userIngredient: u.original,
      status: status,
      quantityHint: relatedDetail?.quantityHint,
    );
  }).toList();

  final total = recipeItems.length;
  final score = total == 0 ? 0.0 : matched.length / total;

  return MatchResult(
    score: score,
    matchedIngredients: matched,
    missingIngredients: missing,
    recipeDetails: recipeDetails,
    userStatuses: userStatuses,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Core classification
// ─────────────────────────────────────────────────────────────────────────────

MatchStatus _classify(_UserItem user, _RecipeItem recipe) {
  // ── COMPOUND GUARD ─────────────────────────────────────────────────────────
  // If either side has a compound qualifier, only allow a match when both
  // sides normalize to the EXACT same string.
  // This is what prevents "chicken" matching "chicken stock".
  if (_hasCompound(recipe.original) || _hasCompound(user.original)) {
    return (user.fullNorm == recipe.fullNorm)
        ? MatchStatus.green
        : MatchStatus.missing;
  }

  // ── GREEN: identical after full normalization (descriptors stripped) ────────
  if (user.fullNorm == recipe.fullNorm) return MatchStatus.green;

  // ── ORANGE: same base food (cuts also stripped), different form ─────────────
  if (user.baseNorm == recipe.baseNorm && user.baseNorm.isNotEmpty) {
    return MatchStatus.orange;
  }

  // ── Directional subset check using fullNorm words ───────────────────────────
  // e.g. user fullNorm "chicken" ⊂ recipe fullNorm words ["chicken", "breast"]
  final uWords = user.fullNorm.split(RegExp(r'\s+'));
  final rWords = recipe.fullNorm.split(RegExp(r'\s+'));

  final uInR = uWords.isNotEmpty && uWords.every((w) => rWords.contains(w));
  final rInU = rWords.isNotEmpty && rWords.every((w) => uWords.contains(w));

  if (uInR || rInU) {
    return (user.fullNorm == recipe.fullNorm)
        ? MatchStatus.green
        : MatchStatus.orange;
  }

  return MatchStatus.missing;
}

bool _hasCompound(String raw) {
  final words = raw.toLowerCase().split(RegExp(r'\s+'));
  return words.any((w) => _compoundQualifiers.contains(w));
}

int _statusRank(MatchStatus s) {
  switch (s) {
    case MatchStatus.green:
      return 2;
    case MatchStatus.orange:
      return 1;
    default:
      return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Normalization
// ─────────────────────────────────────────────────────────────────────────────

/// Full normalization: strips _descriptors only. Cut words survive.
/// Used for GREEN detection (so "breast" ≠ "thigh" keeps them ORANGE).
String _fullNorm(String raw) {
  final words = raw
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_descriptors.contains(w))
      .toList();
  return words.join(' ');
}

/// Base normalization: strips _descriptors AND _cutWords.
/// Used for ORANGE detection (both "chicken breast" & "chicken thigh" → "chicken").
String _baseNorm(String raw) {
  final words = raw
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where(
        (w) =>
            w.isNotEmpty && !_descriptors.contains(w) && !_cutWords.contains(w),
      )
      .toList();
  return words.join(' ');
}

/// Public alias used in meal_results_modal.dart for display purposes.
String normalizeIngredientName(String raw) => _baseNorm(raw);

// ─────────────────────────────────────────────────────────────────────────────
// Internal data classes
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeItem {
  final String original;
  final String fullNorm;
  final String baseNorm;
  final String measure;

  const _RecipeItem({
    required this.original,
    required this.fullNorm,
    required this.baseNorm,
    required this.measure,
  });

  factory _RecipeItem.from(Map<String, String> map) {
    final name = map['name'] ?? '';
    return _RecipeItem(
      original: name,
      fullNorm: _fullNorm(name),
      baseNorm: _baseNorm(name),
      measure: map['measure'] ?? '',
    );
  }
}

class _UserItem {
  final String original;
  final String fullNorm;
  final String baseNorm;
  final String quantity;

  const _UserItem({
    required this.original,
    required this.fullNorm,
    required this.baseNorm,
    required this.quantity,
  });

  factory _UserItem.from(Map<String, String> map) {
    final name = map['ingredient'] ?? '';
    return _UserItem(
      original: name,
      fullNorm: _fullNorm(name),
      baseNorm: _baseNorm(name),
      quantity: map['quantity'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity parsing — hints only
// ─────────────────────────────────────────────────────────────────────────────

double? _parseAmount(String text) {
  final m = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
  return m != null ? double.tryParse(m.group(1)!) : null;
}

String _parseUnit(String measure) {
  for (final token in _unitTokens) {
    if (RegExp('\\b$token\\b', caseSensitive: false).hasMatch(measure)) {
      return token;
    }
  }
  return '';
}

QuantityHint? _buildHint(_RecipeItem recipe, _UserItem user) {
  double? userAmount = _parseAmount(user.quantity);
  double? recipeAmount = _parseAmount(recipe.measure);
  if (userAmount == null || recipeAmount == null) return null;

  String recipeUnit = _parseUnit(recipe.measure);
  String userUnit = _parseUnit(user.quantity);

  // ── Convert g ↔ kg so they can be compared ──────────────────────────────
  if (recipeUnit == 'kg' && userUnit == 'g') {
    recipeAmount = recipeAmount * 1000;
    recipeUnit = 'g';
  } else if (recipeUnit == 'g' && userUnit == 'kg') {
    userAmount = userAmount * 1000;
    userUnit = 'g';
  }
  // ── Convert ml ↔ l ──────────────────────────────────────────────────────
  else if (recipeUnit == 'l' && userUnit == 'ml') {
    recipeAmount = recipeAmount * 1000;
    recipeUnit = 'ml';
  } else if (recipeUnit == 'ml' && userUnit == 'l') {
    userAmount = userAmount * 1000;
    userUnit = 'ml';
  }

  // After conversion, skip only if units are still genuinely incompatible
  if (recipeUnit.isNotEmpty && userUnit.isNotEmpty && recipeUnit != userUnit) {
    return null;
  }

  return QuantityHint(
    ingredientName: recipe.original,
    userAmount: userAmount,
    recipeAmount: recipeAmount,
    unit: recipeUnit,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience extension
// ─────────────────────────────────────────────────────────────────────────────

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
