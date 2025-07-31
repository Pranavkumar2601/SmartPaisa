// lib/services/smart_suggestions_service.dart

import 'dart:math';
import '../models/transaction.dart';
import '../models/category.dart';
import 'storage_service.dart';

class SmartSuggestionsService {
  static final SmartSuggestionsService _instance = SmartSuggestionsService._internal();
  static SmartSuggestionsService get instance => _instance;
  SmartSuggestionsService._internal();

  final StorageService _storageService = StorageService.instance;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  Future<void> initialize() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      _transactions = await _storageService.getTransactions();
      _categories = await _storageService.getCategories();
    } catch (e) {
      print('❌ Error loading suggestions data: $e');
    }
  }

  // Get category suggestions based on merchant and amount
  List<CategorySuggestion> getCategorySuggestions(String merchant, double amount) {
    final suggestions = <CategorySuggestion>[];

    // Exact merchant match
    final exactMatches = _findExactMerchantMatches(merchant);
    for (final match in exactMatches) {
      suggestions.add(CategorySuggestion(
        categoryId: match.categoryId,
        confidence: 0.9,
        reason: 'Previously used for $merchant',
      ));
    }

    // Similar merchant match
    final similarMatches = _findSimilarMerchantMatches(merchant);
    for (final match in similarMatches) {
      suggestions.add(CategorySuggestion(
        categoryId: match.categoryId,
        confidence: 0.7,
        reason: 'Similar to ${match.merchant}',
      ));
    }

    // Amount-based suggestions
    final amountMatches = _findAmountBasedMatches(amount);
    for (final match in amountMatches) {
      suggestions.add(CategorySuggestion(
        categoryId: match.categoryId,
        confidence: 0.5,
        reason: 'Similar amount pattern',
      ));
    }

    // Remove duplicates and sort by confidence
    final uniqueSuggestions = _removeDuplicatesAndSort(suggestions);

    return uniqueSuggestions.take(3).toList();
  }

  // Get spending insights
  List<SpendingInsight> getSpendingInsights() {
    final insights = <SpendingInsight>[];

    // Unusual spending pattern
    final unusualSpending = _detectUnusualSpending();
    if (unusualSpending != null) {
      insights.add(unusualSpending);
    }

    // Budget warnings
    final budgetWarning = _detectBudgetWarnings();
    if (budgetWarning != null) {
      insights.add(budgetWarning);
    }

    // Savings opportunities
    final savingsOpportunity = _detectSavingsOpportunities();
    if (savingsOpportunity != null) {
      insights.add(savingsOpportunity);
    }

    return insights;
  }

  // Get quick actions based on user behavior
  List<QuickAction> getQuickActions() {
    final actions = <QuickAction>[];

    // Frequent transactions
    final frequentActions = _getFrequentTransactionActions();
    actions.addAll(frequentActions);

    // Uncategorized transactions
    final uncategorizedCount = _transactions.where((t) => !t.isCategorized).length;
    if (uncategorizedCount > 0) {
      actions.add(QuickAction(
        id: 'categorize_transactions',
        title: 'Categorize $uncategorizedCount transactions',
        icon: 'category',
        action: 'categorization_screen',
        priority: uncategorizedCount > 5 ? 3 : 2,
      ));
    }

    // Sort by priority
    actions.sort((a, b) => b.priority.compareTo(a.priority));

    return actions.take(4).toList();
  }

  // Private helper methods
  List<Transaction> _findExactMerchantMatches(String merchant) {
    return _transactions
        .where((t) => t.merchant.toLowerCase() == merchant.toLowerCase() && t.isCategorized)
        .toList();
  }

  List<Transaction> _findSimilarMerchantMatches(String merchant) {
    final merchantLower = merchant.toLowerCase();
    return _transactions
        .where((t) {
      final tMerchant = t.merchant.toLowerCase();
      return tMerchant != merchantLower &&
          (tMerchant.contains(merchantLower) || merchantLower.contains(tMerchant)) &&
          t.isCategorized;
    })
        .toList();
  }

  List<Transaction> _findAmountBasedMatches(double amount) {
    final tolerance = amount * 0.1; // 10% tolerance
    return _transactions
        .where((t) =>
    (t.amount - amount).abs() <= tolerance &&
        t.isCategorized)
        .toList();
  }

  List<CategorySuggestion> _removeDuplicatesAndSort(List<CategorySuggestion> suggestions) {
    final Map<String, CategorySuggestion> uniqueMap = {};

    for (final suggestion in suggestions) {
      if (!uniqueMap.containsKey(suggestion.categoryId) ||
          uniqueMap[suggestion.categoryId]!.confidence < suggestion.confidence) {
        uniqueMap[suggestion.categoryId] = suggestion;
      }
    }

    final result = uniqueMap.values.toList();
    result.sort((a, b) => b.confidence.compareTo(a.confidence));

    return result;
  }

  SpendingInsight? _detectUnusualSpending() {
    // Implement unusual spending detection logic
    final now = DateTime.now();
    final thisMonth = _transactions.where((t) =>
    t.dateTime.month == now.month &&
        t.dateTime.year == now.year &&
        t.type == TransactionType.debit
    ).toList();

    final lastMonth = _transactions.where((t) =>
    t.dateTime.month == (now.month == 1 ? 12 : now.month - 1) &&
        t.dateTime.year == (now.month == 1 ? now.year - 1 : now.year) &&
        t.type == TransactionType.debit
    ).toList();

    if (thisMonth.isEmpty || lastMonth.isEmpty) return null;

    final thisMonthTotal = thisMonth.fold(0.0, (sum, t) => sum + t.amount);
    final lastMonthTotal = lastMonth.fold(0.0, (sum, t) => sum + t.amount);

    final increasePercent = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;

    if (increasePercent > 20) {
      return SpendingInsight(
        type: InsightType.warning,
        title: 'Spending increased by ${increasePercent.toStringAsFixed(1)}%',
        description: 'Your spending this month is significantly higher than last month',
        actionTitle: 'View breakdown',
        action: 'spending_breakdown',
      );
    }

    return null;
  }

  SpendingInsight? _detectBudgetWarnings() {
    // Implement budget warning logic
    return null; // Placeholder
  }

  SpendingInsight? _detectSavingsOpportunities() {
    // Implement savings opportunity detection
    return null; // Placeholder
  }

  List<QuickAction> _getFrequentTransactionActions() {
    final actions = <QuickAction>[];

    // Group transactions by merchant
    final merchantFrequency = <String, int>{};
    for (final transaction in _transactions) {
      merchantFrequency[transaction.merchant] =
          (merchantFrequency[transaction.merchant] ?? 0) + 1;
    }

    // Get top frequent merchants
    final sortedMerchants = merchantFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedMerchants.take(2)) {
      if (entry.value >= 3) {
        actions.add(QuickAction(
          id: 'add_${entry.key.toLowerCase().replaceAll(' ', '_')}',
          title: 'Add ${entry.key} transaction',
          icon: 'add',
          action: 'add_transaction_${entry.key}',
          priority: min(entry.value, 5),
        ));
      }
    }

    return actions;
  }
}

// Models for smart suggestions
class CategorySuggestion {
  final String categoryId;
  final double confidence;
  final String reason;

  CategorySuggestion({
    required this.categoryId,
    required this.confidence,
    required this.reason,
  });
}

class SpendingInsight {
  final InsightType type;
  final String title;
  final String description;
  final String actionTitle;
  final String action;

  SpendingInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.actionTitle,
    required this.action,
  });
}

enum InsightType {
  info,
  warning,
  success,
  tip,
}

class QuickAction {
  final String id;
  final String title;
  final String icon;
  final String action;
  final int priority;

  QuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.action,
    required this.priority,
  });
}
