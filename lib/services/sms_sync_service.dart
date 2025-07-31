// lib/services/sms_sync_service.dart (COMPLETE ENHANCED VERSION)
import 'dart:async';
import 'sms_service.dart';
import 'storage_service.dart';
import 'settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsSyncResult {
  final bool success;
  final int newTransactions;
  final String message;
  final DateTime timestamp;

  SmsSyncResult({
    required this.success,
    required this.newTransactions,
    required this.message,
  }) : timestamp = DateTime.now();
}

class SmsSyncService {
  static final SmsSyncService _instance = SmsSyncService._internal();

  factory SmsSyncService() => _instance;

  SmsSyncService._internal();

  static SmsSyncService get instance => _instance;

  final SmsService _smsService = SmsService.instance;
  final StorageService _storage = StorageService.instance;
  final SettingsService _settings = SettingsService.instance;

  // Enhanced state variables
  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _processedSmsCount = 0;
  DateTime? _installDate;
  int _totalSyncs = 0;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Initializing SMS Sync Service...');

      // Load sync data from SharedPreferences
      await _loadSyncData();

      _isInitialized = true;
      print('✅ SMS Sync Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing SMS Sync Service: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Load sync data from persistent storage
  Future<void> _loadSyncData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load last sync time
      final lastSyncString = _settings.getString('last_manual_sync_time', '');
      if (lastSyncString.isNotEmpty) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }

      // Load processed SMS count
      _processedSmsCount = prefs.getInt('processed_sms_count') ?? 0;

      // Load or set install date
      final installTimestamp = prefs.getInt('app_install_date');
      if (installTimestamp == null) {
        _installDate = DateTime.now();
        await prefs.setInt('app_install_date', _installDate!.millisecondsSinceEpoch);
      } else {
        _installDate = DateTime.fromMillisecondsSinceEpoch(installTimestamp);
      }

      // Load sync statistics
      _totalSyncs = prefs.getInt('total_syncs') ?? 0;
      _successfulSyncs = prefs.getInt('successful_syncs') ?? 0;
      _failedSyncs = prefs.getInt('failed_syncs') ?? 0;

      print('📊 Sync data loaded: $_processedSmsCount SMS processed, $_totalSyncs total syncs');
    } catch (e) {
      print('❌ Error loading sync data: $e');
    }
  }

  // ✅ ENHANCED: Save sync data to persistent storage
  Future<void> _saveSyncData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_lastSyncTime != null) {
        await _settings.saveSetting('last_manual_sync_time', _lastSyncTime!.toIso8601String());
      }

      await prefs.setInt('processed_sms_count', _processedSmsCount);
      await prefs.setInt('total_syncs', _totalSyncs);
      await prefs.setInt('successful_syncs', _successfulSyncs);
      await prefs.setInt('failed_syncs', _failedSyncs);

      print('💾 Sync data saved successfully');
    } catch (e) {
      print('❌ Error saving sync data: $e');
    }
  }

  Future<SmsSyncResult> triggerManualSync() async {
    if (_isSyncing) {
      return SmsSyncResult(
        success: false,
        newTransactions: 0,
        message: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _totalSyncs++;

    try {
      print('🔄 Starting manual SMS sync...');

      // Get transaction count before sync
      final beforeCount = await _storage.getTransactionCount();

      // Trigger SMS processing
      await _smsService.processHistoricalSms();

      // Wait a bit for processing to complete
      await Future.delayed(const Duration(seconds: 2));

      // Get transaction count after sync
      final afterCount = await _storage.getTransactionCount();
      final newTransactions = afterCount - beforeCount;

      // Update sync data
      _lastSyncTime = DateTime.now();
      _processedSmsCount += newTransactions;
      _successfulSyncs++;

      // Save sync data
      await _saveSyncData();

      print('✅ Manual sync completed: $newTransactions new transactions');

      return SmsSyncResult(
        success: true,
        newTransactions: newTransactions,
        message: newTransactions > 0
            ? 'Found $newTransactions new transactions'
            : 'No new transactions found',
      );
    } catch (e) {
      print('❌ Error in manual sync: $e');
      _failedSyncs++;
      await _saveSyncData();

      return SmsSyncResult(
        success: false,
        newTransactions: 0,
        message: 'Sync failed: ${e.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ✅ UPDATED: Enhanced getSyncStatus for SettingsScreen UI
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_syncing': _isSyncing,
      'lastSync': _lastSyncTime, // DateTime object for UI calculations
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'is_initialized': _isInitialized,
      'processedCount': _processedSmsCount,
      'installDate': _installDate ?? DateTime.now(),
    };
  }

  Map<String, dynamic> getSyncStatistics() {
    return {
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'is_syncing': _isSyncing,
      'total_syncs': _totalSyncs,
      'successful_syncs': _successfulSyncs,
      'failed_syncs': _failedSyncs,
      'processed_count': _processedSmsCount,
      'install_date': _installDate?.toIso8601String(),
    };
  }

  Future<void> clearSyncData() async {
    _lastSyncTime = null;
    _processedSmsCount = 0;
    _totalSyncs = 0;
    _successfulSyncs = 0;
    _failedSyncs = 0;

    await _settings.saveSetting('last_manual_sync_time', '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('processed_sms_count');
    await prefs.remove('total_syncs');
    await prefs.remove('successful_syncs');
    await prefs.remove('failed_syncs');

    print('🗑️ Sync data cleared');
  }

  Future<Map<String, dynamic>> forceSync() async {
    try {
      final startTime = DateTime.now();
      final result = await triggerManualSync();
      final endTime = DateTime.now();
      final syncDuration = endTime.difference(startTime).inSeconds;

      return {
        'success': result.success,
        'newTransactions': result.newTransactions,
        'message': result.message,
        'timestamp': result.timestamp.toIso8601String(),
        'duplicatesSkipped': 0, // Implement if you track duplicates
        'syncTimeSeconds': syncDuration,
        'totalTransactions': result.newTransactions,
      };
    } catch (e) {
      return {
        'success': false,
        'newTransactions': 0,
        'message': 'Force sync failed: ${e.toString()}',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // ✅ ENHANCED: Reset sync status for clear data functionality
  Future<void> resetSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove SharedPreferences entries
      await prefs.remove('last_sync_timestamp');
      await prefs.remove('processed_sms_count');
      await prefs.remove('app_install_date');
      await prefs.remove('total_syncs');
      await prefs.remove('successful_syncs');
      await prefs.remove('failed_syncs');

      // Clear settings
      await _settings.saveSetting('last_manual_sync_time', '');

      // Reset local variables
      _lastSyncTime = null;
      _processedSmsCount = 0;
      _installDate = null;
      _totalSyncs = 0;
      _successfulSyncs = 0;
      _failedSyncs = 0;

      print('✅ Sync status reset completely');
    } catch (e) {
      print('❌ Error resetting sync status: $e');
      throw Exception('Failed to reset sync status: $e');
    }
  }

  // ✅ NEW: Get formatted sync status for UI display
  String getFormattedSyncStatus() {
    if (_lastSyncTime == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) return 'Synced just now';
    if (difference.inHours < 1) return 'Synced ${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return 'Synced ${difference.inHours} hours ago';
    return 'Synced ${difference.inDays} days ago';
  }

  // ✅ NEW: Check if sync is needed
  bool shouldSync() {
    if (_lastSyncTime == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    // Suggest sync if last sync was more than 1 hour ago
    return difference.inHours >= 1;
  }

  // ✅ NEW: Get sync health status
  Map<String, dynamic> getSyncHealth() {
    final successRate = _totalSyncs > 0
        ? (_successfulSyncs / _totalSyncs * 100).round()
        : 100;

    return {
      'health_status': successRate >= 80 ? 'healthy' : successRate >= 50 ? 'warning' : 'critical',
      'success_rate': successRate,
      'total_syncs': _totalSyncs,
      'last_sync_age_hours': _lastSyncTime != null
          ? DateTime.now().difference(_lastSyncTime!).inHours
          : null,
      'needs_sync': shouldSync(),
    };
  }
}
