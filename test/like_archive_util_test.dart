import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Utils/like_archive_util.dart';

void main() {
  test('archive parser keeps repeated month counts at their real month', () {
    final archives = buildLikeArchives(
      [
        {
          'year': 2025,
          'monthCount': [1, 3, 1, 3],
        },
        {
          'year': 2026,
          'monthCount': [0, 2],
        },
      ],
      descriptionBuilder: (month, year) => '$year-$month',
    );

    expect(
      archives.map((archive) => '${archive.desc}:${archive.count}'),
      ['2026-2:2', '2025-4:3', '2025-3:1', '2025-2:3', '2025-1:1'],
    );
  });

  test('batch removal updates counts and drops empty groups', () {
    final archives = [
      ArchiveData(desc: 'new', count: 2, endTime: 0, startTime: 0),
      ArchiveData(desc: 'old', count: 2, endTime: 0, startTime: 0),
    ];

    decrementLikeArchives(archives, [0, 1, 3]);

    expect(archives, hasLength(1));
    expect(archives.single.desc, 'old');
    expect(archives.single.count, 1);
  });
}
