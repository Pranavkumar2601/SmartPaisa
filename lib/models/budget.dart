import 'dart:convert';

class Budget {
  final String id;
  final String name;
  final String? categoryId;
  final double amount; // ✅ FIXED: Changed from 'limit' to 'amount' to match storage service
  final String period; // ✅ ADDED: Required by storage service
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Budget({
    required this.id,
    required this.name,
    this.categoryId,
    required this.amount, // ✅ FIXED: Changed from 'limit' to 'amount'
    required this.period, // ✅ ADDED: Required field
    this.spent = 0.0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  // ✅ UPDATED: Getters now use 'amount' instead of 'limit'
  double get limit => amount; // Backward compatibility
  double get remainingAmount => amount - spent;
  double get percentageUsed => amount > 0 ? (spent / amount * 100) : 0;
  bool get isOverBudget => spent > amount;
  bool get isNearLimit => percentageUsed >= 80;

  // ✅ UPDATED: Period-based getters
  bool get isMonthly => period.toLowerCase() == 'monthly';
  bool get isWeekly => period.toLowerCase() == 'weekly';
  bool get isYearly => period.toLowerCase() == 'yearly';

  // ✅ ADDED: Check if budget is currently active based on dates
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  Budget copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? amount, // ✅ FIXED: Changed from 'limit' to 'amount'
    String? period, // ✅ ADDED: Period parameter
    double? spent,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount, // ✅ FIXED
      period: period ?? this.period, // ✅ ADDED
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  // ✅ FIXED: Updated toMap() to match storage service expectations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'amount': amount, // ✅ FIXED: Changed from 'limit'
      'period': period, // ✅ ADDED
      'spent': spent,
      'startDate': startDate.toIso8601String(), // ✅ FIXED: Use ISO string for consistency
      'endDate': endDate.toIso8601String(), // ✅ FIXED: Use ISO string for consistency
      'isActive': isActive,
    };
  }

  // ✅ FIXED: Updated fromMap() to handle both old and new formats
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      categoryId: map['categoryId']?.toString(),
      amount: _parseDouble(map['amount'] ?? map['limit'] ?? 0.0), // ✅ FIXED: Support both 'amount' and 'limit'
      period: map['period']?.toString() ?? 'monthly', // ✅ ADDED: Default to monthly
      spent: _parseDouble(map['spent'] ?? 0.0),
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      isActive: _parseBool(map['isActive'] ?? true),
    );
  }

  // ✅ FIXED: toJson() now returns Map<String, dynamic> instead of String
  Map<String, dynamic> toJson() => toMap();

  // ✅ FIXED: fromJson() now accepts Map<String, dynamic> instead of String
  factory Budget.fromJson(Map<String, dynamic> json) => Budget.fromMap(json);

  // ✅ ADDED: Legacy support for String-based JSON
  factory Budget.fromJsonString(String source) =>
      Budget.fromMap(json.decode(source));

  String toJsonString() => json.encode(toMap());

  // ✅ ADDED: Helper methods for robust parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // Handle ISO string format (preferred)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Fallback to current time if parsing fails
        return DateTime.now();
      }
    }

    // Handle milliseconds since epoch (legacy support)
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle double milliseconds
    if (value is double) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // ✅ ADDED: Validation methods
  bool isValid() {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        amount > 0 &&
        period.isNotEmpty &&
        endDate.isAfter(startDate);
  }

  List<String> getValidationErrors() {
    final errors = <String>[];

    if (id.isEmpty) errors.add('Budget ID is required');
    if (name.isEmpty) errors.add('Budget name is required');
    if (amount <= 0) errors.add('Budget amount must be greater than 0');
    if (period.isEmpty) errors.add('Budget period is required');
    if (!endDate.isAfter(startDate)) errors.add('End date must be after start date');

    return errors;
  }

  // ✅ ADDED: Utility methods for budget calculations
  double getSpentPercentage() {
    return amount > 0 ? (spent / amount) * 100 : 0;
  }

  int getDaysRemaining() {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  double getDailyAllowance() {
    final daysRemaining = getDaysRemaining();
    if (daysRemaining <= 0) return 0;
    return remainingAmount / daysRemaining;
  }

  // ✅ ADDED: Budget status enum
  BudgetStatus getStatus() {
    if (!isActive) return BudgetStatus.inactive;
    if (DateTime.now().isAfter(endDate)) return BudgetStatus.expired;
    if (isOverBudget) return BudgetStatus.exceeded;
    if (isNearLimit) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, amount: $amount, period: $period, spent: $spent, remaining: $remainingAmount, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ✅ ADDED: Budget status enum
enum BudgetStatus {
  onTrack,
  warning,
  exceeded,
  expired,
  inactive,
}

// ✅ ADDED: Extension for budget status
extension BudgetStatusExtension on BudgetStatus {
  String get displayName {
    switch (this) {
      case BudgetStatus.onTrack:
        return 'On Track';
      case BudgetStatus.warning:
        return 'Near Limit';
      case BudgetStatus.exceeded:
        return 'Over Budget';
      case BudgetStatus.expired:
        return 'Expired';
      case BudgetStatus.inactive:
        return 'Inactive';
    }
  }

  bool get isHealthy {
    return this == BudgetStatus.onTrack;
  }

  bool get needsAttention {
    return this == BudgetStatus.warning || this == BudgetStatus.exceeded;
  }
}
