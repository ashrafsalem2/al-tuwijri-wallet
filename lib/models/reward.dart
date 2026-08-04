class Reward {
  final String id;
  final String title;
  final int cost;
  final String description;

  const Reward({
    required this.id,
    required this.title,
    required this.cost,
    required this.description,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}
