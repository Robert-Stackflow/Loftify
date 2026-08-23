import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/paged_data_controller.dart';

void main() {
  group('PagedDataController', () {
    test('refresh replaces items and adjacent pages are deduplicated',
        () async {
      final controller = PagedDataController<int, int, int, String>(
        initialCursor: 0,
        keyOf: (item) => item,
        loader: (cursor, refresh) async => PagedDataPage(
          items: cursor == 0 ? const [1, 2] : const [2, 3],
          nextCursor: cursor + 2,
          hasMore: cursor == 0,
          total: 3,
          metadata: refresh ? 'latest' : null,
        ),
      );

      expect(await controller.refresh(), IndicatorResult.success);
      expect(await controller.load(), IndicatorResult.noMore);
      expect(controller.items, [1, 2, 3]);
      expect(controller.metadata, 'latest');

      await controller.refresh();
      expect(controller.items, [1, 2]);
      controller.dispose();
    });

    test('failed page does not advance the committed cursor', () async {
      var shouldFail = true;
      final controller = PagedDataController<int, int, int, void>(
        initialCursor: 0,
        keyOf: (item) => item,
        loader: (cursor, refresh) async {
          if (shouldFail) throw StateError('network');
          return PagedDataPage(
            items: [cursor + 1],
            nextCursor: cursor + 1,
            hasMore: true,
          );
        },
      );

      expect(await controller.load(), IndicatorResult.fail);
      expect(controller.cursor, 0);
      shouldFail = false;
      expect(await controller.load(), IndicatorResult.success);
      expect(controller.cursor, 1);
      controller.dispose();
    });

    test('local removals keep total and no-more state in sync', () async {
      final controller = PagedDataController<int, int, int, void>(
        initialCursor: 0,
        keyOf: (item) => item,
        loader: (cursor, refresh) async => const PagedDataPage(
          items: [1, 2],
          nextCursor: 2,
          hasMore: false,
          total: 2,
        ),
      );

      await controller.refresh();
      expect(
        controller.removeWhere(
          (item) => item == 1,
          updateCursor: (cursor, removedCount) => cursor - removedCount,
        ),
        1,
      );
      expect(controller.items, [2]);
      expect(controller.total, 1);
      expect(controller.cursor, 1);
      expect(controller.noMore, isTrue);
      controller.dispose();
    });

    test('reset invalidates an in-flight page before starting a new source',
        () async {
      final firstPage = Completer<PagedDataPage<int, int, void>>();
      var calls = 0;
      final controller = PagedDataController<int, int, int, void>(
        initialCursor: 0,
        keyOf: (item) => item,
        loader: (cursor, refresh) {
          calls++;
          if (calls == 1) return firstPage.future;
          return Future.value(
            const PagedDataPage(
              items: [2],
              nextCursor: 1,
              hasMore: false,
            ),
          );
        },
      );

      final staleRequest = controller.refresh();
      controller.reset();
      expect(await controller.refresh(), IndicatorResult.success);
      firstPage.complete(
        const PagedDataPage(
          items: [1],
          nextCursor: 1,
          hasMore: false,
        ),
      );
      expect(await staleRequest, IndicatorResult.none);
      expect(controller.items, [2]);
      controller.dispose();
    });

    test('item parser isolates one malformed payload', () {
      final errors = <Object>[];
      final result = parsePagedDataItems<int>(
        [
          {'value': 1},
          {'bad': true},
          {'value': 2},
        ],
        (json) => json['value'] as int,
        onMalformed: (error, _) => errors.add(error),
      );

      expect(result, [1, 2]);
      expect(errors, hasLength(1));
    });

    test('metadata merger accumulates auxiliary page content', () async {
      final controller = PagedDataController<int, int, int, List<int>>(
        initialCursor: 0,
        keyOf: (item) => item,
        loader: (cursor, refresh) async => PagedDataPage(
          items: [cursor],
          nextCursor: cursor + 1,
          hasMore: cursor == 0,
          metadata: [cursor + 10],
        ),
        metadataMerger: (current, incoming, refresh) => [
          ...?current,
          ...?incoming,
        ],
      );

      await controller.refresh();
      await controller.load();
      expect(controller.metadata, [10, 11]);
      controller.dispose();
    });
  });
}
