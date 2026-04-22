import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────
//  THEME STATE  (replace with your own provider)
// ─────────────────────────────────────────────
enum AppThemeMode { light, dark, auto }

enum AccentColor {
  softGold,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  lavenderPurple,
  rosePink,
}

extension AccentColorExt on AccentColor {
  Color get color {
    switch (this) {
      case AccentColor.softGold:
        return const Color(0xFFE0C58F);
      case AccentColor.oceanBlue:
        return const Color(0xFF4A90D9);
      case AccentColor.forestGreen:
        return const Color(0xFF3DB87A);
      case AccentColor.sunsetOrange:
        return const Color(0xFFFF7043);
      case AccentColor.lavenderPurple:
        return const Color(0xFF9B72CF);
      case AccentColor.rosePink:
        return const Color(0xFFE91E8C);
    }
  }

  String get label {
    switch (this) {
      case AccentColor.softGold:
        return 'Soft Gold';
      case AccentColor.oceanBlue:
        return 'Ocean Blue';
      case AccentColor.forestGreen:
        return 'Forest Green';
      case AccentColor.sunsetOrange:
        return 'Sunset Orange';
      case AccentColor.lavenderPurple:
        return 'Lavender Purple';
      case AccentColor.rosePink:
        return 'Rose Pink';
    }
  }
}

// ─────────────────────────────────────────────
//  PROFILE PAGE
// ─────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppThemeMode _themeMode = AppThemeMode.light;
  AccentColor _accentColor = AccentColor.softGold;

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, "/login");
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  void _openGoalsPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoalsPreferencesSheet(),
    );
  }

  void _openThemeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThemeSettingsSheet(
        currentTheme: _themeMode,
        currentAccent: _accentColor,
        onThemeChanged: (t) => setState(() => _themeMode = t),
        onAccentChanged: (a) => setState(() => _accentColor = a),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 70),
              decoration: const BoxDecoration(
                color: Color(0xFF243A6E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white24,
                    child: Icon(LucideIcons.user,
                        size: 50, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  const Text("Alex Johnson",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("alex.johnson@student.edu",
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFFE0C58F))),
                ],
              ),
            ),

            // ── Progress card ────────────────────────────
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(blurRadius: 15, color: Colors.black12)
                  ],
                ),
                child: Column(
                  children: [
                    _progressRow(
                        icon: LucideIcons.target,
                        title: "Weekly Study Goal",
                        value: "28 / 30h",
                        progress: 0.95),
                    const SizedBox(height: 25),
                    _progressRow(
                        icon: LucideIcons.zap,
                        title: "Workout Streak",
                        value: "5 / 7 days",
                        progress: 0.7),
                  ],
                ),
              ),
            ),

            // ── Settings label ────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Settings",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // ── Settings items ────────────────────────────
            _settingsItem(
              icon: LucideIcons.user,
              title: "Edit Profile",
              subtitle: "Update your information",
              iconColor: const Color(0xFF243A6E),
              borderColor: const Color(0xFF243A6E),
              onTap: _openEditProfile,
            ),
            _settingsItem(
              icon: LucideIcons.target,
              title: "Goals & Preferences",
              subtitle: "Manage your targets",
              iconColor: const Color(0xFFE0C58F),
              borderColor: const Color(0xFFE0C58F),
              onTap: _openGoalsPreferences,
            ),
            _settingsItem(
              icon: LucideIcons.moon,
              title: "Theme",
              subtitle: _themeMode.name[0].toUpperCase() +
                  _themeMode.name.substring(1) +
                  " mode",
              iconColor: Colors.purple,
              borderColor: Colors.purpleAccent,
              onTap: _openThemeSettings,
            ),

            const SizedBox(height: 20),

            // ── Logout ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Center(
                    child: Text("Log Out",
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────
  Widget _progressRow({
    required IconData icon,
    required String title,
    required String value,
    required double progress,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFE0C58F)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 10))),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          color: const Color(0xFFE0C58F),
          backgroundColor: const Color(0xFFEEEEEE),
        ),
      ],
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = Colors.blue,
    Color borderColor = Colors.blueAccent,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(blurRadius: 10, color: Colors.black12)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
                color: iconColor.withValues(alpha: 0.08),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  BOTTOM SHEET BASE WRAPPER
// ═════════════════════════════════════════════
class _SheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // title bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            // scrollable body
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  1.  EDIT PROFILE SHEET
// ═════════════════════════════════════════════
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController(text: 'Alex');
  final _lastName = TextEditingController(text: 'Johnson');
  final _email =
      TextEditingController(text: 'alex.johnson@student.edu');
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _birthDate,
      _location,
      _bio
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon:
            Icon(icon, size: 18, color: const Color(0xFF243A6E)),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF243A6E), width: 1.5),
        ),
      );

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            children: required
                ? const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red))
                  ]
                : [],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _SheetWrapper(
      title: 'Edit Profile',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFF0EAD6),
                    child: const Icon(LucideIcons.user,
                        size: 48, color: Color(0xFF243A6E)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF243A6E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.camera,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Tap to change photo',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 24),

            // First & Last name row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('First Name', required: true),
                      TextFormField(
                          controller: _firstName,
                          decoration:
                              _dec('Alex', LucideIcons.user)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Last Name', required: true),
                      TextFormField(
                          controller: _lastName,
                          decoration: _dec('Johnson', Icons.abc)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _label('Email Address', required: true),
            TextFormField(
                controller: _email,
                decoration: _dec(
                    'alex.johnson@student.edu', LucideIcons.mail)),
            const SizedBox(height: 16),

            _label('Phone Number'),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration:
                    _dec('+1 (555) 000-0000', LucideIcons.phone)),
            const SizedBox(height: 16),

            _label('Birth Date'),
            TextFormField(
              controller: _birthDate,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _birthDate.text =
                      '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                }
              },
              decoration:
                  _dec('mm/dd/yyyy', LucideIcons.calendarDays),
            ),
            const SizedBox(height: 16),

            _label('Location'),
            TextFormField(
                controller: _location,
                decoration: _dec('City, Country', LucideIcons.mapPin)),
            const SizedBox(height: 16),

            _label('Bio'),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell something about yourself...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFF243A6E), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF243A6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  2.  GOALS & PREFERENCES SHEET
// ═════════════════════════════════════════════
class _GoalsPreferencesSheet extends StatefulWidget {
  const _GoalsPreferencesSheet();

  @override
  State<_GoalsPreferencesSheet> createState() =>
      _GoalsPreferencesSheetState();
}

class _GoalsPreferencesSheetState
    extends State<_GoalsPreferencesSheet> {
  // Study
  double _weeklyStudyHours = 30;
  double _focusTime = 25;
  double _breakTime = 5;

  // Workout
  double _workoutDays = 5;

  // Health
  double _waterIntake = 8;
  double _sleepHours = 8;

  // Reminders
  bool _studyReminder = true;
  bool _workoutReminder = true;
  bool _mealReminder = false;

  static const _navy = Color(0xFF243A6E);
  static const _gold = Color(0xFFE0C58F);
  static const _green = Color(0xFF3DB87A);

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(display,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            trackHeight: 6,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _reminderToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetWrapper(
      title: 'Goals & Preferences',
      child: Column(
        children: [
          // Study Goals
          _sectionCard(
            icon: LucideIcons.bookOpen,
            title: 'Study Goals',
            color: _navy,
            children: [
              _sliderRow(
                label: 'Weekly Study Hours',
                value: _weeklyStudyHours,
                min: 0,
                max: 60,
                divisions: 60,
                display: '${_weeklyStudyHours.toInt()}h',
                color: _navy,
                onChanged: (v) =>
                    setState(() => _weeklyStudyHours = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Focus Time (min)',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                  onTap: () => setState(() =>
                                      _focusTime =
                                          (_focusTime - 5).clamp(5, 90)),
                                  child: const Icon(Icons.remove,
                                      size: 16)),
                              Text('${_focusTime.toInt()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              GestureDetector(
                                  onTap: () => setState(() =>
                                      _focusTime =
                                          (_focusTime + 5).clamp(5, 90)),
                                  child: const Icon(Icons.add,
                                      size: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Break Time (min)',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                  onTap: () => setState(() =>
                                      _breakTime =
                                          (_breakTime - 1).clamp(1, 30)),
                                  child: const Icon(Icons.remove,
                                      size: 16)),
                              Text('${_breakTime.toInt()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              GestureDetector(
                                  onTap: () => setState(() =>
                                      _breakTime =
                                          (_breakTime + 1).clamp(1, 30)),
                                  child: const Icon(Icons.add,
                                      size: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Workout Goals
          _sectionCard(
            icon: LucideIcons.dumbbell,
            title: 'Workout Goals',
            color: _gold,
            children: [
              _sliderRow(
                label: 'Workout Days Per Week',
                value: _workoutDays,
                min: 1,
                max: 7,
                divisions: 6,
                display: '${_workoutDays.toInt()}',
                color: _gold,
                onChanged: (v) =>
                    setState(() => _workoutDays = v),
              ),
            ],
          ),

          // Health Goals
          _sectionCard(
            icon: LucideIcons.heartPulse,
            title: 'Health Goals',
            color: _green,
            children: [
              _sliderRow(
                label: 'Daily Water Intake (glasses)',
                value: _waterIntake,
                min: 1,
                max: 16,
                divisions: 15,
                display: '${_waterIntake.toInt()}',
                color: _green,
                onChanged: (v) =>
                    setState(() => _waterIntake = v),
              ),
              const SizedBox(height: 8),
              _sliderRow(
                label: 'Target Sleep Hours',
                value: _sleepHours,
                min: 4,
                max: 12,
                divisions: 8,
                display: '${_sleepHours.toInt()}h',
                color: _green,
                onChanged: (v) =>
                    setState(() => _sleepHours = v),
              ),
            ],
          ),

          // Reminder Preferences
          _sectionCard(
            icon: LucideIcons.bell,
            title: 'Reminder Preferences',
            color: Colors.purple,
            children: [
              _reminderToggle(
                icon: LucideIcons.bookOpen,
                label: 'Study Reminders',
                value: _studyReminder,
                onChanged: (v) =>
                    setState(() => _studyReminder = v),
                color: _navy,
              ),
              _reminderToggle(
                icon: LucideIcons.dumbbell,
                label: 'Workout Reminders',
                value: _workoutReminder,
                onChanged: (v) =>
                    setState(() => _workoutReminder = v),
                color: _gold,
              ),
              _reminderToggle(
                icon: LucideIcons.utensils,
                label: 'Meal Reminders',
                value: _mealReminder,
                onChanged: (v) =>
                    setState(() => _mealReminder = v),
                color: _green,
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF243A6E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  3.  THEME SETTINGS SHEET
// ═════════════════════════════════════════════
class _ThemeSettingsSheet extends StatefulWidget {
  final AppThemeMode currentTheme;
  final AccentColor currentAccent;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final ValueChanged<AccentColor> onAccentChanged;

  const _ThemeSettingsSheet({
    required this.currentTheme,
    required this.currentAccent,
    required this.onThemeChanged,
    required this.onAccentChanged,
  });

  @override
  State<_ThemeSettingsSheet> createState() =>
      _ThemeSettingsSheetState();
}

class _ThemeSettingsSheetState
    extends State<_ThemeSettingsSheet> {
  late AppThemeMode _theme;
  late AccentColor _accent;

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
    _accent = widget.currentAccent;
  }

  static const _navy = Color(0xFF243A6E);

  Widget _themeOption({
    required AppThemeMode mode,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final selected = _theme == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _theme = mode);
        widget.onThemeChanged(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _navy.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _navy : Colors.grey.shade200,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? _navy.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected ? _navy : Colors.grey.shade500),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? _navy : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: _navy, shape: BoxShape.circle),
                child: const Icon(Icons.check,
                    size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accentGrid() {
    final colors = AccentColor.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: colors.length,
      itemBuilder: (_, i) {
        final ac = colors[i];
        final selected = _accent == ac;
        return GestureDetector(
          onTap: () {
            setState(() => _accent = ac);
            widget.onAccentChanged(ac);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _navy : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ac.color,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: ac.color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(ac.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected ? _navy : Colors.grey.shade600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _previewCard() {
    final isDark = _theme == AppThemeMode.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor =
        isDark ? Colors.white54 : Colors.grey.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black38
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                _accent.color.withValues(alpha: 0.2),
            child: Icon(LucideIcons.user,
                color: _accent.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sample Card',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                    'This is how the app will look with your theme.',
                    style: TextStyle(
                        fontSize: 11, color: subColor)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.65,
                  minHeight: 6,
                  color: _accent.color,
                  backgroundColor:
                      _accent.color.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetWrapper(
      title: 'Theme Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appearance',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _themeOption(
            mode: AppThemeMode.light,
            icon: LucideIcons.sun,
            label: 'Light',
            subtitle: 'Always use light mode',
          ),
          _themeOption(
            mode: AppThemeMode.dark,
            icon: LucideIcons.moon,
            label: 'Dark',
            subtitle: 'Always use dark mode',
          ),
          _themeOption(
            mode: AppThemeMode.auto,
            icon: LucideIcons.monitor,
            label: 'Auto',
            subtitle: 'Match system settings',
          ),
          const SizedBox(height: 20),
          const Text('Accent Color',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _accentGrid(),
          const SizedBox(height: 20),
          const Text('Preview',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _previewCard(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Apply Theme',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}