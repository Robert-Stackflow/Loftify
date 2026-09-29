import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/tab_state_util.dart';

void main() {
  test('saved tab index restores only while it remains valid', () {
    expect(TabStatePreference.restoreIndex(2, 4), 2);
    expect(TabStatePreference.restoreIndex(-1, 4), 0);
    expect(TabStatePreference.restoreIndex(9, 4), 0);
    expect(
      TabStatePreference.restoreIndex(9, 4, fallbackIndex: 1),
      1,
    );
    expect(TabStatePreference.restoreIndex(1, 0), 0);
  });

  test('lazy tab loading does not repeat a request for a loaded tab', () {
    final state = LazyTabLoadState(itemCount: 6, savedIndex: 4);

    expect(state.currentIndex, 4);
    expect(state.selectAndShouldLoad(4), isTrue);
    expect(state.selectAndShouldLoad(4), isFalse);
    expect(state.selectAndShouldLoad(2), isTrue);
    expect(state.selectAndShouldLoad(4), isFalse);
  });

  test('stable tab id restores the same source after tabs are reordered', () {
    final resolution = TabStatePreference.resolve(
      itemIds: const ['grain', 'all', 'tag', 'collection'],
      savedId: 'collection',
      legacySavedIndex: 2,
    );

    expect(resolution.index, 3);
    expect(resolution.id, 'collection');
    expect(resolution.usedFallback, isFalse);
    expect(resolution.migratedLegacyIndex, isFalse);
  });

  test('unknown stable id safely falls back instead of trusting stale index',
      () {
    final resolution = TabStatePreference.resolve(
      itemIds: const ['all', 'article', 'user'],
      savedId: 'removed-source',
      legacySavedIndex: 2,
      fallbackId: 'all',
    );

    expect(resolution.index, 0);
    expect(resolution.id, 'all');
    expect(resolution.usedFallback, isTrue);
    expect(resolution.migratedLegacyIndex, isFalse);
  });

  test('legacy numeric preference migrates only when no stable id exists', () {
    final resolution = TabStatePreference.resolve(
      itemIds: const ['all', 'tag', 'article'],
      legacySavedIndex: 2,
    );

    expect(resolution.index, 2);
    expect(resolution.id, 'article');
    expect(resolution.migratedLegacyIndex, isTrue);
  });

  test('page lifecycle policy persists selection but not response or scroll',
      () {
    const policy = TabStateRetentionPolicy.userFacingTabs;

    expect(policy.selectionAcrossRestart, isTrue);
    expect(policy.loadedDataAcrossRestart, isFalse);
    expect(policy.scrollOffsetAcrossRestart, isFalse);
  });

  test('failed lazy request is retryable without duplicating successful tabs',
      () {
    final state = LazyTabLoadState(
      itemIds: const ['all', 'tag'],
      savedId: 'tag',
    );

    expect(state.selectAndShouldLoad(1), isTrue);
    state.markLoadFailed(1);
    expect(state.selectAndShouldLoad(1), isTrue);
    expect(state.selectAndShouldLoad(1), isFalse);
  });

  test('new data source clears load markers and can return to default tab', () {
    final state = LazyTabLoadState(itemCount: 6, savedIndex: 5);
    state.selectAndShouldLoad(5);

    state.reset(index: 0);

    expect(state.currentIndex, 0);
    expect(state.isCurrentLoaded, isFalse);
    expect(state.selectAndShouldLoad(0), isTrue);
  });
}
