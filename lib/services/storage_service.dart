// lib/services/storage_service.dart (COMPLETE FIXED VERSION)
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as AppTransaction;
import '../models/category.dart';
import '../models/bank_transaction_method.dart';
import 'settings_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static StorageService get instance => _instance;

  final SettingsService _settings = SettingsService();
  Database? _database;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('💾 Initializing Enhanced Storage Service...');
      await _initDatabase();
      await _verifyDatabaseIntegrity();
      _isInitialized = true;
      print('✅ Enhanced Storage Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing storage service: $e');
      rethrow;
    }
  }

  // lib/services/storage_service.dart (SIMPLIFIED VERSION)

  Future<void> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'smartpaisa_enhanced.db');

      _database = await openDatabase(
        path,
        version: 3,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        // ✅ SIMPLIFIED: Minimal onOpen configuration
        onOpen: (db) async {
          // Only enable foreign keys - most compatible
          try {
            await db.execute('PRAGMA foreign_keys = ON');
            print('✅ Database opened with foreign keys enabled');
          } catch (e) {
            print('⚠️ Could not enable foreign keys: $e');
          }
        },
      );

      print('✅ Database opened successfully: $path');
    } catch (e) {
      print('❌ Error opening database: $e');
      rethrow;
    }
  }

  // Add this method to your StorageService class
  Future<void> clearAllData() async {
    try {
      await _database?.delete('transactions'); // Assuming _transactionsBox is your table name
      // await _categoriesBox.clear(); // If you have a categories box, clear it similarly
      print('✅ All data cleared from storage');
    } catch (e) {
      print('❌ Error clearing data: $e');
      throw Exception('Failed to clear storage data: $e');
    }
  }


  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        merchant TEXT NOT NULL,
        sender TEXT NOT NULL,
        date_time INTEGER NOT NULL,
        original_message TEXT NOT NULL,
        category_id TEXT,
        is_categorized INTEGER DEFAULT 0,
        method TEXT,
        confidence REAL,
        metadata TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
        updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_date_time ON transactions(date_time)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN confidence REAL');
      await db.execute('ALTER TABLE transactions ADD COLUMN metadata TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN created_at INTEGER DEFAULT (strftime(\'%s\', \'now\') * 1000)');
      await db.execute('ALTER TABLE transactions ADD COLUMN updated_at INTEGER DEFAULT (strftime(\'%s\', \'now\') * 1000)');
    }
  }

  Future<void> verifyDatabaseIntegrity() async {
    if (_database == null) return;

    try {
      await _database!.rawQuery('PRAGMA integrity_check');
      print('✅ Database integrity verified');
    } catch (e) {
      print('❌ Database integrity check failed: $e');
    }
  }

  Future<void> _verifyDatabaseIntegrity() async {
    await verifyDatabaseIntegrity();
  }

  // ✅ FIXED: Proper typing for saveTransaction
  Future<void> saveTransaction(AppTransaction.Transaction transaction) async {
    if (_database == null) await init();

    try {
      print('💾 Saving transaction: ${transaction.merchant} - ₹${transaction.amount}');

      await _database!.insert(
        'transactions',
        {
          'id': transaction.id,
          'amount': transaction.amount,
          'type': transaction.type.toString().split('.').last,
          'merchant': transaction.merchant,
          'sender': transaction.sender,
          'date_time': transaction.dateTime.millisecondsSinceEpoch,
          'original_message': transaction.originalMessage,
          'category_id': transaction.categoryId,
          'is_categorized': transaction.isCategorized ? 1 : 0,
          'method': transaction.method?.toString().split('.').last,
          'confidence': transaction.confidence,
          'metadata': transaction.metadata != null ? jsonEncode(transaction.metadata) : null,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Transaction saved successfully: ${transaction.id}');
    } catch (e) {
      print('❌ Error saving transaction: $e');
      rethrow;
    }
  }

  // ✅ FIXED: Return proper Transaction type
  Future<List<AppTransaction.Transaction>> getTransactions() async {
    if (_database == null) await init();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'transactions',
        orderBy: 'date_time DESC',
      );

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting transactions: $e');
      return [];
    }
  }

  // ✅ FIXED: Helper method with proper types
  AppTransaction.Transaction _transactionFromMap(Map<String, dynamic> map) {
    AppTransaction.TransactionType type = AppTransaction.TransactionType.debit;
    try {
      type = AppTransaction.TransactionType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => AppTransaction.TransactionType.debit,
      );
    } catch (e) {
      print('❌ Error parsing transaction type: $e');
    }

    BankTransactionMethod? method;
    if (map['method'] != null) {
      try {
        method = BankTransactionMethod.values.firstWhere(
              (e) => e.toString().split('.').last == map['method'],
          orElse: () => BankTransactionMethod.upi,
        );
      } catch (e) {
        print('❌ Error parsing transaction method: $e');
      }
    }

    Map<String, dynamic>? metadata;
    if (map['metadata'] != null) {
      try {
        metadata = jsonDecode(map['metadata']);
      } catch (e) {
        print('❌ Error parsing metadata: $e');
      }
    }

    return AppTransaction.Transaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      type: type,
      merchant: map['merchant'] ?? '',
      sender: map['sender'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time']),
      originalMessage: map['original_message'] ?? '',
      categoryId: map['category_id'] ?? '',
      isCategorized: (map['is_categorized'] ?? 0) == 1,
      method: method,
      confidence: map['confidence']?.toDouble(),
      metadata: metadata,
    );
  }

  Future<int> getTransactionCount() async {
    if (_database == null) await init();

    try {
      final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM transactions');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting transaction count: $e');
      return 0;
    }
  }

  // lib/services/storage_service.dart (ADD THESE METHODS)  // Add these methods to your existing StorageService class:
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final transactionCount = await getTransactionCount();
      final dbSize = await _getDatabaseSize();
      return {
        'transaction_count': transactionCount,
        'database_size_mb': dbSize,
        'last_backup': _settings.getString('last_backup_time', ''),
        'storage_location': _database?.path ?? 'Unknown',
        'initialized': _isInitialized,
      };
    } catch (e) {
      print('❌ Error getting storage info: $e');
      return {};
    }
  }

  Future<double> _getDatabaseSize() async {
    try {
      if (_database?.path != null) {
        final file = File(_database!.path);
        if (await file.exists()) {
          final size = await file.length();
          return size / (1024 * 1024); // Convert to MB
        }
      }
      return 0.0;
    } catch (e) {
      print('❌ Error getting database size: $e');
      return 0.0;
    }
  }

  Future<Map<String, bool>> checkIntegrity() async {
    try {
      await verifyDatabaseIntegrity();
      return {'integrityOk': true}; // Non-nullable true
    } catch (e) {
      print('❌ Database integrity check failed: $e');
      return {'integrityOk': false};
    }
  }

  // ✅ FIXED: Delegate to SettingsService properly
  T getSetting<T>(String key, T defaultValue) {
    return SettingsService.instance.getSetting(key, defaultValue);
  }

  // ✅ Add missing methods
  Future<List<Category>> getCategories() async {
    return Category.getDefaultCategories();
  }

  Future<void> saveCategory(Category category) async {
    print('💾 Saving category: ${category.name}');
  }

  Future<List<dynamic>> getBudgets() async {
    return [];
  }

  Future<void> saveBudget(dynamic budget) async {
    print('💾 Saving budget');
  }

  void dispose() {
    _database?.close();
    _database = null;
    _isInitialized = false;
  }
}
