class PointsEntry {
  final String id;
  final String type; // "earned" | "redeemed"
  final int points;
  final DateTime date;
  final String reason;
  final String? txnId;

  const PointsEntry({
    required this.id,
    required this.type,
    required this.points,
    required this.date,
    required this.reason,
    this.txnId,
  });

  bool get isEarned => type.toLowerCase() == 'earned';

  factory PointsEntry.fromJson(Map<String, dynamic> json) {
    return PointsEntry(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'earned',
      points: (json['points'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
      reason: json['reason'] as String? ?? '',
      txnId: json['txnId'] as String?,
    );
  }
}

class PointsSummary {
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final List<PointsEntry> history;

  const PointsSummary({
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.history,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    return PointsSummary(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      totalEarned: (json['totalEarned'] as num?)?.toInt() ?? 0,
      totalRedeemed: (json['totalRedeemed'] as num?)?.toInt() ?? 0,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => PointsEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
