import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/models/request_post.dart';
import 'package:ta3awen/utils/constants.dart';
import 'package:ta3awen/utils/request_kind.dart';

void main() {
  group('applyRequestKindSwitch', () {
    test('switching to blood locks need, fixes category, clears blood type',
        () {
      final out = applyRequestKindSwitch(
        requestKindBlood,
        previousType: requestTypeOffer,
        previousCategory: 'ملابس',
      );
      expect(out.kind, requestKindBlood);
      expect(out.type, requestTypeNeed);
      expect(out.category, kBloodCategory);
      expect(out.bloodType, isNull);
    });

    test('switching to general keeps the previous type', () {
      final out = applyRequestKindSwitch(
        requestKindGeneral,
        previousType: requestTypeOffer,
        previousCategory: kBloodCategory,
      );
      expect(out.kind, requestKindGeneral);
      expect(out.type, requestTypeOffer);
      expect(out.category, kCategories.first);
      expect(out.bloodType, isNull);
    });

    test('switching to general preserves a normal category', () {
      final out = applyRequestKindSwitch(
        requestKindGeneral,
        previousType: requestTypeNeed,
        previousCategory: 'كتب',
      );
      expect(out.category, 'كتب');
    });

    test('stays consistent when already on blood', () {
      final out = applyRequestKindSwitch(
        requestKindBlood,
        previousType: requestTypeNeed,
        previousCategory: kBloodCategory,
      );
      expect(out.type, requestTypeNeed);
      expect(out.category, kBloodCategory);
    });
  });
}