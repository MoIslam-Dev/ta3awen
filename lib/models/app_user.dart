import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      fullName: (d['fullName'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      wilaya: (d['wilaya'] ?? '') as String,
      commune: (d['commune'] ?? '') as String,
      contactPhone: d['contactPhone'] as String?,
      disabled: (d['disabled'] ?? false) as bool,
      disabledReason: d['disabledReason'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'email': email,
        'wilaya': wilaya,
        'commune': commune,
        'contactPhone': contactPhone,
        'disabled': disabled,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
