import 'package:flutter/material.dart';

abstract final class StudyTheme {
  static const Color navyBlue = Color(0xFF1F2937);
  static const Color pageBackground = Color(0xFFF5F0E9);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF8D95A6);
  static const Color chipBackground = Color(0xFFF1F3F8);
  static const Color cardBorder = Color(0xFFE8E2D9);
  static const Color divider = Color(0xFFEDE8E0);
  static const Color subtlePurple = Color(0xFFF8ECFF);
  static const Color subtlePurpleText = Color(0xFF9A32FF);
  static const double horizontalPadding = 18;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: horizontalPadding,
  );
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
}
