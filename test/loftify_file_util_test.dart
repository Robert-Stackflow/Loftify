import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/loftify_file_util.dart';

void main() {
  test('download progress accumulator reserves progress for queued resources',
      () {
    final progress = DownloadProgressAccumulator(2);

    expect(progress.value, 0);
    expect(progress.update(0, 50, 100), 0.25);
    expect(progress.update(1, 25, 100), 0.375);
    expect(progress.complete(0), 0.625);
    expect(progress.update(1, 150, 100), 1);
  });

  test('download progress accumulator ignores invalid byte reports', () {
    final progress = DownloadProgressAccumulator(2);

    expect(progress.update(0, 50, 0), 0);
    expect(progress.update(-1, 50, 100), 0);
    expect(progress.update(2, 50, 100), 0);
  });
}
