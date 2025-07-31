// lib/services/backup_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

// ADD THESE MISSING IMPORTS
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';

import 'storage_service.dart';
import 'settings_service.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;

  BackupResult({required this.success, this.filePath, this.error});

  @override
  String toString() => 'BackupResult(success: $success, path: $filePath, error: $error)';
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static BackupService get instance => _instance;

  Future<BackupResult> createBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/smartpaisa_backup_$timestamp.json');

      // Collect all data
      final storage = StorageService.instance;
      final settings = SettingsService.instance;

      final backupData = {
        'version': '1.0',
        'timestamp': timestamp,
        'created_at': DateTime.now().toIso8601String(),
        'transactions': (await storage.getTransactions()).map((t) => t.toMap()).toList(),
        'categories': (await storage.getCategories()).map((c) => c.toMap()).toList(),
        'budgets': (await storage.getBudgets()).map((b) => b.toMap()).toList(),
        'settings': await _getAllSettings(),
        'storage_info': await storage.getStorageInfo(),
      };

      // Write to file
      await backupFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(backupData)
      );

      print('✅ Backup created: ${backupFile.path}');
      return BackupResult(success: true, filePath: backupFile.path);
    } catch (e) {
      print('❌ Error creating backup: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  Future<BackupResult> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupResult(success: false, error: 'Backup file not found');
      }

      final contents = await file.readAsString();
      final backupData = jsonDecode(contents) as Map<String, dynamic>;

      // Validate backup format
      if (backupData['version'] == null) {
        return BackupResult(success: false, error: 'Invalid backup format');
      }

      final storage = StorageService.instance;
      final settings = SettingsService.instance;

      // Restore transactions
      if (backupData['transactions'] != null) {
        final transactionList = backupData['transactions'] as List;
        for (final txnData in transactionList) {
          try {
            final transaction = Transaction.fromMap(txnData as Map<String, dynamic>);
            await storage.saveTransaction(transaction);
          } catch (e) {
            print('⚠️ Error restoring transaction: $e');
          }
        }
      }

      // Restore categories
      if (backupData['categories'] != null) {
        final categoryList = backupData['categories'] as List;
        for (final catData in categoryList) {
          try {
            final category = Category.fromMap(catData as Map<String, dynamic>);
            await storage.saveCategory(category);
          } catch (e) {
            print('⚠️ Error restoring category: $e');
          }
        }
      }

      // Restore budgets
      if (backupData['budgets'] != null) {
        final budgetList = backupData['budgets'] as List;
        for (final budgetData in budgetList) {
          try {
            final budget = Budget.fromMap(budgetData as Map<String, dynamic>);
            await storage.saveBudget(budget);
          } catch (e) {
            print('⚠️ Error restoring budget: $e');
          }
        }
      }

      // Restore settings
      if (backupData['settings'] != null) {
        await _restoreSettings(backupData['settings'] as Map<String, dynamic>);
      }

      print('✅ Backup restored successfully');
      return BackupResult(success: true);
    } catch (e) {
      print('❌ Error restoring backup: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>> _getAllSettings() async {
    try {
      final settings = SettingsService.instance;
      final allKeys = settings.getAllKeys();
      final settingsMap = <String, dynamic>{};

      for (final key in allKeys) {
        try {
          if (settings.containsKey(key)) {
            // Try bool first
            try {
              final boolValue = settings.getBool(key, false);
              settingsMap[key] = {'type': 'bool', 'value': boolValue};
              continue;
            } catch (e) {
              // Not a bool, try next type
            }

            // Try int
            try {
              final intValue = settings.getInt(key, 0);
              settingsMap[key] = {'type': 'int', 'value': intValue};
              continue;
            } catch (e) {
              // Not an int, try next type
            }

            // Try double
            try {
              final doubleValue = settings.getDouble(key, 0.0);
              settingsMap[key] = {'type': 'double', 'value': doubleValue};
              continue;
            } catch (e) {
              // Not a double, use string as fallback
            }

            // Default to string
            final stringValue = settings.getString(key, '');
            settingsMap[key] = {'type': 'string', 'value': stringValue};
          }
        } catch (e) {
          print('⚠️ Error backing up setting $key: $e');
        }
      }

      return settingsMap;
    } catch (e) {
      print('❌ Error getting all settings: $e');
      return {};
    }
  }

  Future<void> _restoreSettings(Map<String, dynamic> settingsData) async {
    try {
      final settings = SettingsService.instance;

      for (final entry in settingsData.entries) {
        try {
          final key = entry.key;
          final data = entry.value as Map<String, dynamic>;
          final type = data['type'] as String;
          final value = data['value'];

          switch (type) {
            case 'bool':
              await settings.setBool(key, value as bool);
              break;
            case 'int':
              await settings.setInt(key, value as int);
              break;
            case 'double':
              await settings.setDouble(key, value as double);
              break;
            case 'string':
              await settings.setString(key, value as String);
              break;
            default:
              print('⚠️ Unknown setting type: $type for key: $key');
          }
        } catch (e) {
          print('⚠️ Error restoring setting ${entry.key}: $e');
        }
      }
    } catch (e) {
      print('❌ Error restoring settings: $e');
    }
  }

  Future<List<File>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFiles = <File>[];

      final dirList = directory.listSync();
      for (final item in dirList) {
        if (item is File && item.path.contains('smartpaisa_backup_') && item.path.endsWith('.json')) {
          backupFiles.add(item);
        }
      }

      // Sort by creation time (newest first)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return backupFiles;
    } catch (e) {
      print('❌ Error getting available backups: $e');
      return [];
    }
  }

  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ Backup deleted: $filePath');
      }
    } catch (e) {
      print('❌ Error deleting backup: $e');
    }
  }
}
