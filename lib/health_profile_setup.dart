import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/prototype_data_service.dart';

class HealthProfileSetupPage extends ConsumerStatefulWidget {
  const HealthProfileSetupPage({super.key});

  @override
  ConsumerState<HealthProfileSetupPage> createState() =>
      _HealthProfileSetupPageState();
}

class _HealthProfileSetupPageState
    extends ConsumerState<HealthProfileSetupPage> {
  static const Color _navy = Color(0xFF24376B);
  static const Color _gold = Color(0xFFD6B66E);
  static const Color _background = Color(0xFFF3F0EC);

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  String _gender = 'Female';
  String _activityLevel = 'Moderate';
  String _fitnessGoal = 'General fitness';
  String _dietaryPreference = 'No preference';
  String _moodStatus = 'Balanced';
  String _wellnessStatus = 'Good';
  final Set<String> _medicalConditions = <String>{};
  final Set<String> _allergies = <String>{};
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
  static const _moods = <String>[
    'Energized',
    'Balanced',
    'Stressed',
    'Tired',
  ];
  static const _wellnessStates = <String>['Good', 'Needs rest', 'Busy', 'Low energy'];
  static const _conditionOptions = <String>[
    'Diabetes',
    'Hypertension',
    'Lactose intolerance',
    'Gluten sensitivity',
    'Food allergies',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    if (age == null || height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid age, height, and weight.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(prototypeDataServiceProvider).saveHealthProfile(
            HealthProfile(
              age: age,
              gender: _gender,
              heightCm: height,
              weightKg: weight,
              activityLevel: _activityLevel,
              fitnessGoal: _fitnessGoal,
              dietaryPreference: _dietaryPreference,
              medicalConditions: _medicalConditions.toList(growable: false),
              allergies: _allergies.toList(growable: false),
              moodStatus: _moodStatus,
              wellnessStatus: _wellnessStatus,
              updatedAt: null,
            ),
          );
      await ref.read(prototypeDataServiceProvider).ensureDailyQuests();
      await ref.read(prototypeDataServiceProvider).ensureDefaultReminders();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } on PrototypeDataException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save your health profile.')),
      );
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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Health Profile',
                style: TextStyle(
                  color: _navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This helps NutriSense personalize your meals, workouts, and reminders.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 22),
              _card(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(_ageController, 'Age'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(_heightController, 'Height (cm)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _numberField(_weightController, 'Weight (kg)'),
                  const SizedBox(height: 16),
                  _dropdown('Gender', _gender, _genders, (value) {
                    setState(() => _gender = value);
                  }),
                  _dropdown('Activity level', _activityLevel, _activityLevels, (
                    value,
                  ) {
                    setState(() => _activityLevel = value);
                  }),
                  _dropdown('Fitness goal', _fitnessGoal, _fitnessGoals, (
                    value,
                  ) {
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
                    onSelected: (value) {
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
                      decoration: _inputDecoration('Add allergy'),
                      onSubmitted: (_) => _addAllergy(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _addAllergy,
                    style: IconButton.styleFrom(backgroundColor: _navy),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _allergies
                    .map(
                      (allergy) => Chip(
                        label: Text(allergy),
                        onDeleted: () => setState(() => _allergies.remove(allergy)),
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
                      : const Text(
                          'Continue to Dashboard',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: _inputDecoration(label),
        items: options
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (next) {
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
}
