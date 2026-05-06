import 'package:flutter/material.dart';
import 'modals/workout/exercise_modal.dart';
import 'nutrition_tab.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedTab = 0;
  bool _isPressed = false;
  static const Color _lightBg = Color(0xFFF5F0EA);
  static const Color _cream = Color(0xFFF5F0E9);

  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  // Placeholdee for exercises list
  final List<Map<String, dynamic>> _exercises = [
    {'name': 'Push-ups', 'sets': '3 x 15 reps', 'done': true, 'num': 1},
    {'name': 'Bench Press', 'sets': '4 x 10 reps', 'done': true, 'num': 2},
    {'name': 'Shoulder Press', 'sets': '3 x 12 reps', 'done': false, 'num': 3},
    {'name': 'Tricep Dips', 'sets': '3 x 15 reps', 'done': false, 'num': 4},
  ];

  // Weekly plan data
  final List<Map<String, dynamic>> _weeklyPlan = [
    {'day': 'Mon', 'activity': 'Cardio', 'completed': true},
    {'day': 'Tue', 'activity': 'Upper Body', 'completed': true},
    {'day': 'Wed', 'activity': 'Rest', 'completed': false},
    {'day': 'Thu', 'activity': 'Lower Body', 'completed': false},
    {'day': 'Fri', 'activity': 'Core', 'completed': false},
  ];

  //  Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderStack(context),
            const SizedBox(height: 40),
            // Conditionally show Workout or Nutrition content
            if (_selectedTab == 0) ..._buildWorkoutContent(),
            if (_selectedTab == 1) const NutritionTab(),
            const SizedBox(height: 20), // bottom breathing room
          ],
        ),
      ),
    );
  }

  /// Workout tab content
  List<Widget> _buildWorkoutContent() {
    return [
      workoutCard(),
      const SizedBox(height: 24),
      exerciseCard(),
      const SizedBox(height: 12),
      weeklyPlan(),
    ];
  }

  Padding exerciseCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercises Title
          Text(
            'Exercises',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Exercises List
          Column(
            children: _exercises.map((exercise) {
              final isCompleted = exercise['done'];

              return Opacity(
                opacity: isCompleted ? 0.6 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left side: Icon or Number
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 24,
                              )
                            : Center(
                                child: Text(
                                  exercise['num'].toString(),
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),

                      // Middle: Exercise name and sets
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise['name'],
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise['sets'],
                              style: TextStyle(
                                color: _primaryColor.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right side: Check mark or Start button
                      if (isCompleted)
                        const SizedBox.shrink()
                      else
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Starting ${exercise['name']}...',
                                ),
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Start',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Padding weeklyPlan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Weekly Plan" Title with "View All"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Plan',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('View All Plans'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekly Plan Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with calendar icon and "This Week's Focus" (inside card)
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: _primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'This Week\'s Focus',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weekly Plan List
                ..._weeklyPlan.map((plan) {
                  final isCompleted = plan['completed'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : Colors.grey.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${plan['day']}: ${plan['activity']}',
                          style: TextStyle(
                            color: _primaryColor.withValues(
                              alpha: isCompleted ? 1.0 : 1.0,
                            ),
                            fontWeight: isCompleted
                                ? FontWeight.w400
                                : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column workoutCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Today\'s Routine',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Container na B
        SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 21),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon, Title and SubTitle
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _cream.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    // Icon
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upper Body Strength',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 3),
                      Opacity(
                        opacity: 0.5,
                        child: Text(
                          '45 minutes • Intermediate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Percentage Bar
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.4,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '0%',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Button "Continue Workout"
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _isPressed = true);
                    await Future.delayed(const Duration(milliseconds: 150));
                    setState(() => _isPressed = false);
                    showExerciseModal(context);
                  },

                  // Animation
                  child: AnimatedScale(
                    scale: _isPressed ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.white,
                          disabledForegroundColor: _primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: const Text(
                          'Continue Workout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //  Header Stack
  /// Combines the navy header and the overlapping tab toggle into a Stack.
  Widget _buildHeaderStack(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [_buildNavyHeader(context), _buildTabToggle()],
    );
  }

  // Navy Header
  /// Dark blue rounded container showing the app title and subtitle.
  Widget _buildNavyHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        left: 20,
        right: 20,
        bottom: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderTitle(),
          const SizedBox(height: 4),
          _buildHeaderSubtitle(),
        ],
      ),
    );
  }

  /// "Wellness Hub" bold white title.
  Widget _buildHeaderTitle() {
    return const Text(
      'Wellness Hub',
      style: TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Muted gold subtitle beneath the title.
  Widget _buildHeaderSubtitle() {
    return Text(
      'Your fitness & nutrition tracker',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 13,
      ),
    );
  }

  // Tab Toggle
  /// Floating pill-shaped toggle that overlaps the bottom edge of the header.
  Widget _buildTabToggle() {
    return Positioned(
      bottom: -22,
      left: 40,
      right: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [_buildTab('Workout', 0), _buildTab('Nutrition', 1)],
        ),
      ),
    );
  }

  /// A single animated tab inside the toggle pill.
  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: _buildTabLabel(label, isSelected),
        ),
      ),
    );
  }

  /// Text label styled based on selected state.
  Widget _buildTabLabel(String label, bool isSelected) {
    return Text(
      label,
      style: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF718096),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}
