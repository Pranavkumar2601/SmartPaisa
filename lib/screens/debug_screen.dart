// lib/screens/debug_screen.dart (NEW FILE - COMPLETE IMPLEMENTATION)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sms_service.dart';
import '../services/sms_sync_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_parser.dart';
import '../utils/validation_utils.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];
  bool _isLoading = false;
  Map<String, dynamic>? _serviceStatus;
  Map<String, dynamic>? _syncStatus;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Debug Console'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Cards
          if (_serviceStatus != null) _buildStatusCards(),

          // Action Buttons
          _buildActionButtons(),

          // Logs Section
          Expanded(
            child: _buildLogsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatusCard('SMS Service', _serviceStatus!['smsService'] ?? {})),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusCard('Sync Service', _serviceStatus!['syncService'] ?? {})),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatusCard('Native Status', _serviceStatus!['nativeStatus'] ?? {})),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusCard('Database', _serviceStatus!['database'] ?? {})),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, Map<String, dynamic> status) {
    final isHealthy = status['healthy'] ?? false;

    return Card(
      color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status['message'] ?? 'No status',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionButton('🔄 Manual Sync', _triggerManualSync),
          _buildActionButton('📱 Test SMS', _testSmsProcessing),
          _buildActionButton('🔔 Test Notification', _testNotification),
          _buildActionButton('📊 Show Stats', _showStats),
          _buildActionButton('🧹 Clear Cache', _clearCache),
          _buildActionButton('🔬 Sync Test', _performSyncTest),
          _buildActionButton('⚡ Force Sync', _forceSync),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(text),
    );
  }

  Widget _buildLogsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Icon(Icons.terminal, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Debug Logs',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🔄 Refreshing service status...');

      // Get comprehensive status
      final smsStats = SmsService.instance.getStats();
      final syncStatus = SmsSyncService.instance.getSyncStatus();
      final nativeStatus = await SmsService.instance.getNativeServiceStatus();
      final transactionCount = (await StorageService.instance.getTransactions()).length;

      setState(() {
        _serviceStatus = {
          'smsService': {
            'healthy': smsStats['isInitialized'] == true,
            'message': 'Processed: ${smsStats['processedTransactions']} txns',
          },
          'syncService': {
            'healthy': syncStatus['isInitialized'] == true,
            'message': 'Last sync: ${syncStatus['lastSync'] ?? 'Never'}',
          },
          'nativeStatus': {
            'healthy': nativeStatus['backgroundServiceRunning'] == true,
            'message': 'WorkManager: ${nativeStatus['workManagerScheduled'] == true ? 'Running' : 'Stopped'}',
          },
          'database': {
            'healthy': transactionCount >= 0,
            'message': '$transactionCount transactions stored',
          },
        };
      });

      _addLog('✅ Status refreshed successfully');

    } catch (e) {
      _addLog('❌ Error refreshing status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🔄 Triggering enhanced manual sync...');

      final result = await SmsService.instance.triggerManualSync();

      _addLog('✅ Manual sync completed:');
      _addLog('   - Success: ${result['success']}');
      _addLog('   - New transactions: ${result['newTransactions']}');
      _addLog('   - Duplicates skipped: ${result['duplicatesSkipped'] ?? 0}');
      _addLog('   - Message: ${result['message']}');

      await _refreshStatus();

    } catch (e) {
      _addLog('❌ Manual sync failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSmsProcessing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🧪 Testing SMS processing...');

      // Test transaction parser
      final parser = TransactionParser();
      parser.debugTestParsing();

      _addLog('✅ SMS processing test completed');

    } catch (e) {
      _addLog('❌ SMS processing test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotification() async {
    try {
      _addLog('🔔 Testing notification...');

      await NotificationService.instance.showTestNotification();

      _addLog('✅ Test notification sent');

    } catch (e) {
      _addLog('❌ Notification test failed: $e');
    }
  }

  void _showStats() {
    try {
      _addLog('📊 Showing comprehensive stats...');

      final smsStats = SmsService.instance.getStats();
      final syncStats = SmsSyncService.instance.getSyncStatistics();

      _addLog('=== SMS SERVICE STATS ===');
      smsStats.forEach((key, value) {
        _addLog('   $key: $value');
      });

      _addLog('=== SYNC SERVICE STATS ===');
      syncStats.forEach((key, value) {
        _addLog('   $key: $value');
      });

    } catch (e) {
      _addLog('❌ Error showing stats: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      _addLog('🧹 Clearing SMS processing cache...');

      SmsService.instance.clearProcessedCache();
      await SmsSyncService.instance.clearSyncData();

      _addLog('✅ Cache cleared successfully');
      await _refreshStatus();

    } catch (e) {
      _addLog('❌ Error clearing cache: $e');
    }
  }

  // lib/screens/debug_screen.dart (FIX THE SYNC RESULT HANDLING)

  Future<void> _performSyncTest() async {
    try {
      _addLog('🔄 Starting sync test...');

      // Trigger manual sync
      final result = await SmsSyncService.instance.forceSync();

      // ✅ FIXED: Access Map properties correctly
      _addLog('📊 Sync Results:');
      _addLog('   - Success: ${result['success'] ?? false}');
      _addLog('   - New transactions: ${result['newTransactions'] ?? 0}');

      // Handle optional properties safely
      if (result.containsKey('duplicatesSkipped')) {
        _addLog('   - Duplicates skipped: ${result['duplicatesSkipped']}');
      }

      _addLog('   - Message: ${result['message'] ?? 'No message'}');

      if (result.containsKey('syncTimeSeconds')) {
        _addLog('   - Sync time: ${result['syncTimeSeconds']}s');
      }

      if (result.containsKey('totalTransactions')) {
        _addLog('   - Total transactions: ${result['totalTransactions']}');
      }

      if (result['success'] == true) {
        _addLog('✅ Sync test completed successfully');
      } else {
        _addLog('❌ Sync test failed');
        if (result.containsKey('error')) {
          _addLog('   Error details: ${result['error']}');
        }
      }

    } catch (e) {
      _addLog('❌ Sync test error: $e');
    }
  }

  Future<void> _forceSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('⚡ Forcing immediate sync (bypassing rate limits)...');

      final result = await SmsSyncService.instance.forceSync();

      _addLog('✅ Force sync completed:');
      _addLog('   - Success: ${result['success']}');
      _addLog('   - New transactions: ${result['newTransactions']}');
      _addLog('   - Message: ${result['message']}');

      await _refreshStatus();

    } catch (e) {
      _addLog('❌ Force sync failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
