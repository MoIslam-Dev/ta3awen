class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String wilaya;
  final String commune;
  final String? contactPhone;
  final bool disabled;
  final String? disabledReason;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.wilaya,
    required this.commune,
    this.contactPhone,
    this.disabled = false,
    this.disabledReason,
    this.createdAt,
  });

  factory AppUser.fromRow(Map<String, dynamic> r) {
    return AppUser(
      uid: r['id'] as String,
      fullName: (r['full_name'] ?? '') as String,
      email: (r['email'] ?? '') as String,
      wilaya: (r['wilaya'] ?? '') as String,
      commune: (r['commune'] ?? '') as String,
      contactPhone: r['contact_phone'] as String?,
      disabled: (r['disabled'] ?? false) as bool,
      disabledReason: r['disabled_reason'] as String?,
      createdAt: _dt(r['created_at']),
    );
  }

  /// Profile insert payload (`public.profiles`). `disabled`/`post_count` are
  /// server-owned and intentionally absent.
  Map<String, dynamic> toMap() => {
        'id': uid,
        'full_name': fullName,
        'email': email,
        'wilaya': wilaya,
        'commune': commune,
      };
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}
