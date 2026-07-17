class Overhead {
  final int id;
  final String name;
  final double amount;
  final String period; // 'per_bulan' | 'per_batch'

  Overhead({
    required this.id,
    required this.name,
    required this.amount,
    required this.period,
  });

  factory Overhead.fromJson(Map<String, dynamic> json) {
    return Overhead(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      amount: _num(json['amount']),
      period: (json['period'] ?? 'per_bulan') as String,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'amount': amount,
        'period': period,
      };
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
