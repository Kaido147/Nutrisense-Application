import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:nutrisense/theme_provider.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomePage({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return p.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColorValue;
        final Color navy = primaryColor;
        final Color bg = const Color(0xFFF3F0EC);
        final Color cardColor = Colors.white;
        final Color gold = const Color(0xFFD6B66E);
        final Color blue = const Color(0xFF6A9CF6);
        final Color green = const Color(0xFF22C55E);
        final Color textDark = const Color(0xFF1F2A44);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(34),
                        bottomRight: Radius.circular(34),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning, Alex',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Ready to balance your day?',
                              style: TextStyle(
                                color: Color(0xFFE0E5F2),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFB8A98B),
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Icon(Icons.person, color: Color(0xFF7C5AA6)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        children: [
                          // Today's Progress Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                Text(
                                  "Today's Progress",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ProgressCircle(
                                      value: '4.2',
                                      unit: 'hrs',
                                      label: 'Study',
                                      color: navy,
                                    ),
                                    ProgressCircle(
                                      value: '45',
                                      unit: 'min',
                                      label: 'Workout',
                                      color: gold,
                                    ),
                                    ProgressCircle(
                                      value: '8',
                                      unit: 'hrs',
                                      label: 'Sleep',
                                      color: blue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Weekly Overview title
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Weekly Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Weekly Overview cards
                          Row(
                            children: [
                              Expanded(
                                child: OverviewCard(
                                  icon: Icons.access_time,
                                  iconColor: navy,
                                  value: '28.5h',
                                  title: 'Study Time',
                                  subtitle: '+12%',
                                  subtitleColor: green,
                                  bgIconColor: const Color(0xFFEFF2F8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OverviewCard(
                                  icon: Icons.gps_fixed,
                                  iconColor: gold,
                                  value: '5/7',
                                  title: 'Workout Days',
                                  subtitle: 'On track',
                                  subtitleColor: green,
                                  bgIconColor: const Color(0xFFF8F3E8),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Quick Actions title
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Quick Action Button
                          GestureDetector(
                            onTap: () {
                              onNavigateTab?.call(2);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: navy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFF3C4E82),
                                    child: Icon(
                                      Icons.access_time,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Study Session',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Focus mode with timer',
                                          style: TextStyle(
                                            color: Color(0xFFD8E0F2),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: () {
                              onNavigateTab?.call(1);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFD6B66E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFE7D4A5),
                                    child: Icon(Icons.gps_fixed, color: navy),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Workout',
                                          style: TextStyle(
                                            color: navy,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Today's routine ready",
                                          style: TextStyle(
                                            color: Color(0xFF3F4A5A),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward, color: navy),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1ECE6), // light beige
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2D8C9),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.auto_awesome, // sparkle icon
                                  color: Color(0xFFD6B66E),
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '"Success is the sum of small efforts\nrepeated day in and day out."',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: navy,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        '— Robert Collier',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7A7F8C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProgressCircle extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const ProgressCircle({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = p.Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColorValue;

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
                  value: 0.78,
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
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
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
  final IconData icon;
  final Color iconColor;
  final Color bgIconColor;
  final String value;
  final String title;
  final String subtitle;
  final Color subtitleColor;

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = p.Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColorValue;

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
          const SizedBox(height: 28),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 14, color: Color(0xFF667085))),
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
