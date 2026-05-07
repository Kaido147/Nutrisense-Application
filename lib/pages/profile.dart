import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/pages/modals/profile/edit_health_profile_modal.dart';
import 'package:nutrisense/pages/modals/profile/edit_profile_modal.dart';
import 'package:nutrisense/pages/modals/profile/goals_preferences_modal.dart';
import 'package:nutrisense/pages/modals/profile/reminder_settings_modal.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/auth_service.dart';
import 'package:nutrisense/theme_provider.dart';
import 'package:nutrisense/widgets/profile_avatar.dart';
import 'package:provider/provider.dart' as p;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext pageContext, WidgetRef ref) {
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await ref.read(authServiceProvider).logout();

                if (!pageContext.mounted) return;

                Navigator.pushNamedAndRemoveUntil(
                  pageContext,
                  '/login',
                  (route) => false,
                );
              } on AuthFlowException catch (error) {
                if (!pageContext.mounted) return;

                ScaffoldMessenger.of(
                  pageContext,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileAsync = ref.watch(
      currentUserProfileProvider,
    );
    final HealthProfile? healthProfile = ref
        .watch(healthProfileProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view your profile.')),
          );
        }

        return _ProfileContent(
          profile: profile,
          healthProfile: healthProfile,
          onLogout: () => _logout(context, ref),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('We could not load your profile.')),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.healthProfile,
    required this.onLogout,
  });

  final UserProfile profile;
  final HealthProfile? healthProfile;
  final VoidCallback onLogout;

  static const Color _backgroundColor = Color(0xFFF4F0E8);
  static const Color _navyBlue = Color(0xFF243A6E);
  static const Color _goldTan = Color(0xFFD8B56D);
  static const Color _textPrimary = Color(0xFF24376B);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _cardColor = Colors.white;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = p.Provider.of<ThemeProvider>(context);
    final stats = ref
        .watch(dashboardStatsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildHeader(),
            Transform.translate(
              offset: const Offset(0, -32),
              child: Column(
                children: [
                  _buildGoalProgressCard(stats),
                  const SizedBox(height: 18),
                  _buildHealthProfileCard(context),
                  const SizedBox(height: 18),
                  _buildSettingsSection(context, themeProvider),
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 36, left: 24, right: 24, bottom: 78),
      decoration: const BoxDecoration(
        color: _navyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          ProfileAvatar(
            uid: profile.uid,
            size: 122,
            borderWidth: 5,
            borderColor: const Color(0xFF8D8D93),
            backgroundColor: const Color(0xFF5B6478),
            fallbackIconColor: const Color(0xFF5B2CA0),
            editable: true,
            editButtonColor: _goldTan,
            editIconColor: _navyBlue,
          ),
          const SizedBox(height: 18),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.displayEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFE1C78F),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(DashboardStats? stats) {
    final studyTargetHours = profile.effectiveStudyWeeklyHours;
    final studyActualMinutes = stats?.weeklyStudyMinutes ?? 0;
    final studyActualHours = studyActualMinutes / 60;
    final studyProgress = studyTargetHours == null || studyTargetHours <= 0
        ? 0.0
        : studyActualHours / studyTargetHours;
    final studyValue = studyTargetHours == null
        ? 'Not set'
        : '${_formatCompactNumber(studyActualHours)}h/${studyTargetHours}h';

    final workoutTargetDays = profile.effectiveWorkoutDaysPerWeek;
    final workoutActualDays = stats?.weeklyCompletedWorkoutDays ?? 0;
    final workoutProgress = workoutTargetDays == null || workoutTargetDays <= 0
        ? 0.0
        : workoutActualDays / workoutTargetDays;
    final workoutValue = workoutTargetDays == null
        ? 'Not set'
        : '$workoutActualDays/$workoutTargetDays days';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Progress',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          _buildProgressRow(
            icon: LucideIcons.target,
            title: 'Weekly Study Goal',
            value: studyValue,
            progress: studyProgress,
            color: _navyBlue,
          ),
          const SizedBox(height: 24),
          _buildProgressRow(
            icon: Icons.trending_up_rounded,
            title: 'Workout Streak',
            value: workoutValue,
            progress: workoutProgress,
            color: _goldTan,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: const Color(0xFFE8E8E8),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthProfileCard(BuildContext context) {
    final health = healthProfile;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => EditHealthProfileModal.show(context, health),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFFCF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFF00A63E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            health == null
                                ? 'Complete your wellness details'
                                : '${health.fitnessGoal} - ${health.activityLevel}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: Color(0xFF98A2B3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (health == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Text(
                'Personalized meals and workouts will use these details once added.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                children: [
                  _buildInfoRow('Age', health.age?.toString() ?? 'Not set'),
                  _buildInfoRow('Gender', health.gender ?? 'Not set'),
                  _buildInfoRow(
                    'Height',
                    health.heightCm == null
                        ? 'Not set'
                        : '${_formatNumber(health.heightCm!)} cm',
                  ),
                  _buildInfoRow(
                    'Current weight',
                    health.weightKg == null
                        ? 'Not set'
                        : '${_formatNumber(health.weightKg!)} kg',
                  ),
                  _buildInfoRow(
                    'Target weight',
                    health.targetWeightKg == null
                        ? 'Not set'
                        : '${_formatNumber(health.targetWeightKg!)} kg',
                  ),
                  // ── Goal pace ─────────────────────────────────────────────────
                  _buildInfoRow(
                    'Goal pace',
                    _formatPace(health.weightGainPaceKgPerWeek),
                  ),
                  _buildInfoRow('Activity', health.activityLevel),
                  _buildInfoRow('Fitness goal', health.fitnessGoal),
                  _buildInfoRow('Diet', health.dietaryPreference),
                  _buildInfoRow(
                    'Allergies',
                    health.allergies.isEmpty
                        ? 'None'
                        : health.allergies.join(', '),
                  ),
                  _buildInfoRow('Mood', health.moodStatus),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: LucideIcons.user,
                  iconColor: _navyBlue,
                  iconBackground: const Color(0xFFF1F3F8),
                  title: 'Edit Profile',
                  subtitle: 'Update your information',
                  onTap: () => EditProfileModal.show(context, profile),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEAEAEA),
                  indent: 24,
                  endIndent: 24,
                ),
                _buildSettingsTile(
                  icon: LucideIcons.target,
                  iconColor: _goldTan,
                  iconBackground: const Color(0xFFF8F4EA),
                  title: 'Goals & Preferences',
                  subtitle: 'Manage your targets',
                  onTap: () => GoalsPreferencesModal.show(context, profile),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEAEAEA),
                  indent: 24,
                  endIndent: 24,
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_none,
                  iconColor: const Color(0xFF00A63E),
                  iconBackground: const Color(0xFFEFFCF4),
                  title: 'Reminders',
                  subtitle: 'Hydration, sleep, workout, and breaks',
                  onTap: () => ReminderSettingsModal.show(context),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEAEAEA),
                  indent: 24,
                  endIndent: 24,
                ),
                _buildSettingsTile(
                  icon: LucideIcons.moon,
                  iconColor: const Color(0xFF9A35FF),
                  iconBackground: const Color(0xFFF5ECFF),
                  title: 'Theme',
                  subtitle: '${_capitalize(themeProvider.themeMode.name)} mode',
                  onTap: () => _openThemeSettings(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.red, size: 22),
                SizedBox(width: 12),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatCompactNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  /// Formats the pace value into a human-readable string.
  /// e.g. 0.5 → "0.5 kg/week (Recommended)"
  String _formatPace(double? pace) {
    if (pace == null) return 'Not set';
    final descriptions = {
      0.25: 'Slow & steady',
      0.5: 'Recommended',
      0.75: 'Faster progress',
      1.0: 'Aggressive',
    };
    final desc = descriptions[pace];
    final paceStr = pace == pace.roundToDouble()
        ? pace.toStringAsFixed(0)
        : pace.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
    return desc != null ? '$paceStr kg/week · $desc' : '$paceStr kg/week';
  }

  void _openThemeSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ThemeSettingsSheet(),
    );
  }
}

class _ThemeSettingsSheet extends StatelessWidget {
  const _ThemeSettingsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: p.Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Theme Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF24376B),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // --- Appearance Section ---
                        const Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24376B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAppearanceOption(
                          context: context,
                          themeProvider: themeProvider,
                          mode: AppThemeMode.light,
                          icon: Icons.wb_sunny_rounded,
                          label: 'Light',
                          subtitle: 'Always use light mode',
                          iconBgColor: const Color(0xFF243A6E),
                          iconColor: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        _buildAppearanceOption(
                          context: context,
                          themeProvider: themeProvider,
                          mode: AppThemeMode.dark,
                          icon: Icons.nightlight_round,
                          label: 'Dark',
                          subtitle: 'Always use dark mode',
                          iconBgColor: const Color(0xFFF2F4F7),
                          iconColor: const Color(0xFF667085),
                        ),
                        const SizedBox(height: 10),
                        _buildAppearanceOption(
                          context: context,
                          themeProvider: themeProvider,
                          mode: AppThemeMode.auto,
                          icon: Icons.palette_outlined,
                          label: 'Auto',
                          subtitle: 'Match system settings',
                          iconBgColor: const Color(0xFFF2F4F7),
                          iconColor: const Color(0xFF667085),
                        ),

                        const SizedBox(height: 24),

                        // --- Accent Color Section ---
                        const Text(
                          'Accent Color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24376B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            for (final accent in AccentColor.values)
                              _buildAccentColorTile(
                                themeProvider: themeProvider,
                                accent: accent,
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- Preview Section ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE4E7EC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preview',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF24376B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: themeProvider
                                          .accentColor
                                          .color
                                          .withValues(alpha: 0.25),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sample Card',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF24376B),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'This is how your theme will look',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeProvider.accentColor.color
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              themeProvider.accentColor.color,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Primary Button',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                themeProvider.accentColor.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF243A6E),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Secondary',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- Note Banner ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD0DAF8)),
                          ),
                          child: const Text(
                            'Note: Theme changes will be applied immediately and saved to your preferences.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF24376B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- Cancel / Apply Buttons ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD0D5DD),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF344054),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF243A6E),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Apply Theme',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppearanceOption({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required AppThemeMode mode,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final bool isSelected = themeProvider.themeMode == mode;
    return GestureDetector(
      onTap: () => themeProvider.setThemeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF243A6E)
                : const Color(0xFFE4E7EC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF243A6E)
                    : const Color(0xFFF2F4F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF667085),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF243A6E)
                          : const Color(0xFF344054),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF243A6E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentColorTile({
    required ThemeProvider themeProvider,
    required AccentColor accent,
  }) {
    final bool isSelected = themeProvider.accentColor == accent;
    return GestureDetector(
      onTap: () => themeProvider.setAccentColor(accent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF243A6E)
                : const Color(0xFFE4E7EC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              accent.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
