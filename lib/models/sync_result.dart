// lib/models/sync_result.dart
class SyncResult {
  final bool success;
  final String message;
  final int newTransactions;
  final int duplicatesSkipped;
  final int invalidMessages;
  final int totalProcessed;
  final DateTime syncTime;
  final Duration syncDuration;
  final Map<String, dynamic>? metadata;

  SyncResult({
    required this.success,
    required this.message,
    required this.newTransactions,
    required this.duplicatesSkipped,
    required this.invalidMessages,
    this.totalProcessed = 0,
    DateTime? syncTime,
    Duration? syncDuration,
    this.metadata,
  }) : syncTime = syncTime ?? DateTime.now(),
        syncDuration = syncDuration ?? Duration.zero;

  // ✅ Success factory constructor
  factory SyncResult.success({
    required int newTransactions,
    required int duplicatesSkipped,
    required int invalidMessages,
    String? message,
    Duration? syncDuration,
    Map<String, dynamic>? metadata,
  }) {
    final totalProcessed = newTransactions + duplicatesSkipped + invalidMessages;
    return SyncResult(
      success: true,
      message: message ?? 'Sync completed successfully',
      newTransactions: newTransactions,
      duplicatesSkipped: duplicatesSkipped,
      invalidMessages: invalidMessages,
      totalProcessed: totalProcessed,
      syncDuration: syncDuration,
      metadata: metadata,
    );
  }

  // ✅ Failure factory constructor
  factory SyncResult.failure({
    required String message,
    int newTransactions = 0,
    int duplicatesSkipped = 0,
    int invalidMessages = 0,
    Duration? syncDuration,
    Map<String, dynamic>? metadata,
  }) {
    return SyncResult(
      success: false,
      message: message,
      newTransactions: newTransactions,
      duplicatesSkipped: duplicatesSkipped,
      invalidMessages: invalidMessages,
      totalProcessed: newTransactions + duplicatesSkipped + invalidMessages,
      syncDuration: syncDuration,
      metadata: metadata,
    );
  }

  // ✅ Empty result constructor
  factory SyncResult.empty({String? message}) {
    return SyncResult(
      success: true,
      message: message ?? 'No new transactions found',
      newTransactions: 0,
      duplicatesSkipped: 0,
      invalidMessages: 0,
      totalProcessed: 0,
    );
  }

  // ✅ Check if sync found any results
  bool get hasResults => totalProcessed > 0;

  // ✅ Check if sync was successful with new transactions
  bool get hasNewTransactions => success && newTransactions > 0;

  // ✅ Get success rate percentage
  double get successRate => totalProcessed > 0
      ? (newTransactions / totalProcessed) * 100
      : 0.0;

  // ✅ Get formatted summary
  String get summary {
    if (!success) return message;

    if (totalProcessed == 0) return 'No SMS to process';

    return 'Found $newTransactions new transactions, '
        'skipped $duplicatesSkipped duplicates, '
        'ignored $invalidMessages invalid messages';
  }

  // ✅ JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'newTransactions': newTransactions,
      'duplicatesSkipped': duplicatesSkipped,
      'invalidMessages': invalidMessages,
      'totalProcessed': totalProcessed,
      'syncTime': syncTime.toIso8601String(),
      'syncDuration': syncDuration.inMilliseconds,
      'successRate': successRate,
      'metadata': metadata,
    };
  }

  // ✅ JSON deserialization
  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      newTransactions: json['newTransactions'] ?? 0,
      duplicatesSkipped: json['duplicatesSkipped'] ?? 0,
      invalidMessages: json['invalidMessages'] ?? 0,
      totalProcessed: json['totalProcessed'] ?? 0,
      syncTime: DateTime.tryParse(json['syncTime'] ?? '') ?? DateTime.now(),
      syncDuration: Duration(milliseconds: json['syncDuration'] ?? 0),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // ✅ Copy with method for immutability
  SyncResult copyWith({
    bool? success,
    String? message,
    int? newTransactions,
    int? duplicatesSkipped,
    int? invalidMessages,
    int? totalProcessed,
    DateTime? syncTime,
    Duration? syncDuration,
    Map<String, dynamic>? metadata,
  }) {
    return SyncResult(
      success: success ?? this.success,
      message: message ?? this.message,
      newTransactions: newTransactions ?? this.newTransactions,
      duplicatesSkipped: duplicatesSkipped ?? this.duplicatesSkipped,
      invalidMessages: invalidMessages ?? this.invalidMessages,
      totalProcessed: totalProcessed ?? this.totalProcessed,
      syncTime: syncTime ?? this.syncTime,
      syncDuration: syncDuration ?? this.syncDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  // ✅ Equality and hashCode
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncResult &&
        other.success == success &&
        other.message == message &&
        other.newTransactions == newTransactions &&
        other.duplicatesSkipped == duplicatesSkipped &&
        other.invalidMessages == invalidMessages &&
        other.totalProcessed == totalProcessed &&
        other.syncTime == syncTime;
  }

  @override
  int get hashCode {
    return success.hashCode ^
    message.hashCode ^
    newTransactions.hashCode ^
    duplicatesSkipped.hashCode ^
    invalidMessages.hashCode ^
    totalProcessed.hashCode ^
    syncTime.hashCode;
  }

  // ✅ String representation
  @override
  String toString() {
    return 'SyncResult('
        'success: $success, '
        'message: $message, '
        'newTransactions: $newTransactions, '
        'duplicatesSkipped: $duplicatesSkipped, '
        'invalidMessages: $invalidMessages, '
        'totalProcessed: $totalProcessed, '
        'syncTime: $syncTime, '
        'syncDuration: ${syncDuration.inMilliseconds}ms'
        ')';
  }
}
