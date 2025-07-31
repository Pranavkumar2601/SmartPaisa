// lib/screens/settings_screen.dart (Enhanced Interactive UI)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';
import '../services/sms_sync_service.dart';
import '../services/storage_service.dart';
import '../models/haptic_feedback_type.dart';
import '../theme/theme.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {

  final SettingsService _settings = SettingsService.instance;
  final SmsService _smsService = SmsService.instance;
  final SmsSyncService _syncService = SmsSyncService.instance;
  final StorageService _storage = StorageService.instance;

  // Enhanced Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _isSyncing = false;
  bool _isClearing = false;
  String _syncStatus = '';
  Map<String, dynamic> _syncInfo = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSyncInfo();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _loadSyncInfo() {
    setState(() {
      _syncInfo = _syncService.getSyncStatus();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildEnhancedAppBar(innerBoxIsScrolled),
            ],
            body: _buildEnhancedContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.vibrantBlue,
              AppTheme.tealGreenDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.vibrantBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildEnhancedContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // SMS & Sync Section
        _buildSectionHeader('Connectivity & Sync', Icons.sync_rounded, AppTheme.vibrantBlue),
        _buildEnhancedSyncCard(),
        const SizedBox(height: 16),
        _buildEnhancedSyncButton(),
        const SizedBox(height: 32),

        // App Preferences Section
        _buildSectionHeader('App Preferences', Icons.tune_rounded, AppTheme.vibrantGreen),
        _buildEnhancedPreferencesCard(),
        const SizedBox(height: 32),

        // Notifications Section
        _buildSectionHeader('Notifications', Icons.notifications_rounded, AppTheme.warningOrange),
        _buildEnhancedNotificationCard(),
        const SizedBox(height: 32),

        // Data Management Section
        _buildSectionHeader('Data Management', Icons.storage_rounded, AppTheme.darkOrangeRed),
        _buildEnhancedDataManagementCard(),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSyncCard() {
    final isOnline = _syncInfo['lastSync'] != null;
    final lastSyncDate = _syncInfo['lastSync'] as DateTime?;
    final processedCount = _syncInfo['processedCount'] as int? ?? 0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.02,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOnline
                    ? AppTheme.vibrantGreen.withOpacity(0.3)
                    : AppTheme.darkOrangeRed.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isOnline
                      ? AppTheme.vibrantGreen.withOpacity(0.1)
                      : AppTheme.darkOrangeRed.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOnline
                              ? [AppTheme.vibrantGreen, AppTheme.vibrantGreen.withOpacity(0.8)]
                              : [AppTheme.darkOrangeRed, AppTheme.darkOrangeRed.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline ? AppTheme.vibrantGreen : AppTheme.darkOrangeRed).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'Sync Active' : 'Not Synced',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isOnline ? AppTheme.vibrantGreen : AppTheme.darkOrangeRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSyncStatusText(lastSyncDate),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (processedCount > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.vibrantBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.vibrantBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$processedCount transactions processed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.vibrantBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_isSyncing) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.vibrantBlue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _syncStatus,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.vibrantBlue,
                              fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  Widget _buildEnhancedSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSyncing ? null : _performManualSync,
        icon: _isSyncing
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.sync_rounded, size: 20),
        label: Text(
          _isSyncing ? 'Syncing...' : 'Sync Recent Transactions',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.vibrantBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppTheme.vibrantBlue.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildEnhancedPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ REMOVED: Theme Selector - no longer needed

          // Haptic Feedback
          _buildEnhancedSettingTile(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            subtitle: 'Feel vibrations for interactions',
            color: AppTheme.vibrantGreen,
            trailing: Switch.adaptive(
              value: _settings.getBool('haptic_feedback', true),
              onChanged: (value) {
                _settings.saveSetting('haptic_feedback', value);
                setState(() {});
                if (value) {
                  _settings.triggerHaptic(HapticFeedbackType.success);
                }
              },
              activeColor: AppTheme.vibrantGreen,
            ),
          ),

          const Divider(height: 1),

          // Smart Suggestions
          _buildEnhancedSettingTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Smart Suggestions',
            subtitle: 'AI-powered transaction categorization',
            color: AppTheme.tealGreenDark,
            trailing: Switch.adaptive(
              value: _settings.getBool('enable_smart_suggestions', true),
              onChanged: (value) {
                _settings.saveSetting('enable_smart_suggestions', value);
                setState(() {});
                if (_settings.getBool('haptic_feedback', true)) {
                  _settings.triggerHaptic(HapticFeedbackType.selection);
                }
              },
              activeColor: AppTheme.tealGreenDark,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEnhancedNotificationCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildEnhancedSettingTile(
        icon: Icons.notifications_rounded,
        title: 'Transaction Notifications',
        subtitle: 'Get notified of new transactions',
        color: AppTheme.warningOrange,
        trailing: Switch.adaptive(
          value: _settings.getBool('enable_notifications', true),
          onChanged: (value) {
            _settings.saveSetting('enable_notifications', value);
            setState(() {});
            if (_settings.getBool('haptic_feedback', true)) {
              _settings.triggerHaptic(HapticFeedbackType.selection);
            }
          },
          activeColor: AppTheme.warningOrange,
        ),
      ),
    );
  }

  Widget _buildEnhancedDataManagementCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkOrangeRed.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkOrangeRed.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkOrangeRed, AppTheme.darkOrangeRed.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkOrangeRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
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
                      'Danger Zone',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkOrangeRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Irreversible actions that affect all your data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isClearing ? null : _showClearDataDialog,
              icon: _isClearing
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.delete_forever_rounded, size: 20),
              label: Text(
                _isClearing ? 'Clearing...' : 'Clear All Data',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkOrangeRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppTheme.darkOrangeRed.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }

  // Helper Methods
  String _getSyncStatusText(DateTime? lastSync) {
    if (lastSync == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) return 'Synced just now';
    if (difference.inHours < 1) return 'Synced ${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return 'Synced ${difference.inHours} hours ago';
    return 'Synced ${difference.inDays} days ago';
  }

  Future<void> _performManualSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Starting sync...';
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await _syncService.triggerManualSync();

      // ✅ SOLUTION: Immediately update sync info after successful sync
      if (result.success) {
        // Update sync info immediately to refresh UI
        setState(() {
          _syncInfo = _syncService.getSyncStatus(); // Get fresh sync status
          _syncStatus = 'Found ${result.newTransactions} new transactions';
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  result.newTransactions > 0
                      ? 'Found ${result.newTransactions} new transactions!'
                      : 'No new transactions found',
                ),
              ],
            ),
            backgroundColor: AppTheme.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.success);
        }
      } else {
        setState(() {
          _syncStatus = 'Sync failed: ${result.message}';
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Sync failed: ${result.message}'),
              ],
            ),
            backgroundColor: AppTheme.darkOrangeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.error);
        }
      }
    } catch (e) {
      setState(() {
        _syncStatus = 'Sync error occurred';
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Sync error occurred'),
            ],
          ),
          backgroundColor: AppTheme.darkOrangeRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      // Reset sync status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSyncing = false;
            _syncStatus = '';
          });
        }
      });
    }
  }


  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.darkOrangeRed),
            const SizedBox(width: 12),
            const Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL your transactions, categories, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkOrangeRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    setState(() => _isClearing = true);

    try {
      // Clear all data through storage service
      await _storage.clearAllData();

      // Reset sync info
      await _syncService.resetSyncStatus();

      // Clear settings but keep theme preference
      final currentTheme = _settings.getThemeMode();
      await _settings.clearAllSettings();
      await _settings.setThemeMode(currentTheme);

      if (mounted) {
        setState(() {
          _syncInfo = {};
          _syncStatus = '';
          _isSyncing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('All data cleared successfully'),
              ],
            ),
            backgroundColor: AppTheme.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (_settings.getBool('haptic_feedback', true)) {
          _settings.triggerHaptic(HapticFeedbackType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Failed to clear data: $e'),
              ],
            ),
            backgroundColor: AppTheme.darkOrangeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
