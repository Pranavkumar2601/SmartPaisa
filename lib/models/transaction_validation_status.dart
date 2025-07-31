// lib/models/transaction_validation_status.dart
enum TransactionValidationStatus {
  valid,
  suspicious,
  invalid,
  pending,
  verified,
}

extension TransactionValidationStatusExtension on TransactionValidationStatus {
  String get displayName {
    switch (this) {
      case TransactionValidationStatus.valid:
        return 'Valid';
      case TransactionValidationStatus.suspicious:
        return 'Suspicious';
      case TransactionValidationStatus.invalid:
        return 'Invalid';
      case TransactionValidationStatus.pending:
        return 'Pending';
      case TransactionValidationStatus.verified:
        return 'Verified';
    }
  }
}
