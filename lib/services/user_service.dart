import '../core/supabase.dart';
import '../models/app_user.dart';

class UserService {
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
    // 1) INSERT ... ON CONFLICT DO NOTHING: never needs the (deliberately
    //    restricted) UPDATE privilege, and covers the case where the DB trigger
    //    has not seeded the row yet.
    await supabase
        .from('profiles')
        .upsert(user.toMap(), ignoreDuplicates: true);
    // 2) Apply the user-entered fields. Only the four editable columns are
    //    writable by an authenticated user (`email`/`id` are server-owned).
    await supabase.from('profiles').update({
      'full_name': fullName,
      'wilaya': wilaya,
      'commune': commune,
    }).eq('id', uid);
  }

  Future<AppUser?> getById(String uid) async {
    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return AppUser.fromRow(row);
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String wilaya,
    required String commune,
    String? contactPhone,
  }) async {
    await supabase.from('profiles').update({
      'full_name': fullName,
      'wilaya': wilaya,
      'commune': commune,
      'contact_phone': contactPhone,
    }).eq('id', uid);
  }

  Future<List<AppUser>> getAll() async {
    final rows = await supabase.from('profiles').select();
    return (rows as List)
        .map((e) => AppUser.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
