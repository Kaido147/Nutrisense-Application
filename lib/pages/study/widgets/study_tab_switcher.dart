import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';

class StudyTabSwitcher extends StatelessWidget {
  const StudyTabSwitcher({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final StudyTab selectedTab;
  final ValueChanged<StudyTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: StudyTheme.softShadow,
      ),
      child: Row(
        children: [
          _StudyTabButton(
            label: 'Focus Mode',
            icon: Icons.menu_book_outlined,
            isSelected: selectedTab == StudyTab.focusMode,
            onTap: () => onTabSelected(StudyTab.focusMode),
          ),
          _StudyTabButton(
            label: 'Journal & Mood',
            icon: Icons.auto_stories_outlined,
            isSelected: selectedTab == StudyTab.journalMood,
            onTap: () => onTabSelected(StudyTab.journalMood),
          ),
        ],
      ),
    );
  }
}

class _StudyTabButton extends StatelessWidget {
  const _StudyTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? StudyTheme.navyBlue : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : StudyTheme.navyBlue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : StudyTheme.navyBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
