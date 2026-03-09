import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedTab = 0;
  bool _isPressed = false;

  // ─── Kulay ng Buhay ──────────────────────────────────────────────────────────────
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _lightBg = Color(0xFFF5F0EA);
  static const Color _goldTan = Color(0xFFE0C58F);
  static const Color _cream = Color(0xFFF5F0E9);

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderStack(context),
          SizedBox(height: 40),
          workoutCard(),
          
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
                  color: _navyBlue,
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
                color: _goldTan,
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upper Body Strength',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _navyBlue,
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
                                color: _navyBlue,
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
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.4,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '0%',
                        style: TextStyle(
                          color: _navyBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Button "Continue Workout"
                  Container(
                  margin: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
                  child:   GestureDetector(
                    onTap: () async {
                          setState(() => _isPressed = true);
                          await Future.delayed(const Duration(milliseconds: 150));
                          setState(() => _isPressed = false);
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
                            disabledForegroundColor: _navyBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  )
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
      decoration: const BoxDecoration(
        color: _navyBlue,
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
    return const Text(
      'Your fitness & nutrition tracker',
      style: TextStyle(color: _goldTan, fontSize: 13),
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
            color: isSelected ? _navyBlue : Colors.transparent,
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
