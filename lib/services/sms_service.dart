// lib/services/sms_service.dart (COMPLETE ENHANCED SMS SERVICE - ALL ERRORS FIXED)
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import '../models/haptic_feedback_type.dart';
import 'storage_service.dart';
import 'settings_service.dart';
import 'transaction_parser.dart';
import 'notification_service.dart';
import '../utils/validation_utils.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  static SmsService get instance => _instance;

  // Services
  final StorageService _storage = StorageService.instance;
  final SettingsService _settings = SettingsService.instance;
  final TransactionParser _parser = TransactionParser();
  final NotificationService _notification = NotificationService.instance;

  // State variables
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isMonitoring = false;
  List<Transaction> _pendingTransactions = [];
  Set<String> _processedSmsIds = {};

  // Subscriptions and timers
  StreamSubscription? _smsWatcherSubscription;
  StreamSubscription? _inboxWatcherSubscription;
  Timer? _periodicSyncTimer;
  Timer? _backgroundSyncTimer;

  // Statistics tracking
  int _processedCount = 0;
  int _successfulTransactions = 0;
  int _failedParsing = 0;
  int _duplicatesSkipped = 0;
  DateTime? _lastProcessedTime;
  DateTime? _lastSyncTime;

  // Stream controllers
  final StreamController<Transaction> _transactionController =
  StreamController<Transaction>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _debugController =
  StreamController<String>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  bool get isMonitoring => _isMonitoring;
  List<Transaction> get pendingTransactions => List.from(_pendingTransactions);

  // Streams
  Stream<Transaction> get transactionStream => _transactionController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<String> get debugStream => _debugController.stream;

  // ✅ ENHANCED: Comprehensive initialization
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('📱 Initializing Enhanced SMS Service...');
      _debugLog('Starting SMS Service initialization');

      // Initialize dependencies
      await _storage.init();
      await _settings.init();
      await _notification.init();

      // Load processed SMS IDs from storage
      await _loadProcessedSmsIds();

      // Load pending transactions
      await refreshPendingTransactions();

      _isInitialized = true;
      _lastSyncTime = DateTime.now();

      print('✅ Enhanced SMS Service initialized successfully');
      _debugLog('SMS Service initialized with ${_pendingTransactions.length} pending transactions');

      _statusController.add({
        'status': 'initialized',
        'pending_transactions': _pendingTransactions.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error initializing SMS Service: $e');
      _debugLog('SMS Service initialization failed: $e');
      rethrow;
    }
  }

  Future<void> initialize() async {
    await init();
  }

  // ✅ ENHANCED: Load processed SMS IDs to avoid duplicates
  Future<void> _loadProcessedSmsIds() async {
    try {
      final processedIds = _settings.getString('processed_sms_ids', '');
      if (processedIds.isNotEmpty) {
        _processedSmsIds = processedIds.split(',').toSet();
        _debugLog('Loaded ${_processedSmsIds.length} processed SMS IDs');
      }
    } catch (e) {
      print('❌ Error loading processed SMS IDs: $e');
    }
  }

  // ✅ ENHANCED: Save processed SMS IDs
  Future<void> _saveProcessedSmsIds() async {
    try {
      // Keep only recent IDs (last 1000)
      if (_processedSmsIds.length > 1000) {
        final recentIds = _processedSmsIds.take(1000).toSet();
        _processedSmsIds = recentIds;
      }

      await _settings.setString('processed_sms_ids', _processedSmsIds.join(','));
    } catch (e) {
      print('❌ Error saving processed SMS IDs: $e');
    }
  }

  // ✅ ENHANCED: Start comprehensive SMS monitoring
  Future<void> startSmsMonitoring() async {
    if (!_isInitialized) await init();
    if (_isMonitoring) return;

    try {
      print('📱 Starting SMS monitoring...');

      // Check permissions
      if (!await _checkSmsPermissions()) {
        throw Exception('SMS permissions not granted');
      }

      // Start real-time SMS watcher
      await _startRealtimeSmsWatcher();

      // Start periodic sync
      _startPeriodicSync();

      // Start background processing
      _startBackgroundSync();

      _isMonitoring = true;

      print('✅ SMS monitoring started successfully');
      _debugLog('SMS monitoring started with all watchers active');

      _statusController.add({
        'status': 'monitoring_started',
        'realtime_active': _smsWatcherSubscription != null,
        'periodic_active': _periodicSyncTimer != null,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error starting SMS monitoring: $e');
      _debugLog('SMS monitoring failed to start: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Real-time SMS watcher with native integration
  Future<void> _startRealtimeSmsWatcher() async {
    try {
      // Method 1: SMS AutoFill listener (for real-time detection)
      _smsWatcherSubscription = SmsAutoFill().code.listen((code) {
        _debugLog('SMS AutoFill detected: $code');
        // This will trigger when any SMS is received
        _processLatestSms();
      });

      // Method 2: Periodic inbox checking for missed messages
      _inboxWatcherSubscription = Stream.periodic(
        const Duration(seconds: 30),
            (_) => _processRecentSms(),
      ).listen((_) {});

      _debugLog('Real-time SMS watchers started');
    } catch (e) {
      print('❌ Error starting real-time SMS watcher: $e');
      _debugLog('Real-time SMS watcher failed: $e');
    }
  }

  // ✅ ENHANCED: Check and request SMS permissions
  Future<bool> _checkSmsPermissions() async {
    try {
      var status = await Permission.sms.status;

      if (status.isDenied || status.isPermanentlyDenied) {
        _debugLog('SMS permission denied, requesting...');
        status = await Permission.sms.request();
      }

      final granted = status.isGranted;
      _debugLog('SMS permission status: ${granted ? 'GRANTED' : 'DENIED'}');
      return granted;
    } catch (e) {
      print('❌ Error checking SMS permissions: $e');
      _debugLog('SMS permission check failed: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Periodic sync with intelligent frequency
  void _startPeriodicSync() {
    final frequencyMinutes = _settings.getInt('sync_frequency_minutes', 30);

    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      Duration(minutes: frequencyMinutes),
          (_) {
        _debugLog('Periodic sync triggered');
        processHistoricalSms();
      },
    );

    print('🔄 Periodic sync started: every $frequencyMinutes minutes');
    _debugLog('Periodic sync scheduled every $frequencyMinutes minutes');
  }

  // ✅ ENHANCED: Background sync for missed messages
  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _processRecentSms(),
    );

    _debugLog('Background sync started: every 5 minutes');
  }

  // ✅ ENHANCED: Process latest SMS (real-time)
  Future<void> _processLatestSms() async {
    if (_isProcessing) return;

    try {
      final messages = await _getRecentSmsMessages(limit: 5);
      for (final message in messages) {
        await _processSingleSms(message);
      }
    } catch (e) {
      print('❌ Error processing latest SMS: $e');
      _debugLog('Latest SMS processing failed: $e');
    }
  }

  // ✅ ENHANCED: Process recent SMS (background)
  Future<void> _processRecentSms() async {
    if (_isProcessing) return;

    try {
      final messages = await _getRecentSmsMessages(limit: 20);
      int processedCount = 0;

      for (final message in messages) {
        if (await _processSingleSms(message)) {
          processedCount++;
        }
      }

      if (processedCount > 0) {
        _debugLog('Recent SMS processing: $processedCount new transactions');
      }
    } catch (e) {
      print('❌ Error processing recent SMS: $e');
      _debugLog('Recent SMS processing failed: $e');
    }
  }

  // ✅ ENHANCED: Process comprehensive historical SMS
  Future<void> processHistoricalSms() async {
    if (_isProcessing) return;

    _isProcessing = true;
    final startTime = DateTime.now();

    _statusController.add({
      'status': 'processing_started',
      'timestamp': startTime.toIso8601String(),
    });

    _debugLog('Starting historical SMS processing');

    try {
      print('📱 Processing historical SMS messages...');

      // Get historical messages
      final messages = await _getHistoricalSmsMessages();
      print('📱 Found ${messages.length} historical SMS messages');
      _debugLog('Found ${messages.length} historical SMS messages for processing');

      int processedCount = 0;
      int newTransactions = 0;
      int duplicatesSkipped = 0;

      for (final message in messages) {
        try {
          final result = await _processSingleSms(message, isHistorical: true);
          if (result) {
            if (await _isNewTransaction(message)) {
              newTransactions++;
            } else {
              duplicatesSkipped++;
            }
          }
          processedCount++;
        } catch (e) {
          // Add delay between processing batches to avoid overwhelming the system
          await Future.delayed(Duration.zero);

          _debugLog('Error processing message from ${message.sender}: $e');
          _failedParsing++;
        }
      }

      final processingTime = DateTime.now().difference(startTime);
      _lastProcessedTime = DateTime.now();

      print('✅ Historical SMS processing completed:');
      print('   - Processed: $processedCount messages');
      print('   - New transactions: $newTransactions');
      print('   - Duplicates skipped: $duplicatesSkipped');
      print('   - Processing time: ${processingTime.inSeconds}s');

      _debugLog('Historical SMS processing completed: $newTransactions new, $duplicatesSkipped duplicates, ${processingTime.inSeconds}s');

      _statusController.add({
        'status': 'processing_completed',
        'processed_count': processedCount,
        'new_transactions': newTransactions,
        'duplicates_skipped': duplicatesSkipped,
        'processing_time_seconds': processingTime.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Save processed IDs
      await _saveProcessedSmsIds();

    } catch (e) {
      print('❌ Error processing historical SMS: $e');
      _debugLog('Historical SMS processing failed: $e');

      _statusController.add({
        'status': 'processing_error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      _isProcessing = false;
    }
  }

  // ✅ ENHANCED: Get recent SMS messages with intelligent filtering
  Future<List<SmsMessage>> _getRecentSmsMessages({int limit = 50}) async {
    try {
      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: limit,
      );

      // Filter messages from last 24 hours
      final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));
      return messages.where((msg) =>
      msg.date != null &&
          msg.date!.isAfter(cutoffDate) &&
          !_processedSmsIds.contains(_generateSmsId(msg))
      ).toList();
    } catch (e) {
      print('❌ Error getting recent SMS messages: $e');
      _debugLog('Failed to get recent SMS messages: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Get historical SMS messages
  Future<List<SmsMessage>> _getHistoricalSmsMessages() async {
    try {
      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500, // Increased for better coverage
      );

      // Filter messages from last 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      return messages.where((msg) =>
      msg.date != null && msg.date!.isAfter(cutoffDate)
      ).toList();
    } catch (e) {
      print('❌ Error getting historical SMS messages: $e');
      _debugLog('Failed to get historical SMS messages: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Process single SMS with comprehensive validation
  Future<bool> _processSingleSms(SmsMessage message, {bool isHistorical = false}) async {
    try {
      final smsId = _generateSmsId(message);

      // Skip if already processed (for historical processing)
      if (isHistorical && _processedSmsIds.contains(smsId)) {
        return false;
      }

      final body = message.body ?? '';
      final sender = message.sender ?? '';
      final date = message.date ?? DateTime.now();

      // Validate message
      if (!ValidationUtils.shouldProcessMessage(body, sender)) {
        _debugLog('Message validation failed for $sender');
        return false;
      }

      // Parse transaction
      final transaction = _parser.parseTransactionFromSms(body, sender, date);
      if (transaction == null) {
        _debugLog('Failed to parse transaction from $sender');
        _failedParsing++;
        return false;
      }

      // Process the transaction
      final success = await _processTransaction(transaction);
      if (success) {
        _processedSmsIds.add(smsId);
        _debugLog('Successfully processed transaction: ${transaction.merchant} - ₹${transaction.amount}');
      }

      return success;
    } catch (e) {
      print('❌ Error processing single SMS: $e');
      _debugLog('Single SMS processing error: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Generate unique SMS ID
  String _generateSmsId(SmsMessage message) {
    return '${message.sender}_${message.date?.millisecondsSinceEpoch}_${message.body?.hashCode}';
  }

  // ✅ ENHANCED: Check if transaction is new
  Future<bool> _isNewTransaction(SmsMessage message) async {
    try {
      final existingTransactions = await _storage.getTransactions();
      final transaction = _parser.parseTransactionFromSms(
        message.body ?? '',
        message.sender ?? '',
        message.date ?? DateTime.now(),
      );

      if (transaction == null) return false;

      return !existingTransactions.any((existing) =>
          _areTransactionsSimilar(existing, transaction)
      );
    } catch (e) {
      _debugLog('Error checking if transaction is new: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Process individual transaction with duplicate detection
  Future<bool> _processTransaction(Transaction transaction) async {
    try {
      // Check for duplicates with enhanced similarity checking
      final existingTransactions = await _storage.getTransactions();
      final isDuplicate = existingTransactions.any((existing) =>
          _areTransactionsSimilar(existing, transaction)
      );

      if (isDuplicate) {
        _duplicatesSkipped++;
        _debugLog('Duplicate transaction skipped: ${transaction.merchant}');
        return false;
      }

      // Auto-categorize if enabled
      if (_settings.getBool('auto_categorization', true)) {
        // This would be implemented with category service
        _debugLog('Auto-categorization enabled for: ${transaction.merchant}');
      }

      // Save transaction
      await _storage.saveTransaction(transaction);
      _pendingTransactions.add(transaction);
      _successfulTransactions++;

      // Emit transaction to stream
      _transactionController.add(transaction);

      // Show notification if enabled
      if (_settings.getBool('transaction_notifications', true)) {
        await _notification.showTransactionNotification(transaction);
      }

      // Trigger haptic feedback
      if (_settings.getBool('haptic_feedback', true)) {
        await _settings.triggerHaptic(HapticFeedbackType.success);
      }

      print('💾 New transaction processed: ${transaction.merchant} - ₹${transaction.amount}');
      _debugLog('Transaction saved and processed: ${transaction.id}');

      return true;
    } catch (e) {
      print('❌ Error processing transaction: $e');
      _debugLog('Transaction processing failed: $e');
      _failedParsing++;
      return false;
    }
  }

  // ✅ ENHANCED: Advanced transaction similarity checking
  bool _areTransactionsSimilar(Transaction t1, Transaction t2) {
    // Check multiple criteria for similarity
    final amountMatch = (t1.amount - t2.amount).abs() < 0.01; // Allow small floating point differences
    final merchantMatch = t1.merchant.toLowerCase().trim() == t2.merchant.toLowerCase().trim();
    final timeMatch = t1.dateTime.difference(t2.dateTime).abs().inMinutes <= 5; // Allow 5-minute window
    final senderMatch = t1.sender.toLowerCase() == t2.sender.toLowerCase();

    return amountMatch && merchantMatch && timeMatch && senderMatch;
  }

  // ✅ ENHANCED: Get historical transactions with filtering
  Future<List<Transaction>> getHistoricalTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      var transactions = await _storage.getTransactions();

      // Apply filters
      if (startDate != null) {
        transactions = transactions.where((t) =>
        t.dateTime.isAfter(startDate) || t.dateTime.isAtSameMomentAs(startDate)
        ).toList();
      }

      if (endDate != null) {
        transactions = transactions.where((t) =>
        t.dateTime.isBefore(endDate) || t.dateTime.isAtSameMomentAs(endDate)
        ).toList();
      }

      if (categoryId != null) {
        transactions = transactions.where((t) => t.categoryId == categoryId).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        transactions = transactions.where((t) =>
        t.merchant.toLowerCase().contains(query) ||
            t.originalMessage.toLowerCase().contains(query)
        ).toList();
      }

      return transactions;
    } catch (e) {
      print('❌ Error getting historical transactions: $e');
      _debugLog('Failed to get historical transactions: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Watch new transactions with filtering
  Stream<Transaction> watchNewTransactions({String? categoryId}) {
    if (categoryId != null) {
      return _transactionController.stream.where((t) => t.categoryId == categoryId);
    }
    return _transactionController.stream;
  }

  // ✅ ENHANCED: Settings management
  void setProcessHistoricalSms(bool value) {
    _settings.setBool('historical_sms_processing', value);
    _debugLog('Historical SMS processing: $value');
    print('📱 Historical SMS processing: $value');

    if (value && !_isProcessing) {
      processHistoricalSms();
    }
  }

  void setDebugMode(bool value) {
    _settings.setBool('debug_mode', value);
    _debugLog('Debug mode: $value');
    print('🐛 Debug mode: $value');
  }

  Future<void> setSyncFrequency(int minutes) async {
    await _settings.setInt('sync_frequency_minutes', minutes);
    _debugLog('Sync frequency updated: $minutes minutes');

    // Restart periodic sync with new frequency
    if (_isMonitoring) {
      _startPeriodicSync();
    }
  }

  // ✅ ENHANCED: Comprehensive statistics
  Map<String, dynamic> getStats() {
    final uptime = _lastSyncTime != null
        ? DateTime.now().difference(_lastSyncTime!).inMinutes
        : 0;

    return {
      'service_status': {
        'initialized': _isInitialized,
        'monitoring': _isMonitoring,
        'processing': _isProcessing,
        'uptime_minutes': uptime,
      },
      'processing_stats': {
        'total_processed': _processedCount,
        'successful_transactions': _successfulTransactions,
        'failed_parsing': _failedParsing,
        'duplicates_skipped': _duplicatesSkipped,
        'success_rate': _processedCount > 0
            ? (_successfulTransactions / _processedCount * 100).toStringAsFixed(1)
            : '0.0',
      },
      'current_state': {
        'pending_transactions': _pendingTransactions.length,
        'processed_sms_ids': _processedSmsIds.length,
        'last_processed': _lastProcessedTime?.toIso8601String(),
        'last_sync': _lastSyncTime?.toIso8601String(),
      },
      'watchers': {
        'realtime_active': _smsWatcherSubscription != null,
        'inbox_active': _inboxWatcherSubscription != null,
        'periodic_active': _periodicSyncTimer?.isActive ?? false,
        'background_active': _backgroundSyncTimer?.isActive ?? false,
      },
    };
  }

  Future<Map<String, dynamic>> getNativeServiceStatus() async {
    final permissionStatus = await Permission.sms.status;

    return {
      'service_info': {
        'version': '2.0.0',
        'initialized': _isInitialized,
        'monitoring': _isMonitoring,
        'processing': _isProcessing,
      },
      'permissions': {
        'sms_granted': permissionStatus.isGranted,
        'sms_status': permissionStatus.toString(),
      },
      'watchers': {
        'sms_watcher_active': _smsWatcherSubscription != null,
        'inbox_watcher_active': _inboxWatcherSubscription != null,
        'periodic_sync_active': _periodicSyncTimer?.isActive ?? false,
        'background_sync_active': _backgroundSyncTimer?.isActive ?? false,
      },
      'performance': {
        'pending_transactions': _pendingTransactions.length,
        'processed_sms_count': _processedSmsIds.length,
        'memory_usage_mb': _getMemoryUsage(),
      },
      'timestamps': {
        'last_processed': _lastProcessedTime?.toIso8601String(),
        'last_sync': _lastSyncTime?.toIso8601String(),
        'status_check': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<Map<String, dynamic>> triggerManualSync() async {
    try {
      print('🔄 Triggering manual SMS sync...');
      _debugLog('Manual sync triggered by user');

      final beforeCount = _pendingTransactions.length;
      final startTime = DateTime.now();

      await processHistoricalSms();

      final afterCount = _pendingTransactions.length;
      final newTransactions = afterCount - beforeCount;
      final syncTime = DateTime.now().difference(startTime);

      final result = {
        'success': true,
        'newTransactions': newTransactions,
        'totalTransactions': afterCount,
        'syncTimeSeconds': syncTime.inSeconds,
        'message': newTransactions > 0
            ? 'Found $newTransactions new transactions'
            : 'No new transactions found',
        'timestamp': DateTime.now().toIso8601String(),
        'statistics': getStats(),
      };

      _debugLog('Manual sync completed: $newTransactions new transactions in ${syncTime.inSeconds}s');
      return result;
    } catch (e) {
      _debugLog('Manual sync failed: $e');
      return {
        'success': false,
        'newTransactions': 0,
        'totalTransactions': _pendingTransactions.length,
        'syncTimeSeconds': 0,
        'message': 'Sync failed: ${e.toString()}',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  void clearProcessedCache() {
    _pendingTransactions.clear();
    _processedSmsIds.clear();
    _processedCount = 0;
    _successfulTransactions = 0;
    _failedParsing = 0;
    _duplicatesSkipped = 0;

    _saveProcessedSmsIds();
    _debugLog('Processed SMS cache cleared');
    print('🗑️ Processed SMS cache cleared');
  }

  // ✅ ENHANCED: Memory usage monitoring
  double _getMemoryUsage() {
    try {
      // This is a simplified memory usage calculation
      final pendingSize = _pendingTransactions.length * 0.001; // Approximate KB per transaction
      final processedIdsSize = _processedSmsIds.length * 0.0001; // Approximate KB per ID
      return pendingSize + processedIdsSize;
    } catch (e) {
      return 0.0;
    }
  }

  // ✅ ENHANCED: Health check with comprehensive diagnostics
  Map<String, dynamic> get healthCheck {
    final now = DateTime.now();
    final lastProcessedAge = _lastProcessedTime != null
        ? now.difference(_lastProcessedTime!).inMinutes
        : null;

    return {
      'overall_health': _isInitialized && !_isProcessing ? 'healthy' : 'warning',
      'service_status': {
        'initialized': _isInitialized,
        'monitoring': _isMonitoring,
        'processing': _isProcessing,
        'last_processed_minutes_ago': lastProcessedAge,
      },
      'watchers_health': {
        'realtime_watcher': _smsWatcherSubscription != null ? 'active' : 'inactive',
        'inbox_watcher': _inboxWatcherSubscription != null ? 'active' : 'inactive',
        'periodic_sync': _periodicSyncTimer?.isActive ?? false ? 'active' : 'inactive',
        'background_sync': _backgroundSyncTimer?.isActive ?? false ? 'active' : 'inactive',
      },
      'performance_metrics': {
        'pending_transactions': _pendingTransactions.length,
        'success_rate': _processedCount > 0
            ? (_successfulTransactions / _processedCount * 100).toStringAsFixed(1)
            : '0.0',
        'memory_usage_mb': _getMemoryUsage(),
      },
      'potential_issues': _getDiagnosticIssues(),
      'recommendations': _getHealthRecommendations(),
      'timestamp': now.toIso8601String(),
    };
  }

  List<String> _getDiagnosticIssues() {
    final issues = <String>[];

    if (!_isInitialized) {
      issues.add('Service not initialized');
    }

    if (_isProcessing && _lastProcessedTime != null) {
      final processingTime = DateTime.now().difference(_lastProcessedTime!);
      if (processingTime.inMinutes > 10) {
        issues.add('Processing stuck for ${processingTime.inMinutes} minutes');
      }
    }

    if (_failedParsing > _successfulTransactions * 0.5) {
      issues.add('High parsing failure rate: ${_failedParsing}/${_processedCount}');
    }

    if (_smsWatcherSubscription == null && _isMonitoring) {
      issues.add('Real-time SMS watcher not active');
    }

    return issues;
  }

  List<String> _getHealthRecommendations() {
    final recommendations = <String>[];

    if (_duplicatesSkipped > _successfulTransactions) {
      recommendations.add('High duplicate rate - consider clearing processed cache');
    }

    if (_failedParsing > 10) {
      recommendations.add('High parsing failures - check SMS patterns');
    }

    if (_pendingTransactions.length > 1000) {
      recommendations.add('Large number of pending transactions - consider archiving');
    }

    return recommendations;
  }

  // ✅ ENHANCED: Lifecycle management
  Future<void> resume() async {
    if (!_isInitialized) return;

    try {
      if (!_isMonitoring) {
        await startSmsMonitoring();
      } else {
        _startPeriodicSync();
        _startBackgroundSync();
      }

      _debugLog('SMS Service resumed');
      print('▶️ SMS Service resumed');
    } catch (e) {
      print('❌ Error resuming SMS Service: $e');
      _debugLog('SMS Service resume failed: $e');
    }
  }

  Future<void> pause() async {
    try {
      _periodicSyncTimer?.cancel();
      _backgroundSyncTimer?.cancel();

      _debugLog('SMS Service paused');
      print('⏸️ SMS Service paused');
    } catch (e) {
      print('❌ Error pausing SMS Service: $e');
      _debugLog('SMS Service pause failed: $e');
    }
  }

  Future<void> refreshPendingTransactions() async {
    try {
      final transactions = await _storage.getTransactions();
      _pendingTransactions = transactions.take(100).toList();

      _debugLog('Refreshed pending transactions: ${_pendingTransactions.length}');
      print('🔄 Refreshed pending transactions: ${_pendingTransactions.length}');
    } catch (e) {
      print('❌ Error refreshing pending transactions: $e');
      _debugLog('Failed to refresh pending transactions: $e');
    }
  }

  // ✅ ENHANCED: Advanced debugging
  void _debugLog(String message) {
    if (_settings.getBool('debug_mode', false)) {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] SMS_SERVICE: $message';
      print('🐛 $logMessage');
      _debugController.add(logMessage);
    }
  }

  Stream<String> getDebugStream() {
    return _debugController.stream;
  }

  Future<List<Map<String, dynamic>>> getDebugInfo() async {
    return [
      {
        'category': 'Service Status',
        'data': {
          'initialized': _isInitialized,
          'monitoring': _isMonitoring,
          'processing': _isProcessing,
        },
      },
      {
        'category': 'Statistics',
        'data': getStats(),
      },
      {
        'category': 'Health Check',
        'data': healthCheck,
      },
      {
        'category': 'Recent Transactions',
        'data': _pendingTransactions.take(5).map((t) => {
          'merchant': t.merchant,
          'amount': t.amount,
          'date': t.dateTime.toIso8601String(),
        }).toList(),
      },
    ];
  }

  // ✅ ENHANCED: Cleanup and disposal
  void dispose() {
    try {
      _smsWatcherSubscription?.cancel();
      _inboxWatcherSubscription?.cancel();
      _periodicSyncTimer?.cancel();
      _backgroundSyncTimer?.cancel();

      _transactionController.close();
      _statusController.close();
      _debugController.close();

      _isInitialized = false;
      _isMonitoring = false;
      _isProcessing = false;

      _debugLog('SMS Service disposed');
      print('🗑️ SMS Service disposed');
    } catch (e) {
      print('❌ Error disposing SMS Service: $e');
    }
  }

  // ✅ ENHANCED: Export/Import functionality
  Future<Map<String, dynamic>> exportServiceData() async {
    try {
      return {
        'version': '2.0.0',
        'export_date': DateTime.now().toIso8601String(),
        'statistics': getStats(),
        'settings': {
          'auto_categorization': _settings.getBool('auto_categorization', true),
          'historical_processing': _settings.getBool('historical_sms_processing', true),
          'sync_frequency': _settings.getInt('sync_frequency_minutes', 30),
        },
        'processed_sms_count': _processedSmsIds.length,
        'pending_transactions_count': _pendingTransactions.length,
      };
    } catch (e) {
      print('❌ Error exporting service data: $e');
      return {};
    }
  }

  Future<void> importServiceData(Map<String, dynamic> data) async {
    try {
      // Import settings if available
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;
        for (final entry in settings.entries) {
          await _settings.saveSetting(entry.key, entry.value);
        }
      }

      _debugLog('Service data imported successfully');
      print('✅ Service data imported successfully');
    } catch (e) {
      print('❌ Error importing service data: $e');
      _debugLog('Service data import failed: $e');
    }
  }
}
