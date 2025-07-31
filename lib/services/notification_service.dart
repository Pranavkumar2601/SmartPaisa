// lib/services/notification_service.dart (COMPLETE ENHANCED VERSION)
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/transaction.dart';
import '../models/haptic_feedback_type.dart';
import 'settings_service.dart';
import 'package:flutter/material.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final SettingsService _settings = SettingsService.instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initializing Notification Service...');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;
      print('✅ Notification Service initialized successfully');

    } catch (e) {
      print('❌ Error initializing Notification Service: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel transactionChannel = AndroidNotificationChannel(
      'transaction_channel',
      'Transaction Notifications',
      description: 'Notifications for new transactions',
      importance: Importance.high,
    );

    const AndroidNotificationChannel summaryChannel = AndroidNotificationChannel(
      'summary_channel',
      'Summary Notifications',
      description: 'Daily and weekly spending summaries',
      importance: Importance.defaultImportance,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(transactionChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(summaryChannel);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('🔔 Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap - could navigate to specific screens
  }

  Future<void> showTransactionNotification(Transaction transaction) async {
    if (!_isInitialized) return;
    if (!_settings.getBool('transaction_notifications', true)) return;

    try {
      final String title = transaction.type == TransactionType.debit
          ? '💸 Money Spent'
          : '💰 Money Received';

      final String body = '₹${transaction.amount.toStringAsFixed(0)} ${transaction.type == TransactionType.debit ? 'paid to' : 'received from'} ${transaction.merchant}';

      await _flutterLocalNotificationsPlugin.show(
        transaction.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'transaction_channel',
            'Transaction Notifications',
            channelDescription: 'Notifications for new transactions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: transaction.type == TransactionType.debit
                ? const Color(0xFFE53935)
                : const Color(0xFF4CAF50),
          ),
        ),
        payload: 'transaction:${transaction.id}',
      );

      // Trigger haptic feedback
      if (_settings.getBool('haptic_feedback', true)) {
        _settings.triggerHaptic(HapticFeedbackType.success);
      }

    } catch (e) {
      print('❌ Error showing transaction notification: $e');
    }
  }

  Future<void> showDailySummaryNotification(double totalSpent, int transactionCount) async {
    if (!_isInitialized) return;
    if (!_settings.getBool('summary_notifications', true)) return;

    try {
      const String title = '📊 Daily Spending Summary';
      final String body = 'You spent ₹${totalSpent.toStringAsFixed(0)} across $transactionCount transactions today';

      await _flutterLocalNotificationsPlugin.show(
        'daily_summary'.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'summary_channel',
            'Summary Notifications',
            channelDescription: 'Daily and weekly spending summaries',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3),
          ),
        ),
        payload: 'summary:daily',
      );

    } catch (e) {
      print('❌ Error showing daily summary notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('❌ Error canceling notifications: $e');
    }
  }

  // Add this method to your existing NotificationService class:
  Future<void> showTestNotification() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.show(
        999,
        '🧪 Test Notification',
        'This is a test notification from SmartPaisa app',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel', // Ensure this channel is created or use an existing one
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: 'test_notification',
      );

      print('🔔 Test notification sent successfully');
    } catch (e) {
      print('❌ Error showing test notification: $e');
    }
  }
}
