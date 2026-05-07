import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/widgets/profile_avatar.dart';

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
    final profile = ref
        .watch(currentUserProfileProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final stats = ref
        .watch(dashboardStatsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final quests = ref
        .watch(todayQuestsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const <DailyQuest>[]);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(todayQuestsProvider);
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
                        _ProgressCard(stats: stats, profile: profile),
                        const SizedBox(height: 26),
                        _sectionTitle('Today Overview'),
                        const SizedBox(height: 14),
                        _OverviewGrid(stats: stats),
                        const SizedBox(height: 26),
                        _QuestSection(quests: quests),
                        const SizedBox(height: 26),
                        const _DailyQuoteCard(),
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
          if (profile == null)
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
            )
          else
            ProfileAvatar(
              uid: profile!.uid,
              size: 48,
              borderColor: const Color(0xFFB8A98B),
              backgroundColor: Colors.transparent,
              fallbackIconColor: const Color(0xFF7C5AA6),
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stats, required this.profile});

  final DashboardStats? stats;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final studyTasks = stats?.studyTasks ?? 0;
    final completedStudyTasks = stats?.completedStudyTasks ?? 0;
    final studyMinutes = stats?.studyMinutes ?? 0;
    final studyTargetMinutes = (profile?.editorFocusMinutes ?? 25)
        .clamp(1, 240)
        .toDouble();
    final studyProgress = studyTasks > 0
        ? completedStudyTasks / studyTasks
        : studyMinutes / studyTargetMinutes;
    final studyValue = studyTasks > 0
        ? '$completedStudyTasks/$studyTasks'
        : (studyMinutes / 60).toStringAsFixed(studyMinutes >= 60 ? 1 : 0);
    final studyUnit = studyTasks > 0 ? 'tasks' : 'hrs';

    final workoutDone = stats?.workoutExercisesDone ?? 0;
    final workoutTotal = stats?.workoutExercisesTotal ?? 0;
    final workoutProgress = workoutTotal == 0
        ? 0.0
        : workoutDone / workoutTotal;
    final totalQuests = stats?.totalQuests ?? 0;
    final completedQuests = stats?.completedQuests ?? 0;

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
              Expanded(
                child: ProgressCircle(
                  valueLabel: studyValue,
                  unit: studyUnit,
                  label: 'Study',
                  progress: studyProgress,
                  color: _HomePageState.navy,
                ),
              ),
              Expanded(
                child: ProgressCircle(
                  valueLabel: workoutTotal == 0
                      ? '0'
                      : '$workoutDone/$workoutTotal',
                  unit: workoutTotal == 0 ? 'plan' : 'done',
                  label: 'Workout',
                  progress: workoutProgress,
                  color: _HomePageState.gold,
                ),
              ),
              Expanded(
                child: ProgressCircle(
                  valueLabel: '$completedQuests/$totalQuests',
                  unit: 'done',
                  label: 'Quests',
                  progress: totalQuests == 0
                      ? 0.0
                      : completedQuests / totalQuests,
                  color: _HomePageState.green,
                ),
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
                icon: Icons.restaurant_menu_outlined,
                iconColor: const Color(0xFF22C55E),
                value: '${stats?.mealsLogged ?? 0}',
                title: 'Meals Logged',
                subtitle: 'Nutrition',
                subtitleColor: _HomePageState.green,
                bgIconColor: const Color(0xFFE8F8F0),
              ),
            ),
          ],
        ),
      ],
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
        return _QuestTile(
          quest: quest,
          onChanged: (value) async {
            await ref
                .read(prototypeDataServiceProvider)
                .setQuestCompleted(quest.id, value);
            ref.invalidate(todayQuestsProvider);
            ref.invalidate(dashboardStatsProvider);
          },
        );
      }).toList(),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest, required this.onChanged});

  final DailyQuest quest;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final completed = quest.completed;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: completed ? const Color(0xFFF1F8F3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onChanged(!completed),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: completed
                        ? _HomePageState.green
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? _HomePageState.green
                          : const Color(0xFFD0D5DD),
                      width: 1.5,
                    ),
                  ),
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          color: completed
                              ? const Color(0xFF667085)
                              : _HomePageState.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
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

class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard();

  static const List<_DailyQuote> _quotes = [
    _DailyQuote(
      quote: 'Small healthy choices compound into a stronger week.',
      author: 'NutriSense',
    ),
    _DailyQuote(
      quote: 'Protect your focus, fuel your body, and take the next step.',
      author: 'NutriSense',
    ),
    _DailyQuote(
      quote: 'Progress feels lighter when you balance effort with recovery.',
      author: 'NutriSense',
    ),
    _DailyQuote(
      quote: 'One focused block can turn a busy day into a clear one.',
      author: 'NutriSense',
    ),
    _DailyQuote(
      quote: 'Your routine is built one meal, one workout, one task at a time.',
      author: 'NutriSense',
    ),
    _DailyQuote(
      quote: 'Rest is part of the plan, not a break from it.',
      author: 'NutriSense',
    ),
    _DailyQuote(
      quote: 'Start where you are and make today easier to repeat tomorrow.',
      author: 'NutriSense',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[DateTime.now().weekday - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2D8C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: _HomePageState.gold, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${quote.quote}"',
                  style: const TextStyle(
                    color: _HomePageState.navy,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '- ${quote.author}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuote {
  const _DailyQuote({required this.quote, required this.author});

  final String quote;
  final String author;
}

class ProgressCircle extends StatelessWidget {
  const ProgressCircle({
    super.key,
    required this.valueLabel,
    required this.unit,
    required this.label,
    required this.progress,
    required this.color,
  });

  final String valueLabel;
  final String unit;
  final String label;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: color.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    valueLabel,
                    style: const TextStyle(
                      fontSize: 16,
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
