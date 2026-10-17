import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/models/app_notification.dart';
import 'package:ta3awen/utils/notification_labels.dart';

AppNotification _n(
  String type, {
  String actor = '',
  String? listingId,
  String? requestId,
}) =>
    AppNotification(
      id: 'n1',
      type: type,
      actorName: actor,
      listingId: listingId,
      requestId: requestId,
    );

Future<NotificationVisual> _visual(
  WidgetTester tester,
  AppNotification n,
) async {
  NotificationVisual? v;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          v = notificationVisual(context, n);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return v!;
}

void main() {
  group('AppNotification.fromRow', () {
    test('parses fields, references and unread state', () {
      final n = AppNotification.fromRow({
        'id': 'a',
        'type': notifyListingClaimed,
        'actor_name': 'سامي',
        'listing_id': 'L1',
        'request_id': null,
        'read_at': null,
        'created_at': '2026-01-02T03:04:05.000Z',
      });
      expect(n.id, 'a');
      expect(n.type, notifyListingClaimed);
      expect(n.actorName, 'سامي');
      expect(n.listingId, 'L1');
      expect(n.requestId, isNull);
      expect(n.isUnread, isTrue);
      expect(n.isListing, isTrue);
      expect(n.isRequest, isFalse);
      expect(n.createdAt!.toUtc().year, 2026);
    });

    test('a read row is not unread; asRead stamps readAt', () {
      final n = AppNotification.fromRow({
        'id': 'a',
        'type': notifyReportNew,
        'read_at': '2026-01-02T03:04:05Z',
      });
      expect(n.isUnread, isFalse);
      final m = n.asRead(DateTime.utc(2026, 2, 3));
      expect(m.isUnread, isFalse);
      expect(m.readAt, isNotNull);
      expect(m.id, n.id);
    });

    test('request reference is recognised', () {
      final n = AppNotification.fromRow(
        {'id': 'a', 'type': notifyBloodMatched, 'request_id': 'R9'},
      );
      expect(n.isRequest, isTrue);
      expect(n.isListing, isFalse);
    });
  });

  group('notificationVisual', () {
    testWidgets('listing_claimed uses the actor name', (tester) async {
      final v = await _visual(tester, _n(notifyListingClaimed, actor: 'سامي'));
      expect(v.title, 'تم حجز إعلانك');
      expect(v.body, contains('سامي'));
    });

    testWidgets('request_matched body carries the actor', (tester) async {
      final v = await _visual(tester, _n(notifyRequestMatched, actor: 'ليلى'));
      expect(v.title, 'وجد أحدهم ما تحتاجه');
      expect(v.body, contains('ليلى'));
    });

    testWidgets('blood_matched is its own wording', (tester) async {
      final v = await _visual(tester, _n(notifyBloodMatched, actor: 'كريم'));
      expect(v.title, 'متبرع متاح');
      expect(v.body, contains('كريم'));
    });

    testWidgets('missing actor falls back to a generic name', (tester) async {
      final v = await _visual(tester, _n(notifyListingReleased, actor: ''));
      expect(v.body, contains('أحد المستخدمين'));
    });

    testWidgets('unknown type falls back to the generic title',
        (tester) async {
      final v = await _visual(tester, _n('something_else', actor: 'x'));
      expect(v.title, 'الإشعارات');
    });

    testWidgets('every known type renders a non-empty title and body',
        (tester) async {
      const types = [
        notifyListingClaimed,
        notifyListingReleased,
        notifyListingGiven,
        notifyRequestMatched,
        notifyBloodMatched,
        notifyRequestReleased,
        notifyRequestClosed,
        notifyReportNew,
      ];
      for (final t in types) {
        final v = await _visual(tester, _n(t, actor: 'سامي'));
        expect(v.title, isNotEmpty, reason: t);
        expect(v.body, isNotEmpty, reason: t);
      }
    });
  });
}
