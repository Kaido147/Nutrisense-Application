import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/pages/modals/profile/edit_profile_modal.dart';
import 'package:nutrisense/pages/modals/profile/goals_preferences_modal.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/auth_service.dart';

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
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
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

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in to view your profile.'),
            ),
          );
        }

        return _ProfileContent(
          profile: profile,
          onLogout: () => _logout(context, ref),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('We could not load your profile.')),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onLogout,
  });

  final UserProfile profile;
  final VoidCallback onLogout;

  static const Color _backgroundColor = Color(0xFFF4F0E8);
  static const Color _navyBlue = Color(0xFF243A6E);
  static const Color _goldTan = Color(0xFFD8B56D);
  static const Color _textPrimary = Color(0xFF24376B);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
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
                  _buildGoalProgressCard(),
                  const SizedBox(height: 18),
                  _buildSettingsSection(context),
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
      padding: const EdgeInsets.only(
        top: 36,
        left: 24,
        right: 24,
        bottom: 78,
      ),
      decoration: const BoxDecoration(
        color: _navyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8D8D93),
                width: 5,
              ),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.user,
                size: 48,
                color: Color(0xFF5B2CA0),
              ),
            ),
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

  Widget _buildGoalProgressCard() {
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
            value: profile.studySummaryValue,
            progress: profile.studySummaryProgress,
            color: _navyBlue,
          ),
          const SizedBox(height: 24),
          _buildProgressRow(
            icon: Icons.trending_up_rounded,
            title: 'Workout Streak',
            value: profile.workoutSummaryValue,
            progress: profile.workoutSummaryProgress,
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

  Widget _buildSettingsSection(BuildContext context) {
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
                  icon: LucideIcons.moon,
                  iconColor: const Color(0xFF9A35FF),
                  iconBackground: const Color(0xFFF5ECFF),
                  title: 'Theme',
                  subtitle: 'Light mode',
                  onTap: () {},
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
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
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
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 22,
                ),
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
}