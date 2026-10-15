import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/models/listing.dart';
import 'package:ta3awen/utils/labels.dart';
import 'package:ta3awen/widgets/listing_card.dart';

Listing _listing({String kind = listingKindDonation}) => Listing(
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
      kind: kind,
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  group('Listing kind (donation vs exchange)', () {
    test('defaults to donation', () {
      expect(_listing().kind, listingKindDonation);
      expect(_listing().isExchange, isFalse);
    });

    test('detects exchange', () {
      expect(_listing(kind: listingKindExchange).isExchange, isTrue);
    });

    test('toMap persists the kind', () {
      expect(
        _listing(kind: listingKindExchange).toMap()['kind'],
        listingKindExchange,
      );
      expect(_listing().toMap()['kind'], listingKindDonation);
    });
  });

  testWidgets('listingKindLabel is localized (ar)', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(listingKindLabel(ctx, listingKindDonation), 'تبرّع');
    expect(listingKindLabel(ctx, listingKindExchange), 'تبادل');
  });

  testWidgets('ListingCard shows the exchange badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [_listingCard(listingKindExchange)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تبادل'), findsOneWidget);
  });

  testWidgets('ListingCard shows the donation badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [_listingCard(listingKindDonation)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تبرّع'), findsOneWidget);
  });
}

Widget _listingCard(String kind) => ListingCard(listing: _listing(kind: kind));
