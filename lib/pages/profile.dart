import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, "/login");
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 70),
              decoration: const BoxDecoration(
                color: Color(0xFF243A6E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white24,
                    child: Icon(LucideIcons.user, size: 50, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  const Text("Alex Johnson",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("alex.johnson@student.edu",
                      style: TextStyle(fontSize: 10, color: Color(0xFFE0C58F))),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black12)],
                ),
                child: Column(
                  children: [
                    _progressRow(icon: LucideIcons.target, title: "Weekly Study Goal", value: "28 / 30h", progress: 0.95),
                    const SizedBox(height: 25),
                    _progressRow(icon: LucideIcons.zap, title: "Workout Streak", value: "5 / 7 days", progress: 0.7),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Settings", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            _settingsItem(icon: LucideIcons.user, title: "Edit Profile", subtitle: "Update your information", iconColor: Color(0xFF243A6E), borderColor: Color(0xFF243A6E)),
            _settingsItem(icon: LucideIcons.target, title: "Goals & Preferences", subtitle: "Manage your targets", iconColor: Color(0xFFE0C58F), borderColor: Color(0xFFE0C58F)),
            _settingsItem(icon: LucideIcons.moon, title: "Theme", subtitle: "Light mode", iconColor: Colors.purple, borderColor: Colors.purpleAccent),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Center(
                    child: Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _progressRow({required IconData icon, required String title, required String value, required double progress}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFE0C58F)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 10))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          color: const Color(0xFFE0C58F),
          backgroundColor: const Color(0xFFEEEEEE),
        ),
      ],
    );
  }

  Widget _settingsItem({required IconData icon, required String title, required String subtitle, Color iconColor = Colors.blue, Color borderColor = Colors.blueAccent}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
              color: iconColor.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}