import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/widgets/health_profile_form.dart';

class HealthProfileSetupPage extends ConsumerWidget {
  const HealthProfileSetupPage({super.key});

  static const Color _navy = Color(0xFF24376B);
  static const Color _background = Color(0xFFF3F0EC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthDate = ref
        .watch(currentUserProfileProvider)
        .asData
        ?.value
        ?.birthDate;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: HealthProfileForm(
            initialProfile: HealthProfile.empty(),
            submitLabel: 'Continue to Dashboard',
            header: const _HealthProfileHeader(),
            birthDate: birthDate,
            onSubmit: (profile) async {
              final service = ref.read(prototypeDataServiceProvider);
              await service.saveHealthProfile(profile);

              // Calculate and save daily macros based on health profile
              // weightGainPaceKgPerWeek is now included in profile from the form
              final profileService = ref.read(profileServiceProvider);
              await profileService.calculateAndSaveDailyMacros(profile);

              await service.ensureDailyQuests();
              await service.ensureDefaultReminders();

              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HealthProfileHeader extends StatelessWidget {
  const _HealthProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Profile',
          style: TextStyle(
            color: HealthProfileSetupPage._navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'This helps NutriSense personalize your meals, workouts, and reminders.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }
}
