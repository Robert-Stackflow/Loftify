import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Utils/enums.dart';

void main() {
  test('tag filter preference restores every user-facing filter', () {
    final original = GetTagPostListParams(
      tag: 'old-tag',
      tagPostResultType: TagPostResultType.month,
      recentDayType: TagRecentDayType.oneWeek,
      tagRangeType: TagRangeType.follow,
      protectedFlag: true,
      postTypes: TagPostType.image,
      postYm: '2026-08',
    );

    final restored = GetTagPostListParams.fromPreference(
      tag: 'current-tag',
      value: jsonDecode(jsonEncode(original.toPreferenceJson())),
      fallbackResultType: TagPostResultType.week,
    );

    expect(restored.tag, 'current-tag');
    expect(restored.offset, 0);
    expect(restored.tagPostResultType, TagPostResultType.month);
    expect(restored.recentDayType, TagRecentDayType.oneWeek);
    expect(restored.tagRangeType, TagRangeType.follow);
    expect(restored.protectedFlag, isTrue);
    expect(restored.postTypes, TagPostType.image);
    expect(restored.postYm, '2026-08');
  });

  test('invalid saved filter values fall back without throwing', () {
    final restored = GetTagPostListParams.fromPreference(
      tag: 'safe-tag',
      value: <String, dynamic>{
        'resultType': 99,
        'recentDayType': -4,
        'rangeType': 'bad',
        'postType': 200,
        'protected': 'true',
        'postYm': 202608,
      },
      fallbackResultType: TagPostResultType.newPost,
    );

    expect(restored.tagPostResultType, TagPostResultType.newPost);
    expect(restored.recentDayType, TagRecentDayType.noLimit);
    expect(restored.tagRangeType, TagRangeType.noLimit);
    expect(restored.protectedFlag, isFalse);
    expect(restored.postTypes, TagPostType.noLimit);
    expect(restored.postYm, isEmpty);
  });
}
