// lib/services/transaction_parser.dart (COMPLETE ENHANCED VERSION)
import 'dart:math';
import '../models/transaction.dart';
import '../models/bank_transaction_method.dart';

class TransactionParser {
  // ✅ ENHANCED: Banking patterns for different scenarios
  static final List<Map<String, dynamic>> _bankPatterns = [
    // UPI Patterns
    {
      'type': 'upi',
      'patterns': [
        r'UPI.*?(?:Rs\.?|INR)\s*(\d+(?:\.\d{2})?)',
        r'paid\s+(?:Rs\.?|INR)\s*(\d+(?:\.\d{2})?)\s+to\s+(.+?)\s+via\s+UPI',
        r'(\d+(?:\.\d{2})?)\s+debited.*?UPI.*?to\s+(.+)',
        r'UPI.*?(\d+(?:\.\d{2})?)\s+(?:sent to|paid to)\s+(.+)',
      ],
      'method': BankTransactionMethod.upi,
    },
    // Debit Card Patterns
    {
      'type': 'debit_card',
      'patterns': [
        r'(?:debit card|DC).*?(?:Rs\.?|INR)\s*(\d+(?:\.\d{2})?)',
        r'Card\s+(\d+(?:\.\d{2})?)\s+spent\s+at\s+(.+)',
        r'(\d+(?:\.\d{2})?)\s+debited.*?(?:debit card|DC).*?at\s+(.+)',
      ],
      'method': BankTransactionMethod.debitCard,
    },
    // Credit Card Patterns
    {
      'type': 'credit_card',
      'patterns': [
        r'(?:credit card|CC).*?(?:Rs\.?|INR)\s*(\d+(?:\.\d{2})?)',
        r'(\d+(?:\.\d{2})?)\s+spent.*?(?:credit card|CC).*?at\s+(.+)',
      ],
      'method': BankTransactionMethod.creditCard,
    },
    // Net Banking Patterns
    {
      'type': 'net_banking',
      'patterns': [
        r'(?:net banking|NEFT|RTGS).*?(?:Rs\.?|INR)\s*(\d+(?:\.\d{2})?)',
        r'(\d+(?:\.\d{2})?)\s+transferred.*?(?:net banking|NEFT|RTGS)',
      ],
      'method': BankTransactionMethod.netBanking,
    },
  ];

  // ✅ ENHANCED: Merchant extraction patterns
  static final List<RegExp> _merchantPatterns = [
    RegExp(r'to\s+([A-Z][A-Z0-9\s]{2,30})', caseSensitive: false),
    RegExp(r'at\s+([A-Z][A-Z0-9\s]{2,30})', caseSensitive: false),
    RegExp(r'paid\s+to\s+([A-Z][A-Z0-9\s]{2,30})', caseSensitive: false),
    RegExp(r'from\s+([A-Z][A-Z0-9\s]{2,30})', caseSensitive: false),
    RegExp(r'VPA\s+([A-Z0-9@\.\s]{5,30})', caseSensitive: false),
  ];

  // lib/services/transaction_parser.dart (ADD THIS METHOD)
  // Add this method to your existing TransactionParser class:
  void debugTestParsing() {
    final testMessages = [
      'Dear Customer, Rs.500.00 debited from your account ending with 1234 at SWIGGY DELHI on 15-Jan-24. UPI Ref No: 123456789. Available balance: Rs.5000.00',
      'Rs.2000 paid to AMAZON PAY via UPI on 15-Jan-24. UPI transaction ID: 123456789',
      'Your card ending 1234 used for transaction of Rs.1500.00 at FLIPKART on 15-Jan-24',
    ];

    print('🧪 Starting debug test parsing...');

    for (int i = 0; i < testMessages.length; i++) {
      final message = testMessages[i];
      print('\n--- Test Message ${i + 1} ---');
      print('Message: ${message.substring(0, 50)}...');

      final transaction = parseTransactionFromSms(
        message,
        'VM-TESTBK',
        DateTime.now(),
      );

      if (transaction != null) {
        print('✅ Parsed successfully:');
        print('   Amount: ₹${transaction.amount}');
        print('   Merchant: ${transaction.merchant}');
        print('   Type: ${transaction.type}');
        print('   Method: ${transaction.method}');
        print('   Confidence: ${transaction.confidence?.toStringAsFixed(2)}');
      } else {
        print('❌ Failed to parse');
      }
    }

    print('\n🧪 Debug test parsing completed');
  }
  // ✅ ENHANCED: Transaction type detection
  static final List<String> _debitKeywords = [
    'debited', 'spent', 'paid', 'withdrawn', 'deducted', 'charged',
    'purchase', 'payment', 'transfer', 'sent'
  ];

  static final List<String> _creditKeywords = [
    'credited', 'received', 'deposit', 'refund', 'cashback',
    'interest', 'salary', 'bonus', 'dividend'
  ];

  Transaction? parseTransactionFromSms(String smsBody, String sender, DateTime dateTime) {
    try {
      print('🔍 Parsing SMS: ${smsBody.substring(0, min(100, smsBody.length))}...');

      // Extract amount
      final amount = _extractAmount(smsBody);
      if (amount == null || amount <= 0) {
        print('❌ No valid amount found');
        return null;
      }

      // Determine transaction type
      final type = _determineTransactionType(smsBody);

      // Extract merchant
      final merchant = _extractMerchant(smsBody);

      // Determine payment method
      final method = _determinePaymentMethod(smsBody);

      // Calculate confidence score
      final confidence = _calculateConfidence(smsBody, amount, merchant, method);

      final transaction = Transaction(
        amount: amount,
        type: type,
        merchant: merchant,
        sender: sender,
        dateTime: dateTime,
        originalMessage: smsBody,
        categoryId: '',
        isCategorized: false,
        method: method,
        confidence: confidence,
        metadata: {
          'parsed_at': DateTime.now().toIso8601String(),
          'parser_version': '2.0',
        },
      );

      print('✅ Transaction parsed successfully: ${merchant} - ₹${amount}');
      return transaction;

    } catch (e) {
      print('❌ Error parsing transaction: $e');
      return null;
    }
  }

  // ✅ LEGACY: For backward compatibility
  Transaction? parseTransactionWithConfidence(String smsBody, String sender, DateTime dateTime) {
    return parseTransactionFromSms(smsBody, sender, dateTime);
  }

  double? _extractAmount(String smsBody) {
    final amountPatterns = [
      RegExp(r'(?:Rs\.?|INR)\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{2})?)\s*(?:Rs\.?|INR)', caseSensitive: false),
      RegExp(r'amount\s*(?:of\s*)?(?:Rs\.?|INR)\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
    ];

    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '');
        if (amount != null && amount > 0 && amount < 10000000) { // Reasonable limits
          return amount;
        }
      }
    }

    return null;
  }

  TransactionType _determineTransactionType(String smsBody) {
    final lowerBody = smsBody.toLowerCase();

    // Check for credit keywords
    for (final keyword in _creditKeywords) {
      if (lowerBody.contains(keyword)) {
        return TransactionType.credit;
      }
    }

    // Check for debit keywords
    for (final keyword in _debitKeywords) {
      if (lowerBody.contains(keyword)) {
        return TransactionType.debit;
      }
    }

    // Default to debit for bank SMS
    return TransactionType.debit;
  }

  String _extractMerchant(String smsBody) {
    // Try different merchant extraction methods
    String? merchant;

    // Method 1: Use predefined patterns
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        merchant = match.group(1)?.trim();
        if (merchant != null && merchant.length > 2) {
          break;
        }
      }
    }

    // Method 2: Extract from UPI VPA
    if (merchant == null || merchant.isEmpty) {
      final vpaPattern = RegExp(r'([a-zA-Z0-9\.\-_]+@[a-zA-Z0-9\.\-_]+)', caseSensitive: false);
      final vpaMatch = vpaPattern.firstMatch(smsBody);
      if (vpaMatch != null) {
        final vpa = vpaMatch.group(1);
        if (vpa != null) {
          merchant = vpa.split('@')[0].replaceAll('.', ' ').replaceAll('-', ' ').replaceAll('_', ' ');
        }
      }
    }

    // Method 3: Extract from card transactions
    if (merchant == null || merchant.isEmpty) {
      final cardPatterns = [
        RegExp(r'at\s+([A-Z][A-Z0-9\s]{2,25})', caseSensitive: false),
        RegExp(r'merchant\s+([A-Z][A-Z0-9\s]{2,25})', caseSensitive: false),
      ];

      for (final pattern in cardPatterns) {
        final match = pattern.firstMatch(smsBody);
        if (match != null) {
          merchant = match.group(1)?.trim();
          if (merchant != null && merchant.length > 2) {
            break;
          }
        }
      }
    }

    // Method 4: Extract from transaction description
    if (merchant == null || merchant.isEmpty) {
      final words = smsBody.split(' ');
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i].toLowerCase() == 'to' || words[i].toLowerCase() == 'at') {
          if (words[i + 1].length > 2) {
            merchant = words.sublist(i + 1, min(i + 4, words.length)).join(' ');
            break;
          }
        }
      }
    }

    // Clean up merchant name
    if (merchant != null) {
      merchant = _cleanMerchantName(merchant);
    }

    return merchant?.isNotEmpty == true ? merchant! : 'Unknown Merchant';
  }

  String _cleanMerchantName(String merchant) {
    // Remove special characters and clean up
    merchant = merchant
        .replaceAll(RegExp(r'[^\w\s@\.\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Capitalize properly
    final words = merchant.split(' ');
    final cleanWords = words.map((word) {
      if (word.length <= 2) return word.toUpperCase();
      return word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return cleanWords.join(' ');
  }

  BankTransactionMethod? _determinePaymentMethod(String smsBody) {
    final lowerBody = smsBody.toLowerCase();

    // Check UPI
    if (lowerBody.contains('upi') ||
        lowerBody.contains('paytm') ||
        lowerBody.contains('gpay') ||
        lowerBody.contains('phonepe') ||
        lowerBody.contains('bhim') ||
        lowerBody.contains('@')) {
      return BankTransactionMethod.upi;
    }

    // Check Credit Card
    if (lowerBody.contains('credit card') ||
        lowerBody.contains('cc ') ||
        lowerBody.contains(' cc') ||
        lowerBody.contains('credit')) {
      return BankTransactionMethod.creditCard;
    }

    // Check Debit Card
    if (lowerBody.contains('debit card') ||
        lowerBody.contains('dc ') ||
        lowerBody.contains(' dc') ||
        lowerBody.contains('debit')) {
      return BankTransactionMethod.debitCard;
    }

    // Check Net Banking
    if (lowerBody.contains('net banking') ||
        lowerBody.contains('neft') ||
        lowerBody.contains('rtgs') ||
        lowerBody.contains('imps')) {
      return BankTransactionMethod.netBanking;
    }

    // Check Wallet
    if (lowerBody.contains('wallet') ||
        lowerBody.contains('paytm wallet') ||
        lowerBody.contains('mobikwik')) {
      return BankTransactionMethod.wallet;
    }

    return null;
  }

  double _calculateConfidence(String smsBody, double amount, String merchant, BankTransactionMethod? method) {
    double confidence = 0.0;

    // Amount confidence
    if (amount > 0 && amount < 100000) {
      confidence += 0.3;
    } else if (amount >= 100000) {
      confidence += 0.2;
    }

    // Merchant confidence
    if (merchant != 'Unknown Merchant') {
      if (merchant.length > 3) confidence += 0.2;
      if (merchant.contains('@')) confidence += 0.1; // UPI VPA
      if (!merchant.contains('XXXX')) confidence += 0.1; // Not masked
    }

    // Method confidence
    if (method != null) {
      confidence += 0.2;
    }

    // SMS structure confidence
    final lowerBody = smsBody.toLowerCase();
    if (lowerBody.contains('account') || lowerBody.contains('a/c')) confidence += 0.1;
    if (lowerBody.contains('balance') || lowerBody.contains('bal')) confidence += 0.1;
    if (lowerBody.contains('transaction') || lowerBody.contains('txn')) confidence += 0.05;

    // Bank sender confidence
    final commonBanks = ['sbi', 'hdfc', 'icici', 'axis', 'kotak', 'paytm', 'phonepe'];
    if (commonBanks.any((bank) => lowerBody.contains(bank))) {
      confidence += 0.05;
    }

    return confidence.clamp(0.0, 1.0);
  }

  // ✅ ENHANCED: Validation methods
  bool isValidTransactionSms(String smsBody, String sender) {
    final lowerBody = smsBody.toLowerCase();
    final lowerSender = sender.toLowerCase();

    // Check for banking keywords
    final bankingKeywords = [
      'account', 'a/c', 'balance', 'transaction', 'txn',
      'debited', 'credited', 'paid', 'received', 'upi',
      'card', 'rs', 'inr', 'rupees'
    ];

    bool hasKeyword = bankingKeywords.any((keyword) => lowerBody.contains(keyword));
    bool hasAmount = _extractAmount(smsBody) != null;
    bool isBankSender = _isBankingSender(sender);

    return hasKeyword && hasAmount && isBankSender;
  }

  bool _isBankingSender(String sender) {
    final lowerSender = sender.toLowerCase();
    final bankPatterns = [
      'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'pnb', 'bob', 'canara',
      'union', 'indian', 'central', 'syndicate', 'allahabad',
      'paytm', 'phonepe', 'gpay', 'amazonpay', 'mobikwik',
      'bank', 'payment', 'upi', 'wallet'
    ];

    return bankPatterns.any((pattern) => lowerSender.contains(pattern)) ||
        sender.startsWith('VM-') ||
        sender.startsWith('VK-') ||
        sender.length == 6; // Common bank code format
  }

  // ✅ ENHANCED: Debug and analytics methods
  Map<String, dynamic> getParsingDebugInfo(String smsBody) {
    final amount = _extractAmount(smsBody);
    final type = _determineTransactionType(smsBody);
    final merchant = _extractMerchant(smsBody);
    final method = _determinePaymentMethod(smsBody);
    final confidence = _calculateConfidence(smsBody, amount ?? 0, merchant, method);

    return {
      'amount': amount,
      'type': type.toString(),
      'merchant': merchant,
      'method': method?.toString(),
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
