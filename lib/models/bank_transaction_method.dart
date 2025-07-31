// lib/models/bank_transaction_method.dart (COMPLETE FILE)
enum BankTransactionMethod {
  upi,
  debitCard,
  creditCard,
  netBanking,
  cash,
  cheque,
  bankTransfer,
  wallet,
  unknown,
}

extension BankTransactionMethodExtension on BankTransactionMethod {
  String get displayName {
    switch (this) {
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
      case BankTransactionMethod.cheque:
        return 'Cheque';
      case BankTransactionMethod.bankTransfer:
        return 'Bank Transfer';
      case BankTransactionMethod.wallet:
        return 'Wallet';
      case BankTransactionMethod.unknown:
        return 'Unknown';
    }
  }

  String get shortName {
    switch (this) {
      case BankTransactionMethod.upi:
        return 'UPI';
      case BankTransactionMethod.debitCard:
        return 'DC';
      case BankTransactionMethod.creditCard:
        return 'CC';
      case BankTransactionMethod.netBanking:
        return 'NB';
      case BankTransactionMethod.cash:
        return 'Cash';
      case BankTransactionMethod.cheque:
        return 'Cheque';
      case BankTransactionMethod.bankTransfer:
        return 'Transfer';
      case BankTransactionMethod.wallet:
        return 'Wallet';
      case BankTransactionMethod.unknown:
        return 'Unknown';

    }
  }
}
