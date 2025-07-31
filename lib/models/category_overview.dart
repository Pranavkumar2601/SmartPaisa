// lib/models/category_overview.dart (COMPLETE ENHANCED VERSION)
import 'category.dart';
import '../utils/helpers.dart';

class CategoryOverview {
  final Category category;
  final double totalAmount;
  final int transactionCount;
  final double percentage;
  final double thisMonthAmount;
  final double lastMonthAmount;
  final double monthlyChangePercent;

  CategoryOverview({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
    this.thisMonthAmount = 0.0,
    this.lastMonthAmount = 0.0,
    this.monthlyChangePercent = 0.0,
  });

  // ✅ Add missing getters
  String get formattedTotalAmount => Helpers.formatCurrency(totalAmount);

  bool get hasIncrease => monthlyChangePercent > 0;

  String get formattedThisMonthAmount => Helpers.formatCurrency(thisMonthAmount);

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  CategoryOverview copyWith({
    Category? category,
    double? totalAmount,
    int? transactionCount,
    double? percentage,
    double? thisMonthAmount,
    double? lastMonthAmount,
    double? monthlyChangePercent,
  }) {
    return CategoryOverview(
      category: category ?? this.category,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionCount: transactionCount ?? this.transactionCount,
      percentage: percentage ?? this.percentage,
      thisMonthAmount: thisMonthAmount ?? this.thisMonthAmount,
      lastMonthAmount: lastMonthAmount ?? this.lastMonthAmount,
      monthlyChangePercent: monthlyChangePercent ?? this.monthlyChangePercent,
    );
  }

  @override
  String toString() {
    return 'CategoryOverview{category: ${category.name}, totalAmount: $totalAmount, count: $transactionCount}';
  }
}

class CategoryStats {
  final double totalSpent;
  final double averageTransaction;
  final int transactionCount;
  final DateTime firstTransaction;
  final DateTime lastTransaction;
  final double thisMonthAmount;
  final double totalAmount; // Add this property

  CategoryStats({
    required this.totalSpent,
    required this.averageTransaction,
    required this.transactionCount,
    required this.firstTransaction,
    required this.lastTransaction,
    this.thisMonthAmount = 0.0,
  }) : totalAmount = totalSpent; // Set totalAmount equal to totalSpent

  String get formattedTotalSpent => Helpers.formatCurrency(totalSpent);
  String get formattedAverageTransaction => Helpers.formatCurrency(averageTransaction);
  String get formattedThisMonthAmount => Helpers.formatCurrency(thisMonthAmount);

  @override
  String toString() {
    return 'CategoryStats{totalSpent: $totalSpent, avgTransaction: $averageTransaction, count: $transactionCount}';
  }
}
