import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/models/request_post.dart';
import 'package:ta3awen/utils/request_filters.dart';

RequestPost _post({
  String id = 'r1',
  String type = requestTypeNeed,
  String kind = requestKindGeneral,
  String? bloodType,
  String wilaya = 'الجزائر',
  String commune = 'باب الزوار',
  String title = 'عنوان',
  String category = 'كتب',
}) =>
    RequestPost(
      id: id,
      uid: 'u',
      userName: 'مستخدم',
      type: type,
      title: title,
      description: 'وصف يشرح المحتوى',
      category: category,
      wilaya: wilaya,
      commune: commune,
      contactPhone: '0550000000',
      kind: kind,
      bloodType: bloodType,
    );

void main() {
  final need = _post(id: 'need', title: 'أبحث عن كتاب');
  final offer =
      _post(id: 'offer', type: requestTypeOffer, title: 'أقدم سريرا');
  final blood =
      _post(id: 'blood', kind: requestKindBlood, bloodType: 'O+',
          title: 'أحتاج دم O+');

  group('filterRequests board separation', () {
    test('general board never mixes blood posts', () {
      final out = filterRequests([need, offer, blood]);
      expect(out.map((r) => r.id), ['need', 'offer']);
    });

    test('need filter keeps needs only and still excludes blood', () {
      final out = filterRequests([need, offer, blood], typeFilter: 'need');
      expect(out.map((r) => r.id), ['need']);
    });

    test('offer filter keeps offers only', () {
      final out = filterRequests([need, offer, blood], typeFilter: 'offer');
      expect(out.map((r) => r.id), ['offer']);
    });

    test('blood board keeps blood posts only', () {
      final out = filterRequests([need, offer, blood],
          bloodSeparation: true, bloodBoard: true);
      expect(out.map((r) => r.id), ['blood']);
    });

    test('blood board narrows by blood type', () {
      final other =
          _post(id: 'other', kind: requestKindBlood, bloodType: 'A-');
      final out = filterRequests([blood, other],
          bloodSeparation: true, bloodBoard: true, bloodTypeFilter: 'O+');
      expect(out.map((r) => r.id), ['blood']);
    });

    test('own requests list shows everything owned (no separation)', () {
      final out = filterRequests([need, offer, blood], bloodSeparation: false);
      expect(out.map((r) => r.id), ['need', 'offer', 'blood']);
    });
  });

  group('filterRequests search', () {
    test('matches title', () {
      final out = filterRequests([need, offer, blood], query: 'كتاب');
      expect(out.map((r) => r.id), ['need']);
    });

    test('matches blood type "O+"', () {
      final out = filterRequests([need, offer, blood],
          bloodBoard: true, query: 'O+');
      expect(out.map((r) => r.id), ['blood']);
    });

    test('matches wilaya and commune', () {
      final out = filterRequests([need], query: 'باب الزوار');
      expect(out.map((r) => r.id), ['need']);
    });

    test('search is case-insensitive for latin blood types', () {
      final out = filterRequests([blood], bloodBoard: true, query: 'o+');
      expect(out.map((r) => r.id), ['blood']);
    });

    test('query is trimmed', () {
      final out =
          filterRequests([blood], bloodBoard: true, query: '  o+  ');
      expect(out.map((r) => r.id), ['blood']);
    });
  });

  group('filterRequests location', () {
    final tipaza = _post(
        id: 'tip',
        wilaya: 'تيبازة',
        commune: 'حجوط',
        title: 'طلب في تيبازة');
    final algiers = _post(
        id: 'alg', wilaya: 'الجزائر', commune: 'باب الوادي', title: 'أخرى');

    test('filters by wilaya', () {
      final out = filterRequests([tipaza, algiers], wilaya: 'تيبازة');
      expect(out.map((r) => r.id), ['tip']);
    });

    test('filters by commune only within the chosen wilaya', () {
      final out = filterRequests([tipaza, algiers], commune: 'حجوط');
      expect(out.map((r) => r.id), ['tip']);
    });

    test('combines wilaya and commune', () {
      final out = filterRequests([tipaza, algiers],
          wilaya: 'الجزائر', commune: 'باب الوادي');
      expect(out.map((r) => r.id), ['alg']);
    });
  });

  group('filterRequests combined', () {
    test('need + wilaya + query together', () {
      final src = [
        _post(id: 'a', type: requestTypeNeed, wilaya: 'الجزائر', title: 'سرير'),
        _post(
            id: 'b', type: requestTypeNeed, wilaya: 'تيبازة', title: 'سرير'),
        _post(id: 'c', type: requestTypeOffer, wilaya: 'الجزائر', title: 'سرير'),
      ];
      final out = filterRequests(src,
          typeFilter: requestTypeNeed, wilaya: 'الجزائر', query: 'سرير');
      expect(out.map((r) => r.id), ['a']);
    });
  });
}