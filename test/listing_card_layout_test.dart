import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/models/listing.dart';
import 'package:ta3awen/widgets/listing_card.dart';

// 1x1 px transparent PNG
const String _tinyPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Listing _listing({String? image0}) => Listing(
      id: 'x',
      ownerId: 'u',
      ownerName: 'مستخدم',
      title: 'قميص قطني',
      description: 'وصف',
      category: 'ملابس',
      wilaya: 'الجزائر',
      commune: 'باب الزوار',
      condition: 'جديد',
      status: 'متاح',
      image0: image0,
      createdAt: DateTime(2026, 10, 1),
    );

Future<void> _pumpCard(WidgetTester tester, Listing listing) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(
          children: [ListingCard(listing: listing)],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ListingCard renders without image', (tester) async {
    await _pumpCard(tester, _listing());
    expect(tester.takeException(), isNull);
    expect(find.text('قميص قطني'), findsOneWidget);
  });

  testWidgets('ListingCard renders with image', (tester) async {
    await _pumpCard(tester, _listing(image0: _tinyPng));
    expect(tester.takeException(), isNull);
    expect(find.text('قميص قطني'), findsOneWidget);
  });
}
