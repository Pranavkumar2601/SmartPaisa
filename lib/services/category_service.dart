// lib/services/category_service.dart (COMPLETE ENHANCED VERSION)
import 'dart:async';
import 'dart:convert';
import '../models/category.dart';
import '../models/category_overview.dart';
import '../models/transaction.dart';
import 'storage_service.dart';
import 'settings_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  static CategoryService get instance => _instance;

  final StorageService _storage = StorageService.instance;
  final SettingsService _settings = SettingsService.instance;

  List<Category> _categories = [];
  bool _isInitialized = false;
  final StreamController<List<Category>> _categoriesController = StreamController<List<Category>>.broadcast();

  bool get isInitialized => _isInitialized;
  Stream<List<Category>> get categoriesStream => _categoriesController.stream;

  // ✅ ENHANCED: Initialize with comprehensive error handling
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('📂 Initializing Enhanced Category Service...');
      await initialize();
      _isInitialized = true;
      print('✅ Enhanced Category Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Category Service: $e');
      rethrow;
    }
  }

  Future<void> initialize() async {
    try {
      await _loadCategories();

      // If no categories exist, create default ones
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }

      _categoriesController.add(_categories);
      print('📂 Categories initialized: ${_categories.length} categories loaded');
    } catch (e) {
      print('❌ Error in category service initialization: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Load categories from storage
  Future<void> _loadCategories() async {
    try {
      final categoriesJson = _settings.getString('categories_data', '');

      if (categoriesJson.isNotEmpty) {
        final List<dynamic> categoriesList = jsonDecode(categoriesJson);
        _categories = categoriesList.map((json) => Category.fromJson(json)).toList();

        // Filter out deleted categories for normal operations
        _categories = _categories.where((c) => !c.isDeleted).toList();
      } else {
        _categories = [];
      }

      print('📂 Loaded ${_categories.length} categories from storage');
    } catch (e) {
      print('❌ Error loading categories: $e');
      _categories = [];
    }
  }

  // ✅ ENHANCED: Create default categories
  Future<void> _createDefaultCategories() async {
    try {
      print('📂 Creating default categories...');

      _categories = Category.getDefaultCategories();
      await _saveCategories();

      print('✅ Created ${_categories.length} default categories');
    } catch (e) {
      print('❌ Error creating default categories: $e');
    }
  }

  // ✅ ENHANCED: Save categories to storage
  Future<void> _saveCategories() async {
    try {
      final categoriesJson = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await _settings.saveSetting('categories_data', categoriesJson);

      _categoriesController.add(_categories.where((c) => !c.isDeleted).toList());
      print('💾 Categories saved successfully');
    } catch (e) {
      print('❌ Error saving categories: $e');
    }
  }

  // ✅ ENHANCED: Get all categories
  Future<List<Category>> getCategories() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _categories.where((c) => !c.isDeleted).toList();
  }

  // ✅ ENHANCED: Get category by ID
  Future<Category?> getCategoryById(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return _categories.firstWhere((c) => c.id == id && !c.isDeleted);
    } catch (e) {
      print('❌ Category not found: $id');
      return null;
    }
  }

  // ✅ ENHANCED: Get categories by type
  Future<List<Category>> getCategoriesByType(String type) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _categories.where((c) => c.type == type && !c.isDeleted).toList();
  }

  // ✅ ENHANCED: Add new category
  Future<void> addCategory(Category category) async {
    try {
      // Check for duplicate names
      final existingCategory = _categories
          .where((c) => !c.isDeleted)
          .where((c) => c.name.toLowerCase() == category.name.toLowerCase())
          .firstOrNull;

      if (existingCategory != null) {
        throw Exception('Category with name "${category.name}" already exists');
      }

      _categories.add(category);
      await _saveCategories();
      print('✅ Category added: ${category.name}');
    } catch (e) {
      print('❌ Error adding category: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Update existing category
  Future<void> updateCategory(Category category) async {
    try {
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category.copyWith(updatedAt: DateTime.now());
        await _saveCategories();
        print('✅ Category updated: ${category.name}');
      } else {
        throw Exception('Category not found: ${category.id}');
      }
    } catch (e) {
      print('❌ Error updating category: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Delete category (soft delete)
  Future<void> deleteCategory(String categoryId) async {
    try {
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        final category = _categories[index];

        if (category.isSystem) {
          throw Exception('Cannot delete system category: ${category.name}');
        }

        // Soft delete
        _categories[index] = category.copyWith(
          isDeleted: true,
          updatedAt: DateTime.now(),
        );

        await _saveCategories();
        print('✅ Category deleted: ${category.name}');
      } else {
        throw Exception('Category not found: $categoryId');
      }
    } catch (e) {
      print('❌ Error deleting category: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Save category (for compatibility)
  Future<void> saveCategory(Category category) async {
    final existingIndex = _categories.indexWhere((c) => c.id == category.id);

    if (existingIndex != -1) {
      await updateCategory(category);
    } else {
      await addCategory(category);
    }
  }

  // ✅ ENHANCED: Assign transaction to category
  Future<void> assignTransactionToCategory(String transactionId, String categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Category not found: $categoryId');
      }

      print('✅ Transaction $transactionId assigned to category: ${category.name}');
    } catch (e) {
      print('❌ Error assigning transaction to category: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Get category overview with statistics
  Future<List<CategoryOverview>> getCategoryOverview() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final categories = await getCategories();
      final overviews = <CategoryOverview>[];

      // Get all transactions for analysis
      final allTransactions = await _storage.getTransactions();
      final totalSpent = _calculateTotalSpent(allTransactions);

      for (final category in categories) {
        // Calculate real statistics from transactions
        final categoryTransactions = allTransactions
            .where((t) => t.categoryId == category.id && t.type == TransactionType.debit)
            .toList();

        final totalAmount = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
        final percentage = totalSpent > 0 ? (totalAmount / totalSpent * 100) : 0.0;

        final overview = CategoryOverview(
          category: category,
          totalAmount: totalAmount,
          transactionCount: categoryTransactions.length,
          percentage: percentage,
        );

        overviews.add(overview);
      }

      // Sort by total amount descending
      overviews.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      print('📊 Generated category overview: ${overviews.length} categories');
      return overviews;
    } catch (e) {
      print('❌ Error getting category overview: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Get transactions for specific category
  Future<List<Transaction>> getCategoryTransactions(String categoryId) async {
    try {
      final allTransactions = await _storage.getTransactions();
      final categoryTransactions = allTransactions
          .where((t) => t.categoryId == categoryId)
          .toList();

      // Sort by date descending
      categoryTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      print('📊 Found ${categoryTransactions.length} transactions for category: $categoryId');
      return categoryTransactions;
    } catch (e) {
      print('❌ Error getting category transactions: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Get detailed statistics for category
  Future<CategoryStats> getCategoryStats(String categoryId) async {
    try {
      final transactions = await getCategoryTransactions(categoryId);
      final debitTransactions = transactions.where((t) => t.type == TransactionType.debit).toList();

      if (debitTransactions.isEmpty) {
        return CategoryStats(
          totalSpent: 0.0,
          averageTransaction: 0.0,
          transactionCount: 0,
          firstTransaction: DateTime.now(),
          lastTransaction: DateTime.now(),
        );
      }

      final totalSpent = debitTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final averageTransaction = totalSpent / debitTransactions.length;

      // Sort by date to find first and last
      debitTransactions.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final stats = CategoryStats(
        totalSpent: totalSpent,
        averageTransaction: averageTransaction,
        transactionCount: debitTransactions.length,
        firstTransaction: debitTransactions.first.dateTime,
        lastTransaction: debitTransactions.last.dateTime,
      );

      print('📊 Generated stats for category $categoryId: ${stats.transactionCount} transactions');
      return stats;
    } catch (e) {
      print('❌ Error getting category stats: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Get spending by category for date range
  Future<Map<String, double>> getCategorySpending({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryType,
  }) async {
    try {
      final allTransactions = await _storage.getTransactions();
      final categories = await getCategories();

      var filteredTransactions = allTransactions
          .where((t) => t.type == TransactionType.debit)
          .toList();

      // Apply date filters
      if (startDate != null) {
        filteredTransactions = filteredTransactions
            .where((t) => t.dateTime.isAfter(startDate) || t.dateTime.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        filteredTransactions = filteredTransactions
            .where((t) => t.dateTime.isBefore(endDate) || t.dateTime.isAtSameMomentAs(endDate))
            .toList();
      }

      final categorySpending = <String, double>{};

      // Calculate spending for each category
      for (final category in categories) {
        if (categoryType != null && category.type != categoryType) continue;

        final categoryTransactions = filteredTransactions
            .where((t) => t.categoryId == category.id)
            .toList();

        final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
        if (totalSpent > 0) {
          categorySpending[category.name] = totalSpent;
        }
      }

      return categorySpending;
    } catch (e) {
      print('❌ Error getting category spending: $e');
      return {};
    }
  }

  // ✅ ENHANCED: Get top spending categories
  Future<List<CategoryOverview>> getTopSpendingCategories({int limit = 5}) async {
    try {
      final allOverviews = await getCategoryOverview();

      // Filter out categories with no spending
      final spendingCategories = allOverviews
          .where((overview) => overview.totalAmount > 0)
          .toList();

      // Sort by total amount descending and take top N
      spendingCategories.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return spendingCategories.take(limit).toList();
    } catch (e) {
      print('❌ Error getting top spending categories: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Auto-categorize transaction based on merchant
  Future<String?> suggestCategoryForTransaction(Transaction transaction) async {
    try {
      final merchantLower = transaction.merchant.toLowerCase();

      // Define merchant patterns for auto-categorization
      const merchantPatterns = {
        'food_dining': [
          'swiggy', 'zomato', 'restaurant', 'cafe', 'dominos', 'kfc', 'mcdonald',
          'burger', 'pizza', 'food', 'dining', 'eat', 'kitchen'
        ],
        'transportation': [
          'uber', 'ola', 'metro', 'petrol', 'fuel', 'bpcl', 'iocl', 'hp',
          'transport', 'taxi', 'bus', 'train', 'flight', 'airport'
        ],
        'shopping': [
          'amazon', 'flipkart', 'myntra', 'nykaa', 'mall', 'store', 'shop',
          'retail', 'market', 'buy', 'purchase'
        ],
        'entertainment': [
          'netflix', 'spotify', 'youtube', 'movie', 'cinema', 'pvr', 'inox',
          'game', 'music', 'entertainment', 'fun', 'leisure'
        ],
        'utilities': [
          'electricity', 'water', 'gas', 'internet', 'mobile', 'jio', 'airtel',
          'vi', 'bsnl', 'bill', 'utility', 'service'
        ],
      };

      // Find matching category
      for (final entry in merchantPatterns.entries) {
        final categoryId = entry.key;
        final patterns = entry.value;

        if (patterns.any((pattern) => merchantLower.contains(pattern))) {
          print('🤖 Auto-categorization suggestion: $categoryId for ${transaction.merchant}');
          return categoryId;
        }
      }

      return null; // No suggestion found
    } catch (e) {
      print('❌ Error suggesting category: $e');
      return null;
    }
  }

  // ✅ ENHANCED: Bulk categorize transactions
  Future<int> bulkCategorizeTransactions(List<Transaction> transactions) async {
    int categorizedCount = 0;

    try {
      for (final transaction in transactions) {
        if (transaction.isCategorized) continue;

        final suggestedCategoryId = await suggestCategoryForTransaction(transaction);
        if (suggestedCategoryId != null) {
          await assignTransactionToCategory(transaction.id, suggestedCategoryId);
          categorizedCount++;
        }
      }

      print('🤖 Bulk categorization completed: $categorizedCount transactions categorized');
      return categorizedCount;
    } catch (e) {
      print('❌ Error in bulk categorization: $e');
      return categorizedCount;
    }
  }

  // ✅ HELPER: Calculate total spent from transactions
  double _calculateTotalSpent(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ✅ ENHANCED: Import/Export categories
  Future<String> exportCategories() async {
    try {
      final categories = await getCategories();
      final exportData = {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => c.toJson()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      print('❌ Error exporting categories: $e');
      rethrow;
    }
  }

  Future<void> importCategories(String jsonData) async {
    try {
      final importData = jsonDecode(jsonData) as Map<String, dynamic>;
      final categoriesData = importData['categories'] as List<dynamic>;

      for (final categoryData in categoriesData) {
        final category = Category.fromJson(categoryData);

        // Check if category already exists
        final existingCategory = _categories
            .where((c) => c.id == category.id || c.name == category.name)
            .firstOrNull;

        if (existingCategory == null) {
          await addCategory(category);
        }
      }

      print('✅ Categories imported successfully');
    } catch (e) {
      print('❌ Error importing categories: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Reset categories to default
  Future<void> resetToDefaultCategories() async {
    try {
      _categories.clear();
      await _createDefaultCategories();
      print('✅ Categories reset to defaults');
    } catch (e) {
      print('❌ Error resetting categories: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Search categories
  Future<List<Category>> searchCategories(String query) async {
    try {
      final categories = await getCategories();
      final queryLower = query.toLowerCase();

      return categories
          .where((category) =>
      category.name.toLowerCase().contains(queryLower) ||
          category.description.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      print('❌ Error searching categories: $e');
      return [];
    }
  }

  // ✅ ENHANCED: Get category usage statistics
  Future<Map<String, dynamic>> getCategoryUsageStats() async {
    try {
      final allTransactions = await _storage.getTransactions();
      final categories = await getCategories();

      final stats = {
        'total_categories': categories.length,
        'used_categories': 0,
        'unused_categories': 0,
        'most_used_category': '',
        'least_used_category': '',
        'usage_distribution': <String, int>{},
      };

      final categoryUsage = <String, int>{};

      // Count transactions per category
      for (final category in categories) {
        final count = allTransactions
            .where((t) => t.categoryId == category.id)
            .length;

        categoryUsage[category.name] = count;

        if (count > 0) {
          stats['used_categories'] = (stats['used_categories'] as int) + 1;
        } else {
          stats['unused_categories'] = (stats['unused_categories'] as int) + 1;
        }
      }

      // Find most and least used categories
      if (categoryUsage.isNotEmpty) {
        final sortedUsage = categoryUsage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        stats['most_used_category'] = sortedUsage.first.key;
        stats['least_used_category'] = sortedUsage.last.key;
        stats['usage_distribution'] = categoryUsage;
      }

      return stats;
    } catch (e) {
      print('❌ Error getting category usage stats: $e');
      return {};
    }
  }

  // ✅ CLEANUP: Dispose resources
  void dispose() {
    _categoriesController.close();
    _isInitialized = false;
    print('🗑️ CategoryService disposed');
  }
}

// ✅ EXTENSION: Add helpful extension method
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
