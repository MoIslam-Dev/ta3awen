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
    expect(statusGiven, 'تم التبرع به');
  });
}
