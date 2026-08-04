/// A single line item inside a transaction's detail.
class TransactionItem {
  final String name;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  const TransactionItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      name: json['name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Summary shown in the transactions list.
class SalesTransaction {
  final String id;
  final DateTime date;
  final String branch;
  final double total;
  final String currency;
  final int pointsEarned;
  final String paymentMethod;
  final String status;
  final int itemsCount;

  const SalesTransaction({
    required this.id,
    required this.date,
    required this.branch,
    required this.total,
    required this.currency,
    required this.pointsEarned,
    required this.paymentMethod,
    required this.status,
    required this.itemsCount,
  });

  factory SalesTransaction.fromJson(Map<String, dynamic> json) {
    return SalesTransaction(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
      branch: json['branch'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'SAR',
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? '',
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isRefunded => status.toLowerCase() == 'refunded';
}

/// Full detail shown on the transaction detail page.
class TransactionDetail {
  final String id;
  final DateTime date;
  final String branch;
  final String cashier;
  final String status;
  final String currency;
  final String paymentMethod;
  final int pointsEarned;
  final List<TransactionItem> items;
  final double subtotal;
  final double discount;
  final double vat;
  final double total;

  const TransactionDetail({
    required this.id,
    required this.date,
    required this.branch,
    required this.cashier,
    required this.status,
    required this.currency,
    required this.paymentMethod,
    required this.pointsEarned,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.vat,
    required this.total,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
      branch: json['branch'] as String? ?? '',
      cashier: json['cashier'] as String? ?? '',
      status: json['status'] as String? ?? '',
      currency: json['currency'] as String? ?? 'SAR',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isRefunded => status.toLowerCase() == 'refunded';
}
