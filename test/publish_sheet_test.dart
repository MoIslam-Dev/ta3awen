import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/widgets/publish_sheet.dart';

void main() {
  testWidgets('publish sheet exposes the four intents', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => ElevatedButton(
              onPressed: () => showPublishSheet(c),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('أتبرّع بشيء'), findsOneWidget);
    expect(find.text('أتبادل شيئًا'), findsOneWidget);
    expect(find.text('أطلب شيئًا'), findsOneWidget);
    expect(find.text('أطلب دمًا (عاجل)'), findsOneWidget);
  });
}
