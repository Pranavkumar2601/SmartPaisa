// lib/models/transaction.dart (FIXED - NO SPACE IN FILENAME)
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'bank_transaction_method.dart';

enum TransactionType {
  debit,
  credit
}

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String merchant;
  final String sender;
  final DateTime dateTime;
  final String originalMessage;
  final String categoryId;
  final bool isCategorized;
  final BankTransactionMethod? method;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  Transaction({
    String? id,
    required this.amount,
    required this.type,
    required this.merchant,
    required this.sender,
    required this.dateTime,
    required this.originalMessage,
    required this.categoryId,
    required this.isCategorized,
    this.method,
    this.confidence,
    this.metadata,
  }) : id = id ?? const Uuid().v4();

  // Helper getters for UI
  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  String get typeString {
    switch (type) {
      case TransactionType.debit:
        return 'Expense';
      case TransactionType.credit:
        return 'Income';
    }
  }

  String get methodString {
    switch (method) {
      case BankTransactionMethod.upi:
        return 'UPI';
      case BankTransactionMethod.debitCard:
        return 'Debit Card';
      case BankTransactionMethod.creditCard:
        return 'Credit Card';
      case BankTransactionMethod.netBanking:
        return 'Net Banking';
      case BankTransactionMethod.cash:
        return 'Cash';
      case BankTransactionMethod.wallet:
        return 'Wallet';
      default:
        return 'Unknown';
    }
  }

  IconData get methodIcon {
    switch (method) {
      case BankTransactionMethod.upi:
        return Icons.account_balance_wallet_rounded;
      case BankTransactionMethod.debitCard:
      case BankTransactionMethod.creditCard:
        return Icons.credit_card_rounded;
      case BankTransactionMethod.netBanking:
        return Icons.account_balance_rounded;
      case BankTransactionMethod.cash:
        return Icons.monetization_on_rounded;
      case BankTransactionMethod.wallet:
        return Icons.wallet_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  // Optional fields for additional transaction data
  String? get referenceNumber => metadata?['referenceNumber'];
  double? get balance => metadata?['balance'];
  String? get accountNumber => metadata?['accountNumber'];

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? merchant,
    String? sender,
    DateTime? dateTime,
    String? originalMessage,
    String? categoryId,
    bool? isCategorized,
    BankTransactionMethod? method,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      sender: sender ?? this.sender,
      dateTime: dateTime ?? this.dateTime,
      originalMessage: originalMessage ?? this.originalMessage,
      categoryId: categoryId ?? this.categoryId,
      isCategorized: isCategorized ?? this.isCategorized,
      method: method ?? this.method,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString().split('.').last,
      'merchant': merchant,
      'sender': sender,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'originalMessage': originalMessage,
      'categoryId': categoryId,
      'isCategorized': isCategorized,
      'method': method?.toString().split('.').last,
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  // Add toMap method for backup service
  Map<String, dynamic> toMap() => toJson();

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.debit,
      ),
      merchant: json['merchant'] ?? '',
      sender: json['sender'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
      originalMessage: json['originalMessage'] ?? '',
      categoryId: json['categoryId'] ?? '',
      isCategorized: json['isCategorized'] ?? false,
      method: json['method'] != null
          ? BankTransactionMethod.values.firstWhere(
            (e) => e.toString().split('.').last == json['method'],
        orElse: () => BankTransactionMethod.upi,
      )
          : null,
      confidence: json['confidence']?.toDouble(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // Add fromMap method for backup service
  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction.fromJson(map);

  @override
  String toString() {
    return 'Transaction{id: $id, amount: $amount, type: $type, merchant: $merchant}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
