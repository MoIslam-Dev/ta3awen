import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('users');

  Future<void> createAppUser({
    required String uid,
    required String fullName,
    required String email,
    required String wilaya,
    required String commune,
  }) async {
    final user = AppUser(
      uid: uid,
      fullName: fullName,
      email: email,
      wilaya: wilaya,
      commune: commune,
    );
    await _col.doc(uid).set(user.toMap());
  }

  Future<AppUser?> getById(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String wilaya,
    required String commune,
    String? contactPhone,
  }) async {
    await _col.doc(uid).update({
      'fullName': fullName,
      'wilaya': wilaya,
      'commune': commune,
      'contactPhone': contactPhone,
    });
  }

  Future<List<AppUser>> getAll() async {
    final snap = await _col.get();
    return snap.docs.map(AppUser.fromDoc).toList();
  }
}
