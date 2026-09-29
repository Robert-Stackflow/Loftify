import '../Models/history_response.dart';

typedef LikeArchiveDescriptionBuilder = String Function(int month, int year);

List<ArchiveData> buildLikeArchives(
  dynamic rawArchives, {
  required LikeArchiveDescriptionBuilder descriptionBuilder,
  void Function(Object error, StackTrace stackTrace)? onMalformed,
}) {
  if (rawArchives is! List) return <ArchiveData>[];
  final archiveItems = <ArchiveItem>[];
  for (final rawArchive in rawArchives) {
    if (rawArchive is! Map) continue;
    try {
      archiveItems.add(ArchiveItem.fromJson(
        Map<String, dynamic>.from(rawArchive),
      ));
    } catch (error, stackTrace) {
      onMalformed?.call(error, stackTrace);
    }
  }
  archiveItems.sort((a, b) => b.year.compareTo(a.year));

  final archives = <ArchiveData>[];
  for (final archive in archiveItems) {
    for (var month = archive.monthCount.length - 1; month >= 0; month--) {
      final count = archive.monthCount[month];
      if (count <= 0) continue;
      archives.add(ArchiveData(
        desc: descriptionBuilder(month + 1, archive.year),
        count: count,
        endTime: 0,
        startTime: 0,
      ));
    }
  }
  return archives;
}

void decrementLikeArchives(
  List<ArchiveData> archives,
  Iterable<int> removedItemIndices,
) {
  final removedByArchive = <ArchiveData, int>{};
  for (final itemIndex in removedItemIndices) {
    final archive = likeArchiveForItemIndex(archives, itemIndex);
    if (archive != null) {
      removedByArchive[archive] = (removedByArchive[archive] ?? 0) + 1;
    }
  }
  for (final entry in removedByArchive.entries) {
    entry.key.count = (entry.key.count - entry.value).clamp(0, 0x7fffffff);
  }
  archives.removeWhere((archive) => archive.count <= 0);
}

ArchiveData? likeArchiveForItemIndex(
  List<ArchiveData> archives,
  int itemIndex,
) {
  var start = 0;
  for (final archive in archives) {
    final end = start + archive.count;
    if (itemIndex >= start && itemIndex < end) return archive;
    start = end;
  }
  return null;
}
