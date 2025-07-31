// lib/utils/helpers.dart (COMPLETE UPDATED VERSION)
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' show DateTimeRange;

class Helpers {
  // ✅ ADD: Missing isSameDay method
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Date formatting methods
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return '${DateFormat('EEEE HH:mm').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('MMM dd, HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  static String formatDateOnly(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  // Currency formatting
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
  }

  // ✅ ADD: Missing formatCompactCurrency method
  static String formatCompactCurrency(double amount, {String symbol = '₹'}) {
    if (amount == 0) return '${symbol}0';

    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 10000) {
      return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount >= 100) {
      return '$symbol${amount.toStringAsFixed(0)}';
    } else {
      return '$symbol${amount.toStringAsFixed(1)}';
    }
  }

  static String formatCurrencyFull(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat('#,##,###.00', 'en_IN');
    return '$symbol${formatter.format(amount)}';
  }

  // Time utilities
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    }
  }

  // ✅ BONUS: Additional date utility methods
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return date.isAfter(startOfWeekMidnight.subtract(const Duration(seconds: 1))) &&
        date.isBefore(now.add(const Duration(days: 1)));
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // Date range utilities
  static DateTimeRange getCurrentMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  static DateTimeRange getCurrentWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  static DateTimeRange getLastNDaysRange(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  // String utilities
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map(capitalizeFirst).join(' ');
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Number utilities
  static double parseAmount(String amountString) {
    final cleanString = amountString
        .replaceAll(RegExp(r'[^\d.-]'), '')
        .trim();

    return double.tryParse(cleanString) ?? 0.0;
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // ✅ BONUS: Better number formatting for charts
  static String formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value >= 100) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(1);
    }
  }

  // Validation utilities
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  static bool isValidAmount(String amount) {
    final parsed = double.tryParse(amount);
    return parsed != null && parsed > 0;
  }

  // Transaction utilities
  static String getTransactionTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'debit':
        return 'Expense';
      case 'credit':
        return 'Income';
      default:
        return capitalizeFirst(type);
    }
  }

  static String getMerchantDisplayName(String merchant) {
    return merchant
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Debug utilities
  static void debugLog(String message, {String tag = 'SmartPaisa'}) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    print('[$tag] [$timestamp] $message');
  }
}
