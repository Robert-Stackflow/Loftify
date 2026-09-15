import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/download_task.dart';

void main() {
  for (final status in DownloadTaskStatus.values) {
    for (final total in [0, 100]) {
      test('indicator follows transfer state $status total=$total', () {
        final task = DownloadTask(
            id: 'test',
            url: 'https://example.com/image.jpg',
            fileName: 'image.jpg',
            mediaType: DownloadMediaType.image,
            status: status,
            progress: 0.4,
            receivedBytes: 40,
            totalBytes: total,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026));
        final expected = status == DownloadTaskStatus.completed
            ? 1.0
            : status == DownloadTaskStatus.downloading && total == 0
                ? null
                : 0.4;
        expect(task.indicatorProgress, expected);
        expect(task.progress, 0.4);
      });
    }
  }
}
