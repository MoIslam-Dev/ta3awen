import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/models/request_post.dart';
import 'package:ta3awen/utils/labels.dart';

RequestPost _post({
  String type = requestTypeNeed,
  String kind = requestKindGeneral,
  bool hasBloodType = false,
}) =>
    RequestPost(
      id: 'x',
      uid: 'u',
      userName: 'مستخدم',
      type: type,
      title: 'عنوان',
      description: 'وصف',
      category: 'كتب',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      kind: kind,
      bloodType: hasBloodType ? 'O+' : null,
    );

Future<String> _helpLabel(WidgetTester tester, RequestPost post) async {
  String? label;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          label = requestMatchHelpLabel(context, post);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return label!;
}

void main() {
  group('requestMatchIntent', () {
    test('need -> need', () {
      expect(requestMatchIntent(_post(type: requestTypeNeed)),
          RequestMatchIntent.need);
    });

    test('offer -> offer', () {
      expect(requestMatchIntent(_post(type: requestTypeOffer)),
          RequestMatchIntent.offer);
    });

    test('blood (any type) -> blood', () {
      expect(
        requestMatchIntent(
          _post(type: requestTypeNeed, kind: requestKindBlood, hasBloodType: true),
        ),
        RequestMatchIntent.blood,
      );
      expect(
        requestMatchIntent(
          _post(type: requestTypeOffer, kind: requestKindBlood, hasBloodType: true),
        ),
        RequestMatchIntent.blood,
      );
    });
  });

  group('requestMatchHelpLabel', () {
    testWidgets('need asks for help', (tester) async {
      expect(
        await _helpLabel(tester, _post(type: requestTypeNeed)),
        'أستطيع المساعدة',
      );
    });

    testWidgets('offer asks for the item', (tester) async {
      expect(
        await _helpLabel(tester, _post(type: requestTypeOffer)),
        'أريد هذا',
      );
    });

    testWidgets('blood asks to donate', (tester) async {
      expect(
        await _helpLabel(
          tester,
          _post(type: requestTypeNeed, kind: requestKindBlood, hasBloodType: true),
        ),
        'أستطيع التبرع',
      );
    });
  });
}