// lib/main.dart (PRODUCTION-READY FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

import 'services/settings_service.dart';
import 'services/sms_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/category_service.dart';
import 'services/sms_sync_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_screen.dart';
import 'theme/theme.dart';

void main() async {
  // ✅ PRODUCTION: Comprehensive error handling for main function
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ PRODUCTION: Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('❌ FLUTTER ERROR: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // ✅ PRODUCTION: Initialize core services with bulletproof error handling
  try {
    print('🚀 Initializing SmartPaisa Production...');

    await SettingsService.instance.init();
    print('✅ Settings service initialized');

    await StorageService.instance.init();
    print('✅ Storage service initialized');

    print('✅ Core services initialized successfully');
  } catch (e, stackTrace) {
    print('❌ CRITICAL ERROR initializing core services: $e');
    print('Stack trace: $stackTrace');

    // ✅ PRODUCTION: Don't crash, try to continue with basic functionality
    try {
      await _emergencyInitialization();
    } catch (emergencyError) {
      print('❌ Emergency initialization also failed: $emergencyError');
    }
  }

  runApp(const SmartPaisaApp());
}

// ✅ PRODUCTION: Emergency initialization fallback
Future<void> _emergencyInitialization() async {
  try {
    print('🚨 Attempting emergency initialization...');

    // Try to initialize just the absolutely essential services
    await SettingsService.instance.init();

    print('✅ Emergency initialization completed');
  } catch (e) {
    print('❌ Emergency initialization failed: $e');
    // At this point, we'll rely on the app's error handling
  }
}

class SmartPaisaApp extends StatefulWidget {
  const SmartPaisaApp({Key? key}) : super(key: key);

  @override
  State<SmartPaisaApp> createState() => _SmartPaisaAppState();
}

class _SmartPaisaAppState extends State<SmartPaisaApp> with WidgetsBindingObserver {
  bool _servicesInitialized = false;
  bool _initializationInProgress = false;
  String _initStatus = 'Starting...';
  bool _hasInitializationError = false;
  String _errorMessage = '';

  // ✅ PRODUCTION: Track service initialization status
  final Map<String, bool> _serviceStatus = {
    'settings': false,
    'storage': false,
    'sms': false,
    'notification': false,
    'category': false,
    'sync': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ PRODUCTION: Delayed initialization to ensure widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAllServices();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeServices();
    super.dispose();
  }

  // ✅ PRODUCTION: Proper service disposal
  void _disposeServices() {
    try {
      if (SmsService.instance.isInitialized) {
        SmsService.instance.dispose();
      }
    } catch (e) {
      print('❌ Error disposing SMS service: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (!_servicesInitialized) return;

    try {
      switch (state) {
        case AppLifecycleState.resumed:
          print('📱 [LIFECYCLE] App resumed - refreshing data');
          await _handleAppResume();
          break;
        case AppLifecycleState.paused:
          print('📱 [LIFECYCLE] App paused - saving state');
          await _handleAppPause();
          break;
        case AppLifecycleState.inactive:
          print('📱 [LIFECYCLE] App inactive');
          break;
        case AppLifecycleState.detached:
          print('📱 [LIFECYCLE] App detached');
          _disposeServices();
          break;
        case AppLifecycleState.hidden:
          print('📱 [LIFECYCLE] App hidden');
          break;
      }
    } catch (e) {
      print('❌ Error handling app lifecycle: $e');
    }
  }

  // ✅ PRODUCTION: Enhanced app resume handling
  Future<void> _handleAppResume() async {
    try {
      // Resume SMS service
      if (SmsService.instance.isInitialized) {
        await SmsService.instance.resume();
      }

      // Refresh data
      await _refreshAppData();

      // Check for any missed transactions
      await _performQuickSync();

      print('✅ App resume handling completed');
    } catch (e) {
      print('❌ Error handling app resume: $e');
    }
  }

  // ✅ PRODUCTION: Enhanced app pause handling
  Future<void> _handleAppPause() async {
    try {
      // Pause SMS service
      if (SmsService.instance.isInitialized) {
        await SmsService.instance.pause();
      }

      // Save app state
      await _saveAppState();

      print('✅ App pause handling completed');
    } catch (e) {
      print('❌ Error handling app pause: $e');
    }
  }

  // ✅ PRODUCTION: Quick sync on resume
  Future<void> _performQuickSync() async {
    try {
      if (!SmsService.instance.isInitialized) return;

      await SmsService.instance.processHistoricalSms();
      print('✅ Quick sync completed');
    } catch (e) {
      print('❌ Error in quick sync: $e');
    }
  }

  // ✅ PRODUCTION: Enhanced data refresh
  Future<void> _refreshAppData() async {
    try {
      // Force reload storage data
      if (StorageService.instance.isInitialized) {
        await StorageService.instance.init();
      }

      // Refresh SMS service
      if (SmsService.instance.isInitialized) {
        await SmsService.instance.refreshPendingTransactions();
      }

      // Trigger UI updates
      if (mounted) {
        setState(() {});
      }

      print('✅ App data refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing app data: $e');
    }
  }

  // ✅ PRODUCTION: Enhanced state saving
  Future<void> _saveAppState() async {
    try {
      await SettingsService.instance.saveSetting('last_active_time', DateTime.now().toIso8601String());
      await SettingsService.instance.saveSetting('app_version', '1.0.0');

      print('✅ App state saved');
    } catch (e) {
      print('❌ Error saving app state: $e');
    }
  }

  // ✅ PRODUCTION: Comprehensive service initialization
  Future<void> _initializeAllServices() async {
    if (_initializationInProgress || _servicesInitialized) return;

    setState(() {
      _initializationInProgress = true;
      _initStatus = 'Initializing services...';
      _hasInitializationError = false;
      _errorMessage = '';
    });

    try {
      print('🚀 Initializing SmartPaisa Production Services...');

      // ✅ Step 1: Verify core services
      await _verifyAndInitializeCoreServices();

      // ✅ Step 2: Check permissions (don't request, just check)
      setState(() => _initStatus = 'Checking permissions...');
      await _checkExistingPermissions();

      // ✅ Step 3: Initialize notification service
      setState(() => _initStatus = 'Starting notification service...');
      await _initializeNotificationService();

      // ✅ Step 4: Initialize category service
      setState(() => _initStatus = 'Loading categories...');
      await _initializeCategoryService();

      // ✅ Step 5: Initialize SMS service
      setState(() => _initStatus = 'Starting SMS monitoring...');
      await _initializeSmsService();

      // ✅ Step 6: Initialize sync service
      setState(() => _initStatus = 'Setting up sync service...');
      await _initializeSyncService();

      // ✅ Step 7: Verify and refresh data
      setState(() => _initStatus = 'Verifying data integrity...');
      await _verifyAndRefreshData();

      // ✅ Step 8: Final health check
      setState(() => _initStatus = 'Finalizing...');
      await _verifyServicesHealth();

      _servicesInitialized = true;
      print('🎉 All SmartPaisa Production Services initialized successfully');

    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR initializing services: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _hasInitializationError = true;
        _errorMessage = e.toString();
        _initStatus = 'Initialization failed';
      });

      await _attemptGracefulRecovery();

    } finally {
      _initializationInProgress = false;
      if (mounted) {
        setState(() => _initStatus = _servicesInitialized ? 'Ready' : 'Error occurred');
      }
    }
  }

  // ✅ PRODUCTION: Verify and initialize core services
  Future<void> _verifyAndInitializeCoreServices() async {
    try {
      // Settings service
      if (!SettingsService.instance.isInitialized) {
        await SettingsService.instance.init();
      }
      _serviceStatus['settings'] = true;

      // Storage service
      if (!StorageService.instance.isInitialized) {
        await StorageService.instance.init();
      }
      _serviceStatus['storage'] = true;

      print('✅ Core services verified and initialized');
    } catch (e) {
      print('❌ Error initializing core services: $e');
      throw e;
    }
  }

  // ✅ PRODUCTION: Smart permission checking (FIXED)
  Future<void> _checkExistingPermissions() async {
    try {
      final smsStatus = await Permission.sms.status;
      final notificationStatus = await Permission.notification.status;

      print('📋 Current Permissions:');
      print('  📱 SMS: $smsStatus');
      print('  🔔 Notifications: $notificationStatus');
      print('  💾 Storage: Not Required'); // ✅ Remove storage checking

      // ✅ FIXED: Only check essential permissions
      final allPermissionsGranted = smsStatus.isGranted && notificationStatus.isGranted;

      if (allPermissionsGranted) {
        await SettingsService.instance.saveSetting('permissions_verified', true);
        print('✅ All essential permissions granted');
      } else {
        print('⚠️ Some permissions missing - user will see onboarding');
        await SettingsService.instance.saveSetting('permissions_verified', false);
      }

    } catch (e) {
      print('❌ Error checking permissions: $e');
    }
  }

  // ✅ PRODUCTION: Initialize notification service
  Future<void> _initializeNotificationService() async {
    try {
      await NotificationService.instance.init();
      _serviceStatus['notification'] = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      // Don't throw, continue with other services
    }
  }

  // ✅ PRODUCTION: Initialize category service
  Future<void> _initializeCategoryService() async {
    try {
      await CategoryService.instance.init();
      _serviceStatus['category'] = true;
      print('✅ Category service initialized');
    } catch (e) {
      print('❌ Error initializing category service: $e');
      throw e; // Categories are essential
    }
  }

  // ✅ PRODUCTION: Initialize SMS service
  Future<void> _initializeSmsService() async {
    try {
      await SmsService.instance.init();
      _serviceStatus['sms'] = true;
      print('✅ SMS service initialized');
    } catch (e) {
      print('❌ Error initializing SMS service: $e');
      throw e; // SMS is essential
    }
  }

  // ✅ PRODUCTION: Initialize sync service
  Future<void> _initializeSyncService() async {
    try {
      await SmsSyncService.instance.initialize();
      _serviceStatus['sync'] = true;
      print('✅ Sync service initialized');
    } catch (e) {
      print('❌ Error initializing sync service: $e');
      // Don't throw, sync is not critical for basic functionality
    }
  }

  // ✅ PRODUCTION: Enhanced data verification
  Future<void> _verifyAndRefreshData() async {
    try {
      // Check transaction count
      final transactionCount = await StorageService.instance.getTransactionCount();
      print('📊 Found $transactionCount transactions in storage');

      // Refresh SMS data if permissions available
      final smsPermissionGranted = await Permission.sms.isGranted;
      if (smsPermissionGranted && SmsService.instance.isInitialized) {
        print('📱 Refreshing SMS data...');
        await SmsService.instance.processHistoricalSms();

        final newCount = await StorageService.instance.getTransactionCount();
        print('📊 After refresh: $newCount transactions');
      }

      // ✅ FIXED: Robust integrity check
      await _performIntegrityCheck();

      print('✅ Data verification completed successfully');

    } catch (e) {
      print('❌ Error verifying data: $e');
      // Don't throw, continue with initialization
    }
  }

  // ✅ PRODUCTION: Robust integrity check (COMPLETELY FIXED)
  // ✅ PRODUCTION: Robust integrity check (COMPLETELY FIXED)
  Future<void> _performIntegrityCheck() async {
    try {
      print('🔍 Starting database integrity check...');
      final integrityResult = await StorageService.instance.checkIntegrity();

      // ✅ SAFE: Handle Map<String, bool>? return type properly
      bool isIntegrityOk = false;

      // integrityResult is Map<String, bool>?, so we check for null and extract boolean values
      if (integrityResult != null) {
        // Since integrityResult is Map<String, bool>, access values directly
        isIntegrityOk = (integrityResult['integrityOk'] == true) ||
            (integrityResult['integrity'] == true) ||
            (integrityResult['ok'] == true) ||
            (integrityResult['success'] == true);
      }

      if (isIntegrityOk) {
        print('✅ Database integrity check passed');
      } else {
        print('⚠️ Database integrity check failed');
        await _handleIntegrityFailure();
      }
    } catch (e) {
      print('❌ Error performing integrity check: $e');
    }
  }

  // ✅ PRODUCTION: Handle integrity failure
  Future<void> _handleIntegrityFailure() async {
    try {
      print('🔧 Attempting to repair database...');

      // Try to reinitialize storage service
      await StorageService.instance.init();

      // Log the repair attempt
      await SettingsService.instance.saveSetting('last_integrity_repair', DateTime.now().toIso8601String());

      print('✅ Database repair attempt completed');
    } catch (e) {
      print('❌ Error handling integrity failure: $e');
    }
  }

  // ✅ PRODUCTION: Enhanced health check
  Future<void> _verifyServicesHealth() async {
    try {
      print('🔍 Verifying services health...');

      // Check SMS service
      if (SmsService.instance.isInitialized) {
        final smsHealth = SmsService.instance.healthCheck;
        print('📱 SMS Service Health: ${smsHealth['overall_health'] ?? 'unknown'}');
      }

      // Check storage service
      if (StorageService.instance.isInitialized) {
        final storageInfo = await StorageService.instance.getStorageInfo();
        print('💾 Storage Service: Active with ${storageInfo['total_transactions'] ?? 0} transactions');
      }

      // Check settings service
      if (SettingsService.instance.isInitialized) {
        print('⚙️ Settings Service: Active');
      }

      print('✅ Services health check completed');
      print('📊 Service Status: $_serviceStatus');

    } catch (e) {
      print('❌ Service health check failed: $e');
      // Don't throw, this is just informational
    }
  }

  // ✅ PRODUCTION: Enhanced recovery mechanism
  Future<void> _attemptGracefulRecovery() async {
    try {
      print('🔄 Attempting graceful recovery...');

      // Ensure core services are working
      if (!SettingsService.instance.isInitialized) {
        await SettingsService.instance.init();
        _serviceStatus['settings'] = true;
      }

      if (!StorageService.instance.isInitialized) {
        await StorageService.instance.init();
        _serviceStatus['storage'] = true;
      }

      // Mark as initialized with limited functionality
      _servicesInitialized = true;
      await SettingsService.instance.saveSetting('recovery_mode', true);

      print('✅ Recovery successful - running in safe mode');

    } catch (e) {
      print('❌ Recovery failed: $e');
      _servicesInitialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPaisa - Enhanced SMS Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(),
      home: _buildHomeScreen(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/transactions': (_) => const TransactionsScreen(),
        '/categories': (_) => const CategoriesScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/debug': (_) => const DebugScreen(),
      },
      builder: (context, child) {
        ErrorWidget.builder = (details) => _buildEnhancedErrorWidget(details);
        return child!;
      },
    );
  }

  // ✅ PRODUCTION: Smart home screen selection
  Widget _buildHomeScreen() {
    if (_hasInitializationError) {
      return _buildInitializationErrorScreen();
    }

    if (!_servicesInitialized) {
      return _buildEnhancedLoadingScreen();
    }

    return _getInitialScreen();
  }

  // ✅ PRODUCTION: Initialization error screen
  Widget _buildInitializationErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 80,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Service Initialization Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'An unexpected error occurred during startup.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7CB9E8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasInitializationError = false;
                      _servicesInitialized = false;
                    });
                    _initializeAllServices();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Initialization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vibrantGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PRODUCTION: Smart theme mode detection
  ThemeMode _getThemeMode() {
    try {
      final settings = SettingsService.instance;
      if (!settings.isInitialized) return ThemeMode.dark;

      final mode = settings.getString('theme_mode', 'dark');
      switch (mode) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
        default:
          return ThemeMode.dark;
      }
    } catch (e) {
      return ThemeMode.dark;
    }
  }

  // ✅ PRODUCTION: Smart initial screen selection
  Widget _getInitialScreen() {
    try {
      final settings = SettingsService.instance;
      if (!settings.isInitialized) {
        return const DashboardScreen();
      }

      // ✅ FIXED: Comprehensive onboarding check
      final onboardingComplete = settings.getBool('onboarding_complete', false);
      final permissionsVerified = settings.getBool('permissions_verified', false);
      final isRecoveryMode = settings.getBool('recovery_mode', false);

      final needsOnboarding = !onboardingComplete || !permissionsVerified;

      print('🔍 Onboarding check: complete=$onboardingComplete, permissions=$permissionsVerified, recovery=$isRecoveryMode, needs=$needsOnboarding');

      if (isRecoveryMode) {
        // Clear recovery mode flag
        settings.saveSetting('recovery_mode', false);
      }

      return needsOnboarding ? const OnboardingScreen() : const DashboardScreen();
    } catch (e) {
      print('❌ Error determining initial screen: $e');
      return const DashboardScreen();
    }
  }

  // ✅ PRODUCTION: Enhanced loading screen
  Widget _buildEnhancedLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF162447),
              Color(0xFF1F4068),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Loading animation
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
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
              const SizedBox(height: 40),

              // ✅ App title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                ).createShader(bounds),
                child: const Text(
                  'SmartPaisa',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enhanced SMS Tracker',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7CB9E8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 50),

              // ✅ Progress indicator
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 30),

              // ✅ Status text
              Text(
                _initStatus,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7CB9E8),
                ),
              ),

              // ✅ Service status indicators
              if (_initializationInProgress) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _serviceStatus.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.value ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: entry.value ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.value ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: entry.value ? Colors.green : Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: entry.value ? Colors.green : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ PRODUCTION: Enhanced error widget
  Widget _buildEnhancedErrorWidget(FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFE74C3C),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Don\'t worry, your financial data is completely safe!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7CB9E8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _servicesInitialized = false;
                          _hasInitializationError = false;
                        });
                        _initializeAllServices();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vibrantGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    OutlinedButton.icon(
                      onPressed: SystemNavigator.pop,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
