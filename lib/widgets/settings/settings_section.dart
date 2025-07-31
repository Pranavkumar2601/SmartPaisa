// lib/widgets/settings/settings_section.dart

import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark Black
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF004D40).withOpacity(0.5), // Dark Teal Green border
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.2), // Dark Teal Green shadow
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF4500), // Dark OrangeRed
                        Color(0xFF008000), // Green
                        Color(0xFF0000FF), // Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
