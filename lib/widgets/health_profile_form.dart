import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrisense/models/prototype_data.dart';

class HealthProfileForm extends StatefulWidget {
  const HealthProfileForm({
    super.key,
    required this.initialProfile,
    required this.submitLabel,
    required this.onSubmit,
    this.header,
  });

  final HealthProfile initialProfile;
  final String submitLabel;
  final Future<void> Function(HealthProfile profile) onSubmit;
  final Widget? header;

  @override
  State<HealthProfileForm> createState() => _HealthProfileFormState();
}

class _HealthProfileFormState extends State<HealthProfileForm> {
  static const Color _navy = Color(0xFF24376B);
  static const Color _gold = Color(0xFFD6B66E);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  final TextEditingController _allergyController = TextEditingController();

  late String _gender;
  late String _activityLevel;
  late String _fitnessGoal;
  late String _dietaryPreference;
  late String _moodStatus;
  late String _wellnessStatus;
  late final Set<String> _medicalConditions;
  late final Set<String> _allergies;
  bool _isSaving = false;

  static const _genders = <String>['Female', 'Male', 'Prefer not to say'];
  static const _activityLevels = <String>['Low', 'Moderate', 'High'];
  static const _fitnessGoals = <String>[
    'General fitness',
    'Build strength',
    'Weight management',
    'Flexibility and mobility',
  ];
  static const _dietaryPreferences = <String>[
    'No preference',
    'Vegetarian',
    'Vegan',
    'High-protein',
    'Low sodium',
  ];
  static const _moods = <String>['Energized', 'Balanced', 'Stressed', 'Tired'];
  static const _wellnessStates = <String>[
    'Good',
    'Needs rest',
    'Busy',
    'Low energy',
  ];
  static const _conditionOptions = <String>[
    'Diabetes',
    'Hypertension',
    'Lactose intolerance',
    'Gluten sensitivity',
    'Food allergies',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _ageController = TextEditingController(text: _formatInt(profile.age));
    _heightController = TextEditingController(
      text: _formatDouble(profile.heightCm),
    );
    _weightController = TextEditingController(
      text: _formatDouble(profile.weightKg),
    );
    _targetWeightController = TextEditingController(
      text: _formatDouble(profile.targetWeightKg),
    );
    _gender = profile.gender ?? _genders.first;
    _activityLevel = profile.activityLevel;
    _fitnessGoal = profile.fitnessGoal;
    _dietaryPreference = profile.dietaryPreference;
    _moodStatus = profile.moodStatus;
    _wellnessStatus = profile.wellnessStatus;
    _medicalConditions = profile.medicalConditions.toSet();
    _allergies = profile.allergies.toSet();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (_isSaving || form == null || !form.validate()) return;

    setState(() => _isSaving = true);
    final profile = HealthProfile(
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      heightCm: double.parse(_heightController.text.trim()),
      weightKg: double.parse(_weightController.text.trim()),
      targetWeightKg: double.parse(_targetWeightController.text.trim()),
      activityLevel: _activityLevel,
      fitnessGoal: _fitnessGoal,
      dietaryPreference: _dietaryPreference,
      medicalConditions: _medicalConditions.toList(growable: false),
      allergies: _allergies.toList(growable: false),
      moodStatus: _moodStatus,
      wellnessStatus: _wellnessStatus,
      updatedAt: widget.initialProfile.updatedAt,
    );

    try {
      await widget.onSubmit(profile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addAllergy() {
    final value = _allergyController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _allergies.add(value);
      _allergyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: 22),
          ],
          _card(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _ageController,
                      'Age',
                      min: 10,
                      max: 100,
                      decimal: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      _heightController,
                      'Height (cm)',
                      min: 90,
                      max: 250,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _weightController,
                      'Current weight (kg)',
                      min: 25,
                      max: 300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      _targetWeightController,
                      'Target weight (kg)',
                      min: 25,
                      max: 300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _dropdown('Gender', _gender, _genders, (value) {
                setState(() => _gender = value);
              }),
              _dropdown('Activity level', _activityLevel, _activityLevels, (
                value,
              ) {
                setState(() => _activityLevel = value);
              }),
              _dropdown('Fitness goal', _fitnessGoal, _fitnessGoals, (value) {
                setState(() => _fitnessGoal = value);
              }),
              _dropdown(
                'Dietary preference',
                _dietaryPreference,
                _dietaryPreferences,
                (value) => setState(() => _dietaryPreference = value),
              ),
              _dropdown('Mood today', _moodStatus, _moods, (value) {
                setState(() => _moodStatus = value);
              }),
              _dropdown(
                'Wellness status',
                _wellnessStatus,
                _wellnessStates,
                (value) => setState(() => _wellnessStatus = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('Medical conditions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditionOptions.map((condition) {
              final selected = _medicalConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: selected,
                selectedColor: _gold.withValues(alpha: 0.35),
                checkmarkColor: _navy,
                onSelected: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          if (value) {
                            _medicalConditions.add(condition);
                          } else {
                            _medicalConditions.remove(condition);
                          }
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Allergies'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _allergyController,
                  enabled: !_isSaving,
                  decoration: _inputDecoration('Add allergy'),
                  onSubmitted: (_) => _addAllergy(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isSaving ? null : _addAllergy,
                style: IconButton.styleFrom(backgroundColor: _navy),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies
                .map(
                  (allergy) => Chip(
                    label: Text(allergy),
                    onDeleted: _isSaving
                        ? null
                        : () => setState(() => _allergies.remove(allergy)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.submitLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required num min,
    required num max,
    bool decimal = true,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Color(0xFF1F2A44),
        fontWeight: FontWeight.w600,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(decimal ? r'[0-9.]' : r'[0-9]'),
        ),
      ],
      validator: (value) {
        final parsed = num.tryParse((value ?? '').trim());
        if (parsed == null) return 'Required';
        if (parsed < min || parsed > max) return '$min-$max';
        return null;
      },
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      labelStyle: const TextStyle(color: Color(0xFF4B5563)),
      floatingLabelStyle: const TextStyle(
        color: _navy,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E6EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _navy),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final resolvedValue = options.contains(value) ? value : options.first;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        initialValue: resolvedValue,
        style: const TextStyle(
          color: Color(0xFF1F2A44),
          fontWeight: FontWeight.w600,
        ),
        dropdownColor: Colors.white,
        decoration: _inputDecoration(label),
        items: options
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: _isSaving
            ? null
            : (next) {
                if (next != null) onChanged(next);
              },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _formatInt(int? value) => value?.toString() ?? '';

  String _formatDouble(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}
