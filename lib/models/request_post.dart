/// A post on the community board: either something the author needs
/// (`need`) or something they can provide (`offer`). Matching connects
/// the two sides; the board itself holds no images.
class RequestPost {
  final String id;
  final String uid;
  final String userName;
  final String type;
  final String title;
  final String description;
  final String category;
  final String wilaya;
  final String commune;
  final String? contactPhone;
  final String status;

  /// 'general' (default) or 'blood' — blood posts are always type need
  /// and carry a valid [bloodType].
  final String kind;
  final String? bloodType;

  final String? matchedBy;
  final String? matchedName;
  final DateTime? matchedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RequestPost({
    required this.id,
    required this.uid,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.wilaya,
    required this.commune,
    this.contactPhone,
    this.status = requestStatusOpen,
    this.kind = requestKindGeneral,
    this.bloodType,
    this.matchedBy,
    this.matchedName,
    this.matchedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status == requestStatusOpen;

  bool get isMatched => status == requestStatusMatched;

  bool get isClosed => status == requestStatusClosed;

  bool get isBlood => kind == requestKindBlood;

  factory RequestPost.fromRow(Map<String, dynamic> r) {
    return RequestPost(
      id: r['id'] as String,
      uid: (r['uid'] ?? '') as String,
      userName: (r['user_name'] ?? '') as String,
      type: (r['type'] ?? requestTypeNeed) as String,
      title: (r['title'] ?? '') as String,
      description: (r['description'] ?? '') as String,
      category: (r['category'] ?? '') as String,
      wilaya: (r['wilaya'] ?? '') as String,
      commune: (r['commune'] ?? '') as String,
      contactPhone: r['contact_phone'] as String?,
      status: (r['status'] ?? requestStatusOpen) as String,
      kind: (r['kind'] ?? requestKindGeneral) as String,
      bloodType: r['blood_type'] as String?,
      matchedBy: r['matched_by'] as String?,
      matchedName: r['matched_name'] as String?,
      matchedAt: _dt(r['matched_at']),
      createdAt: _dt(r['created_at']),
      updatedAt: _dt(r['updated_at']),
    );
  }

  /// Insert payload: new posts always start [requestStatusOpen]; match keys are
  /// deliberately absent (the DB trigger owns them).
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'user_name': userName,
        'type': type,
        'title': title,
        'description': description,
        'category': category,
        'wilaya': wilaya,
        'commune': commune,
        'contact_phone': contactPhone,
        'status': requestStatusOpen,
        'kind': kind,
        'blood_type': bloodType,
      };
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

const String requestStatusOpen = 'open';
const String requestStatusMatched = 'matched';
const String requestStatusClosed = 'closed';

const String requestTypeNeed = 'need';
const String requestTypeOffer = 'offer';

const String requestKindGeneral = 'general';
const String requestKindBlood = 'blood';
