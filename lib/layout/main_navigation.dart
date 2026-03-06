import 'package:flutter/material.dart';
import '../pages/home.dart';
import '../pages/workout.dart';
import '../pages/study.dart';
import '../pages/profile.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _goldTan = Color(0xFFD4B896);

  // Only 4 real pages — no FAB page
  final List<Widget> _pages = const [
    HomePage(),
    WorkoutPage(),
    StudyPage(),
    ProfilePage(),
  ];

  // Maps nav button index (0,1,3,4) → page index (0,1,2,3) Galing Ecantadia
  int _navToPage(int navIndex) {
  if (navIndex > 2) return navIndex - 1;
  return navIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Nav bar background
            Container(
              decoration: const BoxDecoration(
                color: _navyBlue,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_outlined, 'Home', 0),
                  _buildNavItem(Icons.fitness_center_outlined, 'Workout', 1),
                  const SizedBox(width: 52), // space for FAB
                  _buildNavItem(Icons.menu_book_outlined, 'Study', 3),
                  _buildNavItem(Icons.person_outline, 'Profile', 4),
                ],
              ),
            ),
            // Overlapping center FAB
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _goldTan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: _navyBlue, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int navIndex) {
    final bool isSelected = _currentIndex == _navToPage(navIndex);
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = _navToPage(navIndex)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? _goldTan : Colors.white.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? _goldTan : Colors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}