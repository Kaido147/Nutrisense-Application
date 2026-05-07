import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/pages/modals/profile/profile_modal_shell.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/widgets/health_profile_form.dart';

class EditHealthProfileModal extends ConsumerWidget {
  const EditHealthProfileModal({super.key, required this.healthProfile});

  final HealthProfile healthProfile;

  static Future<void> show(BuildContext context, HealthProfile? healthProfile) {
    return ProfileModalShell.show<void>(
      context: context,
      builder: (context) => EditHealthProfileModal(
        healthProfile: healthProfile ?? HealthProfile.empty(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthDate = ref
        .watch(currentUserProfileProvider)
        .asData
        ?.value
        ?.birthDate;

    return ProfileModalShell(
      title: 'Edit Health Profile',
      footer: const SizedBox.shrink(),
      child: HealthProfileForm(
        initialProfile: healthProfile,
        submitLabel: 'Save Health Profile',
        birthDate: birthDate,
        onSubmit: (profile) async {
          await ref
              .read(prototypeDataServiceProvider)
              .saveHealthProfile(profile);
          await ref
              .read(profileServiceProvider)
              .calculateAndSaveDailyMacros(profile);
          ref.invalidate(healthProfileProvider);
          ref.invalidate(dailyMacrosProvider);
          ref.invalidate(todayQuestsProvider);
          ref.invalidate(dashboardStatsProvider);
          if (!context.mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
