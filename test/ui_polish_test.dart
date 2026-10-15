import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/models/listing.dart';
import 'package:ta3awen/widgets/base64_image.dart';
import 'package:ta3awen/widgets/listing_card.dart';
import 'package:ta3awen/widgets/skeletons.dart';

Listing _listing({int imageCount = 0, String? image0}) => Listing(
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
      imageCount: imageCount,
      createdAt: DateTime(2026, 10, 1),
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('SkeletonList renders shimmering placeholder cards',
      (tester) async {
    await tester.pumpWidget(_app(const SkeletonList(count: 3)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ListingCardSkeleton), findsWidgets);
    expect(find.byType(Shimmer), findsOneWidget);
  });

  testWidgets('Request skeleton list renders request cards', (tester) async {
    await tester.pumpWidget(
      _app(const SkeletonList(kind: SkeletonKind.request, count: 2)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(RequestCardSkeleton), findsWidgets);
  });

  testWidgets('Base64Image shows a branded placeholder when empty',
      (tester) async {
    await tester.pumpWidget(
      _app(const SizedBox(
        width: 100,
        height: 100,
        child: Base64Image(data: null),
      )),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('ListingCard shows a photo-count badge for multi-photo listings',
      (tester) async {
    await tester.pumpWidget(
      _app(ListView(
        children: [ListingCard(listing: _listing(imageCount: 3))],
      )),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('ListingCard hides the badge for a single photo', (tester) async {
    await tester.pumpWidget(
      _app(ListView(
        children: [ListingCard(listing: _listing(imageCount: 1))],
      )),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.photo_library_outlined), findsNothing);
  });
}
