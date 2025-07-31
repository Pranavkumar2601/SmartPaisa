// lib/utils/validation_utils.dart (COMPLETE ENHANCED VERSION)
class ValidationUtils {
  // ✅ ENHANCED: Known banking senders
  static final Set<String> _knownBankSenders = {
    // Major Banks
    'VM-SBIINB', 'VM-SBMSMS', 'SBI', 'SBIUPI',
    'VM-HDFCBK', 'HDFCBK', 'HDFC', 'HDFCUPI',
    'VM-ICICIB', 'ICICIB', 'ICICI', 'ICICUPI',
    'VM-AXISBK', 'AXISBK', 'AXIS', 'AXISUPI',
    'VM-KOTAKB', 'KOTAKB', 'KOTAK', 'KOTAKUPI',
    'VM-PNBSMS', 'PNBSMS', 'PNB', 'PNBUPI',

    // Payment Apps
    'VM-PAYTM', 'PAYTM', 'PAYTMU',
    'VM-PHPEAY', 'PHPEAY', 'PHONEPE',
    'VM-GPAYIG', 'GPAYIG', 'GPAY',
    'VM-AMZNPA', 'AMZNPA', 'AMAZONPAY',
    'VM-MOBIKW', 'MOBIKW', 'MOBIKWIK',

    // Other Financial Services
    'VM-ICICIB', 'ICICIB', 'ICICI',
    'BHARATPE', 'CRED', 'SLICE',
  };

  // ✅ ENHANCED: Banking keywords for transaction detection
  static final Set<String> _bankingKeywords = {
    // Transaction keywords
    'debited', 'credited', 'paid', 'received', 'transferred',
    'withdrawn', 'deposited', 'refund', 'cashback',

    // Account keywords
    'account', 'a/c', 'acc', 'balance', 'bal',

    // Payment keywords
    'upi', 'card', 'debit', 'credit', 'payment', 'transaction', 'txn',
    'neft', 'rtgs', 'imps', 'net banking',

    // Currency keywords
    'rs', 'inr', 'rupees', 'amount',

    // Banking terms
    'bank', 'banking', 'atm', 'pos', 'merchant',
  };

  // ✅ ENHANCED: Spam/promotional keywords to filter out
  static final Set<String> _spamKeywords = {
    'congratulations', 'winner', 'prize', 'lottery', 'jackpot',
    'offer', 'discount', 'sale', 'deal', 'promotion',
    'click here', 'call now', 'limited time', 'hurry',
    'free', 'gift', 'bonus points', 'reward points',
    'subscribe', 'unsubscribe', 'reply stop',
  };

  // ✅ ENHANCED: OTP keywords to filter out
  static final Set<String> _otpKeywords = {
    'otp', 'one time password', 'verification code',
    'security code', 'pin', 'passcode', 'authenticate',
    'verify', 'confirmation code',
  };

  // ✅ MAIN VALIDATION METHOD
  static bool shouldProcessMessage(String messageBody, String sender) {
    try {
      // Quick checks first
      if (messageBody.isEmpty || sender.isEmpty) return false;
      if (messageBody.length < 10) return false; // Too short to be a transaction SMS

      final lowerBody = messageBody.toLowerCase();
      final lowerSender = sender.toLowerCase();

      // Check 1: Is sender a known banking entity?
      final isBankSender = _isBankingSender(sender);

      // Check 2: Contains banking keywords?
      final hasBankingKeywords = _containsBankingKeywords(lowerBody);

      // Check 3: Contains amount information?
      final hasAmount = _containsAmount(messageBody);

      // Check 4: Not spam/promotional?
      final isNotSpam = !_isSpamMessage(lowerBody);

      // Check 5: Not OTP?
      final isNotOtp = !_isOtpMessage(lowerBody);

      // Check 6: Contains transaction indicators?
      final hasTransactionIndicators = _hasTransactionIndicators(lowerBody);

      // Scoring system
      int score = 0;
      if (isBankSender) score += 3;
      if (hasBankingKeywords) score += 2;
      if (hasAmount) score += 2;
      if (isNotSpam) score += 1;
      if (isNotOtp) score += 1;
      if (hasTransactionIndicators) score += 2;

      final shouldProcess = score >= 5; // Threshold for processing

      print('📋 SMS Validation: $sender - Score: $score - Process: $shouldProcess');
      print('   Banking Sender: $isBankSender, Keywords: $hasBankingKeywords, Amount: $hasAmount');
      print('   Not Spam: $isNotSpam, Not OTP: $isNotOtp, Transaction: $hasTransactionIndicators');

      return shouldProcess;

    } catch (e) {
      print('❌ Error in SMS validation: $e');
      return false;
    }
  }

  static bool _isBankingSender(String sender) {
    final cleanSender = sender.toUpperCase().replaceAll('-', '');

    // Check known senders
    if (_knownBankSenders.contains(sender.toUpperCase()) ||
        _knownBankSenders.contains(cleanSender)) {
      return true;
    }

    // Check patterns
    final lowerSender = sender.toLowerCase();

    // Bank name patterns
    final bankPatterns = [
      'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'pnb', 'bob', 'canara',
      'union', 'indian', 'central', 'syndicate', 'allahabad',
      'paytm', 'phonepe', 'gpay', 'amazonpay', 'mobikwik',
      'bank', 'payment', 'upi', 'wallet', 'bharatpe', 'cred'
    ];

    if (bankPatterns.any((pattern) => lowerSender.contains(pattern))) {
      return true;
    }

    // Common banking sender formats
    if (sender.startsWith('VM-') ||
        sender.startsWith('VK-') ||
        sender.startsWith('BP-') ||
        sender.length == 6) { // Common 6-digit bank codes
      return true;
    }

    return false;
  }

  static bool _containsBankingKeywords(String lowerBody) {
    return _bankingKeywords.any((keyword) => lowerBody.contains(keyword));
  }

  static bool _containsAmount(String messageBody) {
    // Pattern to match currency amounts
    final amountPatterns = [
      RegExp(r'(?:rs\.?|inr)\s*\d+', caseSensitive: false),
      RegExp(r'\d+\s*(?:rs\.?|inr)', caseSensitive: false),
      RegExp(r'amount\s*(?:of\s*)?(?:rs\.?|inr)\s*\d+', caseSensitive: false),
      RegExp(r'rupees\s*\d+', caseSensitive: false),
      RegExp(r'\d+\s*rupees', caseSensitive: false),
    ];

    return amountPatterns.any((pattern) => pattern.hasMatch(messageBody));
  }

  static bool _isSpamMessage(String lowerBody) {
    // Check for spam keywords
    if (_spamKeywords.any((keyword) => lowerBody.contains(keyword))) {
      return true;
    }

    // Check for excessive exclamation marks or caps
    if (lowerBody.split('!').length > 3 ||
        lowerBody.toUpperCase() == lowerBody && lowerBody.length > 20) {
      return true;
    }

    return false;
  }

  static bool _isOtpMessage(String lowerBody) {
    return _otpKeywords.any((keyword) => lowerBody.contains(keyword));
  }

  static bool _hasTransactionIndicators(String lowerBody) {
    final transactionIndicators = [
      'transaction', 'txn', 'payment', 'transfer', 'purchase',
      'debited', 'credited', 'withdrawn', 'deposited',
      'balance', 'account', 'card', 'upi'
    ];

    return transactionIndicators.any((indicator) => lowerBody.contains(indicator));
  }

  // ✅ ENHANCED: Additional validation methods
  static bool isValidTransactionAmount(String amountString) {
    try {
      final cleanAmount = amountString.replaceAll(RegExp(r'[^\d.]'), '');
      final amount = double.tryParse(cleanAmount);

      return amount != null &&
          amount > 0 &&
          amount <= 10000000; // Reasonable upper limit
    } catch (e) {
      return false;
    }
  }

  static bool isValidMerchantName(String merchantName) {
    if (merchantName.isEmpty || merchantName.length < 2) return false;
    if (merchantName.length > 50) return false;

    // Should not be all numbers or special characters
    if (RegExp(r'^[\d\W]+$').hasMatch(merchantName)) return false;

    return true;
  }

  static bool isValidBankSender(String sender) {
    if (sender.isEmpty) return false;
    if (sender.length < 3) return false;

    return _isBankingSender(sender);
  }

  // ✅ ENHANCED: Fraud detection helpers
  static bool isPotentialFraud(String messageBody, String sender) {
    final lowerBody = messageBody.toLowerCase();

    // Check for fraud indicators
    final fraudKeywords = [
      'suspended', 'blocked', 'expired', 'update', 'verify immediately',
      'click link', 'download app', 'enter pin', 'share otp'
    ];

    if (fraudKeywords.any((keyword) => lowerBody.contains(keyword))) {
      return true;
    }

    // Check for suspicious sender patterns
    if (sender.length > 15 || sender.contains('http')) {
      return true;
    }

    return false;
  }

  static double getMessageConfidenceScore(String messageBody, String sender) {
    double score = 0.0;

    // Sender confidence
    if (_isBankingSender(sender)) score += 0.3;

    // Content confidence
    if (_containsBankingKeywords(messageBody.toLowerCase())) score += 0.2;
    if (_containsAmount(messageBody)) score += 0.2;
    if (_hasTransactionIndicators(messageBody.toLowerCase())) score += 0.15;

    // Negative factors
    if (_isSpamMessage(messageBody.toLowerCase())) score -= 0.3;
    if (_isOtpMessage(messageBody.toLowerCase())) score -= 0.5;
    if (isPotentialFraud(messageBody, sender)) score -= 0.4;

    return score.clamp(0.0, 1.0);
  }

  // ✅ ENHANCED: Debug information
  static Map<String, dynamic> getValidationDebugInfo(String messageBody, String sender) {
    final lowerBody = messageBody.toLowerCase();

    return {
      'sender_analysis': {
        'sender': sender,
        'is_bank_sender': _isBankingSender(sender),
        'sender_length': sender.length,
      },
      'content_analysis': {
        'message_length': messageBody.length,
        'has_banking_keywords': _containsBankingKeywords(lowerBody),
        'has_amount': _containsAmount(messageBody),
        'has_transaction_indicators': _hasTransactionIndicators(lowerBody),
        'is_spam': _isSpamMessage(lowerBody),
        'is_otp': _isOtpMessage(lowerBody),
        'is_potential_fraud': isPotentialFraud(messageBody, sender),
      },
      'confidence_score': getMessageConfidenceScore(messageBody, sender),
      'should_process': shouldProcessMessage(messageBody, sender),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
