class Customer {
  final String customerId;
  final String name;
  final String mobile;
  final String email;
  final int points;
  final String tier;
  final String memberSince;

  const Customer({
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.email,
    required this.points,
    required this.tier,
    required this.memberSince,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? '',
      memberSince: json['memberSince'] as String? ?? '',
    );
  }

  /// First name only — handy for greetings.
  String get firstName => name.split(' ').first;

  Customer copyWith({String? name, String? email, int? points}) => Customer(
        customerId: customerId,
        name: name ?? this.name,
        mobile: mobile,
        email: email ?? this.email,
        points: points ?? this.points,
        tier: tier,
        memberSince: memberSince,
      );
}
