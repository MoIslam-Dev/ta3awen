import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/data/algeria_data.dart';
import 'package:ta3awen/utils/constants.dart';
import 'package:ta3awen/models/listing.dart';

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
}
