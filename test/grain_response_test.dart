import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Models/grain_response.dart';

void main() {
  test('timeline item without post data is omitted', () {
    expect(GrainPostItem.fromTimelineJson({'postData': null}), isNull);
    expect(GrainPostItem.fromTimelineJson({}), isNull);
  });

  test('malformed non-null post data is still reported', () {
    expect(
      () => GrainPostItem.fromTimelineJson({'postData': 'invalid'}),
      throwsA(isA<TypeError>()),
    );
  });
}
