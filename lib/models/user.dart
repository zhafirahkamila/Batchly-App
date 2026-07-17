class User {
  final int id;
  final String name;
  final String email;
  final String? businessName;
  final bool isPremium;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.businessName,
    this.isPremium = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      businessName: json['business_name'] as String?,
      isPremium: _parseBool(json['is_premium']),
    );
  }

  /// Guest placeholder — never persisted, never sent to the backend.
  factory User.guest() => User(id: -1, name: 'Guest', email: 'guest@batchly.local');

  bool get isGuest => id == -1;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
