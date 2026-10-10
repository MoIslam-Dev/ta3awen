import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/data/algeria_data.dart';
import 'package:ta3awen/utils/constants.dart';
import 'package:ta3awen/models/listing.dart';
import 'package:ta3awen/models/request_post.dart';

void main() {
  test('Algeria data contains 58 wilayas with communes', () {
    expect(AlgeriaData.wilayas.length, 58);
    expect(AlgeriaData.communesOf('الجزائر').isNotEmpty, true);
    expect(AlgeriaData.communesOf('ولاية غير موجودة'), isEmpty);
  });

  test('categories and conditions match the MVP spec', () {
    expect(kCategories.length, 10);
    expect(kCategories.first, 'ملابس');
    expect(kConditions, ['جديد', 'جيد جداً', 'جيد', 'مستعمل']);
  });

  test('listing status constants', () {
    expect(statusAvailable, 'متاح');
    expect(statusReserved, 'محجوز');
    expect(statusGiven, 'تم التبرع به');
  });

  test('reservation flags and claim fields', () {
    const base = Listing(
      id: 'L1',
      ownerId: 'alice',
      ownerName: 'User alice',
      title: 'Chaise',
      description: 'desc',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      condition: 'جيد',
      status: statusAvailable,
    );
    expect(base.isAvailable, true);
    expect(base.isReserved, false);
    expect(base.claimedBy, isNull);

    const reserved = Listing(
      id: 'L1',
      ownerId: 'alice',
      ownerName: 'User alice',
      title: 'Chaise',
      description: 'desc',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      condition: 'جيد',
      status: statusReserved,
      claimedBy: 'bob',
      claimedByName: 'User bob',
    );
    expect(reserved.isAvailable, false);
    expect(reserved.isReserved, true);
    expect(reserved.claimedBy, 'bob');
  });

  test('toMap never plants claim fields (create rule rejects them)', () {
    const listing = Listing(
      id: 'L1',
      ownerId: 'alice',
      ownerName: 'User alice',
      title: 'Chaise',
      description: 'desc',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      condition: 'جيد',
      status: statusReserved,
      claimedBy: 'bob',
    );
    final map = listing.toMap();
    expect(map.containsKey('claimedBy'), false);
    expect(map.containsKey('claimedByName'), false);
    expect(map.containsKey('claimedAt'), false);
    expect(map['status'], statusReserved);
  });

  test('request status and type constants', () {
    expect(requestStatusOpen, 'open');
    expect(requestStatusMatched, 'matched');
    expect(requestStatusClosed, 'closed');
    expect(requestTypeNeed, 'need');
    expect(requestTypeOffer, 'offer');
  });

  test('request status flags', () {
    const base = RequestPost(
      id: 'R1',
      uid: 'alice',
      userName: 'User alice',
      type: requestTypeNeed,
      title: 'Fauteuil',
      description: 'desc',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
    );
    expect(base.isOpen, true);
    expect(base.isMatched, false);
    expect(base.isClosed, false);
    expect(base.status, requestStatusOpen);

    const matched = RequestPost(
      id: 'R1',
      uid: 'alice',
      userName: 'User alice',
      type: requestTypeNeed,
      title: 'Fauteuil',
      description: 'desc',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      status: requestStatusMatched,
      matchedBy: 'bob',
      matchedName: 'User bob',
    );
    expect(matched.isMatched, true);
    expect(matched.matchedBy, 'bob');

    const closed = RequestPost(
      id: 'R1',
      uid: 'alice',
      userName: 'User alice',
      type: requestTypeOffer,
      title: 'Livres',
      description: 'desc',
      category: 'كتب',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      status: requestStatusClosed,
    );
    expect(closed.isClosed, true);
    expect(closed.isOpen, false);
  });

  test('request toMap never plants match fields (create rule rejects them)',
      () {
    const request = RequestPost(
      id: 'R1',
      uid: 'alice',
      userName: 'User alice',
      type: requestTypeNeed,
      title: 'Fauteuil',
      description: 'Un fauteuil pour une personne âgée',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      status: requestStatusMatched,
      matchedBy: 'bob',
      matchedName: 'User bob',
    );
    final map = request.toMap();
    expect(map.containsKey('matchedBy'), false);
    expect(map.containsKey('matchedName'), false);
    expect(map.containsKey('matchedAt'), false);
    expect(map['status'], requestStatusOpen,
        reason: 'create always starts open');
    expect((map['keywords'] as List).isNotEmpty, true);
  });
}
