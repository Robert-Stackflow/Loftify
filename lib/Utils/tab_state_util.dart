import 'package:awesome_chewie/awesome_chewie.dart';

/// Tab selection is a durable user preference, while loaded response objects
/// and scroll offsets intentionally remain page-lifetime state.
class TabStateRetentionPolicy {
  const TabStateRetentionPolicy({
    required this.selectionAcrossRestart,
    required this.loadedDataAcrossRestart,
    required this.scrollOffsetAcrossRestart,
  });

  static const userFacingTabs = TabStateRetentionPolicy(
    selectionAcrossRestart: true,
    loadedDataAcrossRestart: false,
    scrollOffsetAcrossRestart: false,
  );

  final bool selectionAcrossRestart;
  final bool loadedDataAcrossRestart;
  final bool scrollOffsetAcrossRestart;
}

class TabStateResolution {
  const TabStateResolution({
    required this.index,
    required this.id,
    required this.usedFallback,
    required this.migratedLegacyIndex,
  });

  final int index;
  final String? id;
  final bool usedFallback;
  final bool migratedLegacyIndex;
}

class TabStatePreference {
  const TabStatePreference._();

  static int restoreIndex(
    int savedIndex,
    int itemCount, {
    int fallbackIndex = 0,
  }) {
    if (itemCount <= 0) return 0;
    final safeFallback = fallbackIndex.clamp(0, itemCount - 1);
    if (savedIndex < 0 || savedIndex >= itemCount) return safeFallback;
    return savedIndex;
  }

  static TabStateResolution resolve({
    required List<String> itemIds,
    String? savedId,
    int legacySavedIndex = -1,
    String? fallbackId,
    int fallbackIndex = 0,
  }) {
    if (itemIds.isEmpty) {
      return const TabStateResolution(
        index: 0,
        id: null,
        usedFallback: true,
        migratedLegacyIndex: false,
      );
    }

    final fallbackIdIndex =
        fallbackId == null ? -1 : itemIds.indexOf(fallbackId);
    final safeFallback = restoreIndex(
      fallbackIdIndex >= 0 ? fallbackIdIndex : fallbackIndex,
      itemIds.length,
    );
    final normalizedSavedId = savedId?.trim() ?? '';
    final savedIdIndex = itemIds.indexOf(normalizedSavedId);
    if (savedIdIndex >= 0) {
      return TabStateResolution(
        index: savedIdIndex,
        id: itemIds[savedIdIndex],
        usedFallback: false,
        migratedLegacyIndex: false,
      );
    }

    // Only use the old numeric value when no stable identifier has ever been
    // stored. An unknown identifier means the data source changed and must
    // safely return to the declared default instead of trusting stale order.
    if (normalizedSavedId.isEmpty &&
        legacySavedIndex >= 0 &&
        legacySavedIndex < itemIds.length) {
      return TabStateResolution(
        index: legacySavedIndex,
        id: itemIds[legacySavedIndex],
        usedFallback: false,
        migratedLegacyIndex: true,
      );
    }

    return TabStateResolution(
      index: safeFallback,
      id: itemIds[safeFallback],
      usedFallback: true,
      migratedLegacyIndex: false,
    );
  }

  static String? idAt(List<String> itemIds, int index) {
    if (itemIds.isEmpty || index < 0 || index >= itemIds.length) return null;
    return itemIds[index];
  }
}

class PersistentTabState {
  const PersistentTabState._();

  static TabStateResolution restore({
    required String idKey,
    required String legacyIndexKey,
    required List<String> itemIds,
    String? fallbackId,
    int fallbackIndex = 0,
  }) {
    final resolution = TabStatePreference.resolve(
      itemIds: itemIds,
      savedId: ChewieHiveUtil.getString(idKey, autoCreate: false),
      legacySavedIndex: ChewieHiveUtil.getInt(
        legacyIndexKey,
        defaultValue: -1,
      ),
      fallbackId: fallbackId,
      fallbackIndex: fallbackIndex,
    );
    if (resolution.id != null &&
        (resolution.usedFallback || resolution.migratedLegacyIndex)) {
      save(
        idKey: idKey,
        legacyIndexKey: legacyIndexKey,
        itemIds: itemIds,
        index: resolution.index,
      );
    }
    return resolution;
  }

  static void save({
    required String idKey,
    required String legacyIndexKey,
    required List<String> itemIds,
    required int index,
  }) {
    final safeIndex = TabStatePreference.restoreIndex(index, itemIds.length);
    final id = TabStatePreference.idAt(itemIds, safeIndex);
    if (id == null) return;
    ChewieHiveUtil.put(idKey, id);
    ChewieHiveUtil.put(legacyIndexKey, safeIndex);
  }
}

class LazyTabLoadState {
  LazyTabLoadState({
    int? itemCount,
    List<String>? itemIds,
    String? savedId,
    int savedIndex = -1,
    String? fallbackId,
    int fallbackIndex = 0,
  })  : assert(itemCount != null || itemIds != null),
        _itemIds = itemIds ??
            List<String>.generate(itemCount!, (index) => index.toString()),
        currentIndex = TabStatePreference.resolve(
          itemIds: itemIds ??
              List<String>.generate(itemCount!, (index) => index.toString()),
          savedId: savedId,
          legacySavedIndex: savedIndex,
          fallbackId: fallbackId,
          fallbackIndex: fallbackIndex,
        ).index;

  final List<String> _itemIds;
  final Set<String> _loadedIds = <String>{};
  int currentIndex;

  bool selectAndShouldLoad(int index) {
    currentIndex = TabStatePreference.restoreIndex(index, _itemIds.length);
    return _loadedIds.add(_itemIds[currentIndex]);
  }

  bool get isCurrentLoaded =>
      _itemIds.isNotEmpty && _loadedIds.contains(_itemIds[currentIndex]);

  void markLoadFailed(int index) {
    if (index < 0 || index >= _itemIds.length) return;
    _loadedIds.remove(_itemIds[index]);
  }

  void reset({int? index}) {
    _loadedIds.clear();
    if (index != null) {
      currentIndex = TabStatePreference.restoreIndex(index, _itemIds.length);
    }
  }
}
