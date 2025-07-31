// lib/widgets/settings/switch_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

class SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value && enabled
              ? AppTheme.vibrantGreen.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? () => onChanged(!value) : null,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: value && enabled
                        ? LinearGradient(
                      colors: [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.7)],
                    )
                        : null,
                    color: value && enabled ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: value && enabled ? Colors.white : Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: enabled
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: value && enabled
                        ? LinearGradient(
                      colors: [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.8)],
                    )
                        : null,
                    color: value && enabled ? null : Colors.white.withOpacity(0.2),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: value ? 24 : 2,
                        top: 2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
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
