import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.onNavigateTab});

  final Function(int)? onNavigateTab;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const Color navy = Color(0xFF24376B);
  static const Color bg = Color(0xFFF3F0EC);
  static const Color gold = Color(0xFFD6B66E);
  static const Color blue = Color(0xFF6A9CF6);
  static const Color green = Color(0xFF22C55E);
  static const Color textDark = Color(0xFF1F2A44);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final service = ref.read(prototypeDataServiceProvider);
      await service.ensureDailyQuests();
      await service.ensureDefaultReminders();
      ref.invalidate(todayQuestsProvider);
      ref.invalidate(enabledRemindersProvider);
      ref.invalidate(dashboardStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    final stats = ref.watch(dashboardStatsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    final quests = ref.watch(todayQuestsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <DailyQuest>[],
        );
    final reminders = ref.watch(enabledRemindersProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <AppReminder>[],
        );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(todayQuestsProvider);
            ref.invalidate(enabledRemindersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _Header(profile: profile),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        _ProgressCard(stats: stats),
                        const SizedBox(height: 26),
                        _sectionTitle('Today Overview'),
                        const SizedBox(height: 14),
                        _OverviewGrid(stats: stats),
                        const SizedBox(height: 26),
                        _sectionTitle('Quick Actions'),
                        const SizedBox(height: 14),
                        _QuickActionButton(
                          color: navy,
                          iconBackground: const Color(0xFF3C4E82),
                          icon: Icons.access_time,
                          title: 'Start Study Session',
                          subtitle: 'Focus mode with timer',
                          titleColor: Colors.white,
                          subtitleColor: const Color(0xFFD8E0F2),
                          iconColor: Colors.white,
                          onTap: () => widget.onNavigateTab?.call(2),
                        ),
                        const SizedBox(height: 14),
                        _QuickActionButton(
                          color: gold,
                          iconBackground: const Color(0xFFE7D4A5),
                          icon: Icons.gps_fixed,
                          title: 'Open Wellness Hub',
                          subtitle: 'Workout and meal recommendations',
                          titleColor: navy,
                          subtitleColor: const Color(0xFF3F4A5A),
                          iconColor: navy,
                          onTap: () => widget.onNavigateTab?.call(1),
                        ),
                        const SizedBox(height: 26),
                        _QuestSection(quests: quests),
                        const SizedBox(height: 22),
                        _ReminderSection(reminders: reminders),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile?.resolvedFirstName;
    final displayName = firstName == null || firstName.isEmpty
        ? profile?.displayName ?? 'Student'
        : firstName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
      decoration: const BoxDecoration(
        color: _HomePageState.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, $displayName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ready to balance your day?',
                  style: TextStyle(
                    color: Color(0xFFE0E5F2),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB8A98B), width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, color: Color(0xFF7C5AA6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stats});

  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final studyHours = ((stats?.studyMinutes ?? 0) / 60).toStringAsFixed(1);
    final workoutMinutes = (stats?.completedWorkouts ?? 0) > 0 ? 'Done' : '0';
    final sleepHours = (stats?.sleepHours ?? 0).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _HomePageState.textDark,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ProgressCircle(
                value: studyHours,
                unit: 'hrs',
                label: 'Study',
                color: _HomePageState.navy,
              ),
              ProgressCircle(
                value: workoutMinutes,
                unit: workoutMinutes == 'Done' ? '' : 'min',
                label: 'Workout',
                color: _HomePageState.gold,
              ),
              ProgressCircle(
                value: sleepHours,
                unit: 'hrs',
                label: 'Sleep',
                color: _HomePageState.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.stats});

  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OverviewCard(
                icon: Icons.calendar_today_outlined,
                iconColor: _HomePageState.navy,
                value: '${stats?.todayClasses ?? 0}',
                title: 'Classes Today',
                subtitle: 'Schedule',
                subtitleColor: _HomePageState.green,
                bgIconColor: const Color(0xFFEFF2F8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OverviewCard(
                icon: Icons.task_alt_outlined,
                iconColor: _HomePageState.gold,
                value:
                    '${stats?.completedStudyTasks ?? 0}/${stats?.studyTasks ?? 0}',
                title: 'Study Tasks',
                subtitle: 'Completed',
                subtitleColor: _HomePageState.green,
                bgIconColor: const Color(0xFFF8F3E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OverviewCard(
                icon: Icons.restaurant_menu_outlined,
                iconColor: const Color(0xFF22C55E),
                value: '${stats?.mealsLogged ?? 0}',
                title: 'Meals Logged',
                subtitle: 'Nutrition',
                subtitleColor: _HomePageState.green,
                bgIconColor: const Color(0xFFE8F8F0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OverviewCard(
                icon: Icons.auto_awesome,
                iconColor: _HomePageState.navy,
                value:
                    '${stats?.completedQuests ?? 0}/${stats?.totalQuests ?? 0}',
                title: 'Daily Quests',
                subtitle: 'Progress',
                subtitleColor: _HomePageState.green,
                bgIconColor: const Color(0xFFEFF2F8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.color,
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.onTap,
  });

  final Color color;
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: iconBackground,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: titleColor),
          ],
        ),
      ),
    );
  }
}

class _QuestSection extends ConsumerWidget {
  const _QuestSection({required this.quests});

  final List<DailyQuest> quests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _InfoPanel(
      title: 'Daily Quests',
      emptyText: 'Your quests are being prepared.',
      children: quests.take(4).map((quest) {
        return CheckboxListTile(
          value: quest.completed,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _HomePageState.navy,
          title: Text(
            quest.title,
            style: const TextStyle(
              color: _HomePageState.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(quest.description),
          onChanged: (value) async {
            await ref
                .read(prototypeDataServiceProvider)
                .setQuestCompleted(quest.id, value ?? false);
            ref.invalidate(todayQuestsProvider);
            ref.invalidate(dashboardStatsProvider);
          },
        );
      }).toList(),
    );
  }
}

class _ReminderSection extends ConsumerWidget {
  const _ReminderSection({required this.reminders});

  final List<AppReminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _InfoPanel(
      title: 'Reminders',
      emptyText: 'No reminders are enabled.',
      children: reminders.take(4).map((reminder) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: reminder.enabled,
          activeThumbColor: _HomePageState.navy,
          title: Text(
            reminder.title,
            style: const TextStyle(
              color: _HomePageState.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(reminder.timeLabel),
          secondary: const CircleAvatar(
            backgroundColor: Color(0xFFF8F3E8),
            child: Icon(Icons.notifications_none, color: _HomePageState.gold),
          ),
          onChanged: (value) async {
            await ref
                .read(prototypeDataServiceProvider)
                .setReminderEnabled(reminder.id, value);
            ref.invalidate(enabledRemindersProvider);
          },
        );
      }).toList(),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _HomePageState.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                emptyText,
                style: const TextStyle(color: Color(0xFF667085)),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class ProgressCircle extends StatelessWidget {
  const ProgressCircle({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  final String value;
  final String unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: CircularProgressIndicator(
                  value: value == '0' || value == '0.0' ? 0.08 : 0.78,
                  strokeWidth: 5,
                  backgroundColor: color.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _HomePageState.navy,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7D8596),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF586173)),
        ),
      ],
    );
  }
}

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgIconColor,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgIconColor;
  final String value;
  final String title;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: bgIconColor,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 22),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _HomePageState.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
