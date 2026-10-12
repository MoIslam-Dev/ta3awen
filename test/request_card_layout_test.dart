import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/models/request_post.dart';
import 'package:ta3awen/widgets/request_card.dart';

RequestPost _post({
  String type = requestTypeNeed,
  String kind = requestKindGeneral,
  String? bloodType,
}) =>
    RequestPost(
      id: 'x',
      uid: 'u',
      userName: 'مستخدم',
      type: type,
      title: 'سرير قابل للطي',
      description: 'في حالة جيدة',
      category: 'أثاث',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      kind: kind,
      bloodType: bloodType,
      createdAt: DateTime(2026, 10, 1),
    );

Future<void> _pumpCard(WidgetTester tester, RequestPost request) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(children: [RequestCard(request: request)]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offer card labels the post "أقدّم"', (tester) async {
    await _pumpCard(tester, _post(type: requestTypeOffer));
    expect(tester.takeException(), isNull);
    expect(find.text('أقدّم'), findsOneWidget);
  });

  testWidgets('need card labels the post "أحتاج"', (tester) async {
    await _pumpCard(tester, _post(type: requestTypeNeed));
    expect(tester.takeException(), isNull);
    expect(find.text('أحتاج'), findsOneWidget);
  });

  testWidgets('blood card shows the blood type alongside the category',
      (tester) async {
    await _pumpCard(
      tester,
      _post(type: requestTypeNeed, kind: requestKindBlood, bloodType: 'O+'),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('O+'), findsOneWidget);
  });
}