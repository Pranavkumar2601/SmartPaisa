// lib/widgets/dialogs/reset_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

class ResetDialog extends StatefulWidget {
  final Function(Set<String>) onReset;

  const ResetDialog({
    super.key,
    required this.onReset,
  });

  @override
  State<ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<ResetDialog>
    with TickerProviderStateMixin {
  final Set<String> _selectedOptions = {};
  late AnimationController _dialogController;
  late AnimationController _pulseController;
  late Animation<double> _dialogAnimation;
  late Animation<double> _pulseAnimation;

  final Map<String, Map<String, dynamic>> _resetOptions = {
    'transactions': {
      'title': 'All Transactions',
      'subtitle': 'Delete complete transaction history',
      'icon': Icons.receipt_long_rounded,
      'color': AppTheme.darkOrangeRed,
      'warning': 'This will permanently remove all your transaction records.',
    },
    'categories': {
      'title': 'Custom Categories',
      'subtitle': 'Remove user-created categories',
      'icon': Icons.category_rounded,
      'color': AppTheme.vibrantBlue,
      'warning': 'Default categories will remain, custom ones will be deleted.',
    },
    'settings': {
      'title': 'App Settings',
      'subtitle': 'Reset all preferences to default',
      'icon': Icons.settings_rounded,
      'color': AppTheme.tealGreenDark,
      'warning': 'All your customizations will be lost.',
    },
    'learning': {
      'title': 'AI Learning Data',
      'subtitle': 'Clear machine learning patterns',
      'icon': Icons.psychology_rounded,
      'color': AppTheme.vibrantGreen,
      'warning': 'Smart suggestions will need to re-learn your patterns.',
    },
    'cache': {
      'title': 'App Cache & Temp Files',
      'subtitle': 'Clear temporary files and data',
      'icon': Icons.storage_rounded,
      'color': AppTheme.tealGreenDark,
      'warning': 'Safe to clear, may improve app performance.',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.elasticOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _dialogController.forward();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _dialogAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 700),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.cardDarkGray,
                AppTheme.cardDarkGray.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.darkOrangeRed.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkOrangeRed.withOpacity(0.1),
            AppTheme.darkOrangeRed.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkOrangeRed,
                        AppTheme.darkOrangeRed.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkOrangeRed.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select data types to reset permanently',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ..._resetOptions.entries.map((entry) {
            return _buildResetOption(entry.key, entry.value);
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResetOption(String key, Map<String, dynamic> option) {
    final isSelected = _selectedOptions.contains(key);
    final color = option['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ]
              : [
            AppTheme.surfaceGray,
            AppTheme.surfaceGray.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedOptions.remove(key);
              } else {
                _selectedOptions.add(key);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                          : null,
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option['warning'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          if (_selectedOptions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkOrangeRed.withOpacity(0.1),
                    AppTheme.darkOrangeRed.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkOrangeRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.darkOrangeRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. Selected data will be permanently deleted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkOrangeRed,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _selectedOptions.isEmpty
                        ? null
                        : LinearGradient(
                      colors: [
                        AppTheme.darkOrangeRed,
                        AppTheme.darkOrangeRed.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedOptions.isEmpty
                        ? null
                        : [
                      BoxShadow(
                        color: AppTheme.darkOrangeRed.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedOptions.isEmpty
                        ? null
                        : () {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context).pop();
                      widget.onReset(_selectedOptions);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedOptions.isEmpty
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _selectedOptions.isEmpty
                          ? 'Select Items'
                          : 'Reset ${_selectedOptions.length} Items',
                      style: TextStyle(
                        color: _selectedOptions.isEmpty
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
