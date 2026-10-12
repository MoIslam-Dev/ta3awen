import '../models/request_post.dart';

/// Client-side filtering for the requests board and the user's own list.
///
/// The rules that decide which posts are shown are centralized here so they
/// can be unit-tested and shared by the UI. Filtering runs in memory over an
/// already-open snapshot (`status == open` for the board), so no extra
/// Firestore indexes are required.
///
/// General/need/offer views never mix blood posts and the blood board never
/// mixes general posts ([bloodSeparation]). When browsing one's own requests
/// ([bloodSeparation] = false) type/kind filters are not applied — the user's
/// list shows every post they own regardless of board state.
List<RequestPost> filterRequests(
  List<RequestPost> source, {
  bool bloodSeparation = true,
  bool bloodBoard = false,
  String? typeFilter,
  String? bloodTypeFilter,
  String? wilaya,
  String? commune,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return source.where((r) {
    if (bloodSeparation) {
      if (bloodBoard && !r.isBlood) return false;
      if (!bloodBoard && r.isBlood) return false;
    }
    if (typeFilter != null && r.type != typeFilter) return false;
    if (bloodBoard &&
        bloodTypeFilter != null &&
        r.bloodType != bloodTypeFilter) {
      return false;
    }
    if (wilaya != null && r.wilaya != wilaya) return false;
    if (commune != null && r.commune != commune) return false;
    if (q.isNotEmpty) {
      final hay = <String>[
        r.title,
        r.description,
        r.category,
        r.wilaya,
        r.commune,
        r.kind,
        if (r.bloodType != null) r.bloodType!,
      ].join(' ').toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }).toList();
}