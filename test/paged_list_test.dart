import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/services/paging.dart';
import 'package:ta3awen/state/paged_list.dart';
import 'package:ta3awen/widgets/state_views.dart';

void main() {
  group('QueryPage', () {
    test('carries items, cursor and hasMore', () {
      const page = QueryPage<int>(items: [1, 2], hasMore: true, cursor: 'c');
      expect(page.items, [1, 2]);
      expect(page.hasMore, isTrue);
      expect(page.cursor, 'c');
      expect(QueryPage.empty.items, isEmpty);
    });
  });

  group('PagedList', () {
    test('loads the live head, then appends older pages once', () async {
      final headCtrl = StreamController<QueryPage<int>>.broadcast();
      final moreCalls = <Object?>[];

      final paged = PagedList<int>(
        headBuilder: (_) => headCtrl.stream,
        moreBuilder: (cursor, _) async {
          moreCalls.add(cursor);
          return const QueryPage<int>(items: [4, 5], hasMore: false);
        },
        idOf: (x) => '$x',
      );

      paged.start();
      expect(paged.loading, isTrue);

      headCtrl.add(const QueryPage<int>(items: [1, 2, 3], cursor: 'c3', hasMore: true));
      await Future<void>.delayed(Duration.zero);

      expect(paged.loading, isFalse);
      expect(paged.items, [1, 2, 3]);
      expect(paged.hasMore, isTrue);

      await paged.loadMore();
      expect(moreCalls, ['c3']);
      expect(paged.items, [1, 2, 3, 4, 5]);
      expect(paged.hasMore, isFalse);

      // A later live-head update prepends new items and drops ones that fell
      // out of the head window (they were never latched into the tail).
      headCtrl.add(const QueryPage<int>(items: [0, 1, 2], cursor: 'c2', hasMore: true));
      await Future<void>.delayed(Duration.zero);
      expect(paged.items, [0, 1, 2, 4, 5]);

      paged.remove(2);
      expect(paged.items, [0, 1, 4, 5]);

      paged.dispose();
      await headCtrl.close();
    });

    test('de-duplicates overlapping items by identity', () async {
      final headCtrl = StreamController<QueryPage<int>>.broadcast();
      final paged = PagedList<int>(
        headBuilder: (_) => headCtrl.stream,
        moreBuilder: (_, __) async =>
            const QueryPage<int>(items: [3, 4], hasMore: false),
        idOf: (x) => '$x',
      );
      paged.start();
      headCtrl.add(
          const QueryPage<int>(items: [1, 2, 3], cursor: 'c', hasMore: true));
      await Future<void>.delayed(Duration.zero);
      await paged.loadMore();
      // 3 was already in the head; it must not appear twice.
      expect(paged.items, [1, 2, 3, 4]);
      paged.dispose();
      await headCtrl.close();
    });

    test('surfaces head errors', () async {
      final paged = PagedList<int>(
        headBuilder: (_) => Stream<QueryPage<int>>.error('boom'),
        moreBuilder: (_, __) async =>
            const QueryPage<int>(items: [], hasMore: false),
      );
      paged.start();
      await Future<void>.delayed(Duration.zero);
      expect(paged.error, 'boom');
      expect(paged.loading, isFalse);
      paged.dispose();
    });
  });

  testWidgets('LoadMoreFooter shows a button and fires onLoadMore',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LoadMoreFooter(loading: false, onLoadMore: () => taps++),
        ),
      ),
    );
    expect(find.text('المزيد'), findsOneWidget);
    await tester.tap(find.text('المزيد'));
    expect(taps, 1);
  });
}
