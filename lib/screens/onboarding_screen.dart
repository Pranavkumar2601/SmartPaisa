// lib/screens/onboarding_screen.dart (COMPLETE FIXED VERSION)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

import '../services/settings_service.dart';
import '../theme/theme.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _settings = SettingsService.instance;

  // ✅ FIXED: Enhanced permission tracking (only essential permissions)
  bool _smsGranted = false;
  bool _notificationGranted = false;
  bool _isRequesting = false;
  bool _hasCheckedInitially = false;

  // ✅ ENHANCED: Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _resetPermissionFlags();
    _checkPermissions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ✅ ENHANCED: Initialize animations
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
  }

  // ✅ FIXED: Check only essential permissions
  Future<void> _checkPermissions() async {
    if (_hasCheckedInitially) return;

    try {
      print('🔍 Checking essential permissions...');

      final smsStatus = await Permission.sms.status;
      final notificationStatus = await Permission.notification.status;

      print('📋 Permission Status:');
      print('  📱 SMS: $smsStatus');
      print('  🔔 Notifications: $notificationStatus');
      print('  💾 Storage: Auto-granted by Android 11+ (not needed)');

      if (mounted) {
        setState(() {
          _smsGranted = smsStatus.isGranted;
          _notificationGranted = notificationStatus.isGranted;
          _hasCheckedInitially = true;
        });
      }

      // Auto-complete if essential permissions are granted
      if (_allPermissionsGranted) {
        print('✅ All essential permissions granted, completing onboarding...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _completeOnboarding();
      }

    } catch (e) {
      print('❌ Error checking permissions: $e');
      if (mounted) {
        setState(() => _hasCheckedInitially = true);
      }
    }
  }

  // ✅ FIXED: Proper permission state check (only SMS and notifications)
  bool get _allPermissionsGranted => _smsGranted && _notificationGranted;

  // ✅ FIXED: Request only essential permissions
  Future<void> _requestPermissions() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      print('📱 Requesting essential permissions...');

      final permissionsToRequest = <Permission>[];
      if (!_smsGranted) permissionsToRequest.add(Permission.sms);
      if (!_notificationGranted) permissionsToRequest.add(Permission.notification);

      if (permissionsToRequest.isEmpty) {
        print('✅ All permissions already granted');
        await _completeOnboarding();
        return;
      }

      final statuses = await permissionsToRequest.request();

      // Update state based on results
      bool smsGranted = _smsGranted;
      bool notificationGranted = _notificationGranted;

      for (final entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;

        switch (permission) {
          case Permission.sms:
            smsGranted = status.isGranted;
            break;
          case Permission.notification:
            notificationGranted = status.isGranted;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _smsGranted = smsGranted;
          _notificationGranted = notificationGranted;
        });
      }

      if (_allPermissionsGranted) {
        print('✅ All essential permissions granted successfully');
        await _completeOnboarding();
      } else {
        await _handleDeniedPermissions();
      }

    } catch (e) {
      print('❌ Error requesting permissions: $e');
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  // ✅ FIXED: Handle denied permissions
  Future<void> _handleDeniedPermissions() async {
    final deniedPermissions = <String>[];

    if (!_smsGranted) deniedPermissions.add('SMS Access');
    if (!_notificationGranted) deniedPermissions.add('Notifications');

    if (deniedPermissions.isNotEmpty) {
      _showPermissionExplanationDialog(deniedPermissions);
    }
  }

  Future<void> _resetPermissionFlags() async {
    try {
      // Clear any cached permission states that might be causing issues
      await _settings.saveSetting('permissions_requested', false);
      await _settings.saveSetting('onboarding_complete', false);
      print('🔄 ONBOARDING: Permission flags reset for fresh check');
    } catch (e) {
      print('❌ ONBOARDING: Error resetting permission flags: $e');
    }
  }

  // ✅ ENHANCED: Permission explanation dialog
  void _showPermissionExplanationDialog(List<String> deniedPermissions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security_rounded, color: AppTheme.vibrantBlue, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Permissions Required',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SmartPaisa needs these permissions to work properly:',
              style: TextStyle(color: Color(0xFF7CB9E8), fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...deniedPermissions.map((permission) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.chevron_right, color: AppTheme.vibrantGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPermissionExplanation(permission),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.vibrantBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.vibrantBlue.withOpacity(0.3)),
              ),
              child: const Text(
                'Your financial data remains completely secure and private.',
                style: TextStyle(color: Color(0xFF7CB9E8), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _skipOnboarding();
            },
            child: const Text('Skip for Now', style: TextStyle(color: Color(0xFF7CB9E8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _getPermissionExplanation(String permission) {
    switch (permission) {
      case 'SMS Access':
        return 'Read SMS messages to automatically detect bank transactions';
      case 'Notifications':
        return 'Show notifications for new transactions and important updates';
      default:
        return 'Required for app functionality';
    }
  }

  // ✅ FIXED: Skip onboarding with limited functionality
  Future<void> _skipOnboarding() async {
    try {
      print('⏭️ Skipping onboarding with limited permissions...');

      // Mark onboarding as completed but with limited permissions
      await _settings.saveSetting('onboarding_complete', true);
      await _settings.saveSetting('permissions_limited', true);
      await _settings.saveSetting('onboarding_completed_at', DateTime.now().toIso8601String());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }

    } catch (e) {
      print('❌ Error skipping onboarding: $e');
    }
  }

  // ✅ FIXED: Complete onboarding with all permissions
  Future<void> _completeOnboarding() async {
    try {
      // Mark onboarding as complete
      await _settings.saveSetting('onboarding_complete', true);
      await _settings.saveSetting('permissions_verified', true);
      await _settings.saveSetting('permissions_limited', false);
      await _settings.saveSetting('onboarding_completed_at', DateTime.now().toIso8601String());

      // Set first app use date
      final firstUseDate = _settings.getString('app_first_use_date', '');
      if (firstUseDate.isEmpty) {
        await _settings.saveSetting('app_first_use_date', DateTime.now().toIso8601String());
      }

      print('✅ Onboarding completed successfully');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      print('❌ Error completing onboarding: $e');
      _showErrorDialog('Setup Error', 'Failed to complete setup. Please try again.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Color(0xFF7CB9E8))),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27), // Deep navy
              Color(0xFF162447), // Darker blue
              Color(0xFF1F4068), // Medium blue
              Color(0xFF162447), // Back to darker blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // ✅ ENHANCED: Welcome section with animation
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // ✅ ENHANCED: Lottie welcome animation
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: Lottie.asset(
                                  'assets/animations/loading_money.json',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppTheme.vibrantGreen, AppTheme.vibrantBlue],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.vibrantGreen.withOpacity(0.3),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ✅ ENHANCED: Welcome text with gradient
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                                ).createShader(bounds),
                                child: const Text(
                                  'Welcome to\nSmartPaisa',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your intelligent SMS-based\ntransaction tracker',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7CB9E8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ✅ ENHANCED: Permission requirements
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.vibrantBlue.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.vibrantBlue.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.security_rounded, color: AppTheme.vibrantGreen, size: 20),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Required Permissions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ✅ FIXED: Show permission cards when ready
                                if (_hasCheckedInitially) ...[
                                  _buildPermissionCard(
                                    'SMS Access',
                                    'Required to read transaction messages from banks',
                                    Icons.sms_rounded,
                                    _smsGranted,
                                  ),
                                  _buildPermissionCard(
                                    'Notifications',
                                    'Show alerts for new transactions and sync status',
                                    Icons.notifications_rounded,
                                    _notificationGranted,
                                  ),
                                ] else ...[
                                  // Loading state
                                  const SizedBox(
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ✅ ENHANCED: Action buttons
                        if (_hasCheckedInitially) ...[
                          if (!_allPermissionsGranted) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isRequesting ? null : _requestPermissions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.vibrantGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppTheme.vibrantGreen.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: AppTheme.vibrantGreen.withOpacity(0.3),
                                ),
                                child: _isRequesting
                                    ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Requesting Permissions...', style: TextStyle(fontSize: 15)),
                                  ],
                                )
                                    : const Text(
                                  'Grant Permissions',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _isRequesting ? null : _skipOnboarding,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF7CB9E8),
                                  side: const BorderSide(color: Color(0xFF7CB9E8)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Skip for Now',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 16),

                        // ✅ ENHANCED: Privacy notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.vibrantBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.vibrantBlue.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_rounded, color: Color(0xFF00D2FF), size: 18),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your financial data is encrypted and stored locally. We never share your information.',
                                  style: TextStyle(
                                    color: Color(0xFF7CB9E8),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ENHANCED: Permission card with modern design
  Widget _buildPermissionCard(String title, String description, IconData icon, bool isGranted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGranted
              ? [AppTheme.vibrantGreen.withOpacity(0.15), AppTheme.vibrantGreen.withOpacity(0.08)]
              : [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppTheme.vibrantGreen.withOpacity(0.4) : Colors.orange.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGranted ? AppTheme.vibrantGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: isGranted ? AppTheme.vibrantGreen : Colors.orange, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
            color: isGranted ? AppTheme.vibrantGreen : Colors.orange,
            size: 26,
          ),
        ],
      ),
    );
  }
}
