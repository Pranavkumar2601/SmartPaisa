// lib/services/settings_service.dart (COMPLETE ENHANCED VERSION - ALL ERRORS FIXED)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/haptic_feedback_type.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static SettingsService get instance => _instance;


  SharedPreferences? _prefs;
  bool _isInitialized = false;
  final StreamController<Map<String, dynamic>> _settingsController =
  StreamController<Map<String, dynamic>>.broadcast();

  bool get isInitialized => _isInitialized;
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  // ✅ ENHANCED: Initialize with comprehensive error handling
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('⚙️ Initializing Enhanced Settings Service...');
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      // Initialize default settings if they don't exist
      await _initializeDefaultSettings();

      print('✅ Enhanced Settings Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing settings service: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Initialize default settings
  Future<void> _initializeDefaultSettings() async {
    final defaultSettings = {
      'theme_mode': 'dark',
      'haptic_feedback': true,
      'transaction_notifications': true,
      'summary_notifications': true,
      'auto_categorization': true,
      'historical_sms_processing': true,
      'debug_mode': false,
      'app_first_use_date': DateTime.now().toIso8601String(),
      'onboarding_completed': false,
      'sync_frequency_minutes': 30,
      'notification_sound': true,
      'vibration_enabled': true,
      'data_backup_enabled': true,
      'auto_backup_frequency': 'weekly',
      'currency_symbol': '₹',
      'date_format': 'dd/MM/yyyy',
      'spending_limit_enabled': false,
      'monthly_spending_limit': 50000.0,
      'low_balance_alert': false,
      'low_balance_threshold': 1000.0,
    };

    for (final entry in defaultSettings.entries) {
      if (!_prefs!.containsKey(entry.key)) {
        if (entry.value is bool) {
          await _prefs!.setBool(entry.key, entry.value as bool);
        } else if (entry.value is int) {
          await _prefs!.setInt(entry.key, entry.value as int);
        } else if (entry.value is double) {
          await _prefs!.setDouble(entry.key, entry.value as double);
        } else if (entry.value is String) {
          await _prefs!.setString(entry.key, entry.value as String);
        }
      }
    }

    print('✅ Default settings initialized');
  }

  // ✅ ENHANCED: Generic getter with type safety
  T getSetting<T>(String key, T defaultValue) {
    if (!_isInitialized || _prefs == null) {
      print('⚠️ Settings service not initialized, returning default value for $key');
      return defaultValue;
    }

    try {
      switch (T) {
        case bool:
          return (_prefs!.getBool(key) ?? defaultValue) as T;
        case int:
          return (_prefs!.getInt(key) ?? defaultValue) as T;
        case double:
          return (_prefs!.getDouble(key) ?? defaultValue) as T;
        case String:
          return (_prefs!.getString(key) ?? defaultValue) as T;
        default:
          print('⚠️ Unsupported type ${T.toString()} for key $key');
          return defaultValue;
      }
    } catch (e) {
      print('❌ Error getting setting $key: $e');
      return defaultValue;
    }
  }

  // ✅ ENHANCED: Type-specific getters for convenience
  bool getBool(String key, bool defaultValue) => getSetting<bool>(key, defaultValue);
  int getInt(String key, int defaultValue) => getSetting<int>(key, defaultValue);
  double getDouble(String key, double defaultValue) => getSetting<double>(key, defaultValue);
  String getString(String key, String defaultValue) => getSetting<String>(key, defaultValue);

  // ✅ ENHANCED: Generic setter with type safety
  Future<bool> saveSetting<T>(String key, T value) async {
    if (!_isInitialized || _prefs == null) {
      print('❌ Settings service not initialized');
      print('❌ Settings service not initialized');
      return false;
    }

    try {
      bool success = false;

      if (value is bool) {
        success = await _prefs!.setBool(key, value);
      } else if (value is int) {
        success = await _prefs!.setInt(key, value);
      } else if (value is double) {
        success = await _prefs!.setDouble(key, value);
      } else if (value is String) {
        success = await _prefs!.setString(key, value);
      } else {
        print('❌ Unsupported type ${T.toString()} for key $key');
        return false;
      }

      if (success) {
        _settingsController.add({key: value});
        print('✅ Setting saved: $key = $value');
      }

      return success;
    } catch (e) {
      print('❌ Error saving setting $key: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Type-specific setters for convenience
  Future<bool> setBool(String key, bool value) async => await saveSetting<bool>(key, value);
  Future<bool> setInt(String key, int value) async => await saveSetting<int>(key, value);
  Future<bool> setDouble(String key, double value) async => await saveSetting<double>(key, value);
  Future<bool> setString(String key, String value) async => await saveSetting<String>(key, value);

  // ✅ ENHANCED: Theme management
  // ✅ FIXED: Return ThemeMode instead of String
  ThemeMode getThemeMode() {
    final mode = getString('theme_mode', 'dark');
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
  }

  // ✅ FIXED: Accept ThemeMode instead of String
  Future<void> setThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await saveSetting('theme_mode', modeString);
  }

  // lib/services/settings_service.dart (COMPLETE THEME METHODS SECTION)
  // ✅ FIXED: Theme management methods
  String getThemeModeString() {
    return getString('theme_mode', 'dark');
  }

  // ThemeMode getThemeMode() is already defined and correct

  // Future<void> setThemeMode(ThemeMode mode) is already defined and correct

  // Future<void> setTheme(ThemeMode mode) is already defined and correct

  ThemeMode get themeMode {
    // Re-use the existing getThemeMode method logic
    final mode = getString('theme_mode', 'dark');
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      case 'system': return ThemeMode.system;
      default: return ThemeMode.dark;
    }
  }

  // Add this method to your existing SettingsService class:
  bool containsKey(String key) {
    return hasKey(key); // Use the existing hasKey method
  }

  Future<void> setTheme(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await saveSetting('theme_mode', modeString); // ✅ This is correct
  }

  // ✅ ENHANCED: Notification settings
  bool get transactionNotificationsEnabled => getBool('transaction_notifications', true);
  bool get summaryNotificationsEnabled => getBool('summary_notifications', true);
  bool get notificationSoundEnabled => getBool('notification_sound', true);
  bool get vibrationEnabled => getBool('vibration_enabled', true);

  Future<void> setTransactionNotifications(bool enabled) async {
    await setBool('transaction_notifications', enabled);
  }

  Future<void> setSummaryNotifications(bool enabled) async {
    await setBool('summary_notifications', enabled);
  }

  Future<void> setNotificationSound(bool enabled) async {
    await setBool('notification_sound', enabled);
  }

  Future<void> setVibration(bool enabled) async {
    await setBool('vibration_enabled', enabled);
  }

  // ✅ ENHANCED: SMS and sync settings
  bool get historicalSmsProcessingEnabled => getBool('historical_sms_processing', true);
  bool get autoCategorization => getBool('auto_categorization', true);
  int get syncFrequencyMinutes => getInt('sync_frequency_minutes', 30);

  Future<void> setHistoricalSmsProcessing(bool enabled) async {
    await setBool('historical_sms_processing', enabled);
  }

  Future<void> setAutoCategorization(bool enabled) async {
    await setBool('auto_categorization', enabled);
  }

  Future<void> setSyncFrequency(int minutes) async {
    await setInt('sync_frequency_minutes', minutes);
  }

  // ✅ ENHANCED: Debug and development settings
  bool get debugMode => getBool('debug_mode', false);

  Future<void> setDebugMode(bool enabled) async {
    await setBool('debug_mode', enabled);
  }

  // ✅ ENHANCED: Backup settings
  bool get dataBackupEnabled => getBool('data_backup_enabled', true);
  String get autoBackupFrequency => getString('auto_backup_frequency', 'weekly');

  Future<void> setDataBackup(bool enabled) async {
    await setBool('data_backup_enabled', enabled);
  }

  Future<void> setAutoBackupFrequency(String frequency) async {
    await setString('auto_backup_frequency', frequency);
  }

  // ✅ ENHANCED: Currency and formatting settings
  String get currencySymbol => getString('currency_symbol', '₹');
  String get dateFormat => getString('date_format', 'dd/MM/yyyy');

  Future<void> setCurrencySymbol(String symbol) async {
    await setString('currency_symbol', symbol);
  }

  Future<void> setDateFormat(String format) async {
    await setString('date_format', format);
  }

  // ✅ ENHANCED: Spending limits and alerts
  bool get spendingLimitEnabled => getBool('spending_limit_enabled', false);
  double get monthlySpendingLimit => getDouble('monthly_spending_limit', 50000.0);
  bool get lowBalanceAlert => getBool('low_balance_alert', false);
  double get lowBalanceThreshold => getDouble('low_balance_threshold', 1000.0);

  Future<void> setSpendingLimit(bool enabled, {double? limit}) async {
    await setBool('spending_limit_enabled', enabled);
    if (limit != null) {
      await setDouble('monthly_spending_limit', limit);
    }
  }

  Future<void> setLowBalanceAlert(bool enabled, {double? threshold}) async {
    await setBool('low_balance_alert', enabled);
    if (threshold != null) {
      await setDouble('low_balance_threshold', threshold);
    }
  }

  // ✅ ENHANCED: App lifecycle settings
  bool get onboardingCompleted => getBool('onboarding_completed', false);
  String get appFirstUseDate => getString('app_first_use_date', DateTime.now().toIso8601String());

  Future<void> setOnboardingCompleted(bool completed) async {
    await setBool('onboarding_completed', completed);
  }

  Future<void> setAppFirstUseDate(DateTime date) async {
    await setString('app_first_use_date', date.toIso8601String());
  }

  // ✅ ENHANCED: Haptic feedback with comprehensive types
  Future<void> triggerHaptic(HapticFeedbackType type) async {
    try {
      if (!getBool('haptic_feedback', true) || !vibrationEnabled) return;

      switch (type) {
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.impact:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.success:
          await HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.error:
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          break;
      }
    } catch (e) {
      print('❌ Error triggering haptic feedback: $e');
    }
  }

  // ✅ ENHANCED: Bulk operations
  Future<Map<String, dynamic>> getAllSettings() async {
    if (!_isInitialized || _prefs == null) {
      return {};
    }

    try {
      final allKeys = _prefs!.getKeys();
      final settings = <String, dynamic>{};

      for (final key in allKeys) {
        final value = _prefs!.get(key);
        settings[key] = value;
      }

      return settings;
    } catch (e) {
      print('❌ Error getting all settings: $e');
      return {};
    }
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (!_isInitialized || _prefs == null) return;

    try {
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await setBool(key, value);
        } else if (value is int) {
          await setInt(key, value);
        } else if (value is double) {
          await setDouble(key, value);
        } else if (value is String) {
          await setString(key, value);
        }
      }

      print('✅ Settings imported successfully');
    } catch (e) {
      print('❌ Error importing settings: $e');
    }
  }

  Future<void> resetToDefaults() async {
    if (!_isInitialized || _prefs == null) return;

    try {
      await _prefs!.clear();
      await _initializeDefaultSettings();
      _settingsController.add({'reset': true});
      print('✅ Settings reset to defaults');
    } catch (e) {
      print('❌ Error resetting settings: $e');
    }
  }

  // ✅ ENHANCED: Utility methods
  Set<String> getAllKeys() {
    if (!_isInitialized || _prefs == null) return <String>{};
    return _prefs!.getKeys();
  }

  bool hasKey(String key) {
    if (!_isInitialized || _prefs == null) return false;
    return _prefs!.containsKey(key);
  }

  Future<bool> removeKey(String key) async {
    if (!_isInitialized || _prefs == null) return false;

    try {
      final success = await _prefs!.remove(key);
      if (success) {
        _settingsController.add({'removed': key});
        print('✅ Setting removed: $key');
      }
      return success;
    } catch (e) {
      print('❌ Error removing setting $key: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Settings validation
  bool validateSetting(String key, dynamic value) {
    try {
      switch (key) {
        case 'sync_frequency_minutes':
          return value is int && value >= 1 && value <= 1440; // 1 minute to 24 hours
        case 'monthly_spending_limit':
          return value is double && value > 0 && value <= 10000000; // Reasonable limits
        case 'low_balance_threshold':
          return value is double && value >= 0 && value <= 100000;
        case 'theme_mode':
          return value is String && ['light', 'dark', 'system'].contains(value);
        case 'auto_backup_frequency':
          return value is String && ['daily', 'weekly', 'monthly'].contains(value);
        case 'currency_symbol':
          return value is String && value.isNotEmpty && value.length <= 5;
        default:
          return true; // Allow unknown settings
      }
    } catch (e) {
      print('❌ Error validating setting $key: $e');
      return false;
    }
  }

  // ✅ ENHANCED: Settings categories for organized UI
  Map<String, List<String>> getSettingsCategories() {
    return {
      'appearance': [
        'theme_mode',
        'currency_symbol',
        'date_format',
      ],
      'notifications': [
        'transaction_notifications',
        'summary_notifications',
        'notification_sound',
        'vibration_enabled',
        'haptic_feedback',
      ],
      'sms_processing': [
        'historical_sms_processing',
        'auto_categorization',
        'sync_frequency_minutes',
      ],
      'spending_control': [
        'spending_limit_enabled',
        'monthly_spending_limit',
        'low_balance_alert',
        'low_balance_threshold',
      ],
      'backup_sync': [
        'data_backup_enabled',
        'auto_backup_frequency',
      ],
      'developer': [
        'debug_mode',
      ],
    };
  }

  // Add this method to your SettingsService class
  Future<void> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get current theme to preserve it
      final currentTheme = getThemeMode();
      // Clear all preferences
      await prefs.clear();
      // Restore theme setting
      await setThemeMode(currentTheme);
      print('✅ All settings cleared (theme preserved)');
    } catch (e) {
      print('❌ Error clearing settings: $e');
      throw Exception('Failed to clear settings: $e');
    }
  }

  // ✅ ENHANCED: Statistics and analytics
  Map<String, dynamic> getUsageStatistics() {
    try {
      final appFirstUse = DateTime.parse(appFirstUseDate);
      final daysSinceFirstUse = DateTime.now().difference(appFirstUse).inDays;

      return {
        'app_first_use_date': appFirstUseDate,
        'days_since_first_use': daysSinceFirstUse,
        'onboarding_completed': onboardingCompleted,
        'settings_count': getAllKeys().length,
        'theme_mode': getThemeMode(),
        'notifications_enabled': transactionNotificationsEnabled,
        'auto_categorization_enabled': autoCategorization,
        'backup_enabled': dataBackupEnabled,
      };
    } catch (e) {
      print('❌ Error getting usage statistics: $e');
      return {};
    }
  }

  // ✅ ENHANCED: Health check
  Map<String, dynamic> performHealthCheck() {
    return {
      'service_initialized': _isInitialized,
      'shared_preferences_available': _prefs != null,
      'settings_count': getAllKeys().length,
      'stream_controller_active': !_settingsController.isClosed,
      'critical_settings_present': [
        'theme_mode',
        'haptic_feedback',
        'transaction_notifications',
      ].every((key) => hasKey(key)),
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  // ✅ CLEANUP: Dispose resources
  void dispose() {
    _settingsController.close();
    _isInitialized = false;
    print('🗑️ SettingsService disposed');
  }

  // ✅ ENHANCED: Debug utilities
  Future<void> debugPrintAllSettings() async {
    if (!debugMode) return;

    print('🐛 === SETTINGS DEBUG INFO ===');
    final allSettings = await getAllSettings();
    for (final entry in allSettings.entries) { // Ensure allSettings is awaited
      print('🐛 ${entry.key}: ${entry.value} (${entry.value.runtimeType})');
    }
    print('🐛 === END SETTINGS DEBUG ===');
  }

  Future<void> debugResetSpecificSetting(String key) async {
    if (!debugMode) return;

    await removeKey(key);
    await _initializeDefaultSettings();
    print('🐛 Reset setting: $key');
  }
}
