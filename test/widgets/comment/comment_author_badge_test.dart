import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/post_detail_response.dart';
import 'package:loftify/Widgets/Item/loftify_item_builder.dart';
import 'package:loftify/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/comment_author_badge',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  testWidgets('author badge stays next to nickname, clear of the like action',
      (tester) async {
    final comment = Comment.fromJson({
      'blogId': 1,
      'postId': 2,
      'content': 'Comment',
      'publisherBlogInfo': {
        'blogId': 1,
        'blogName': 'short',
        'blogNickName': '短昵称',
        'bigAvaImg': '',
      },
    });

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        chewieProvider.setRootContext(context);
        return Scaffold(
          body: SizedBox(
            width: 320,
            child: LoftifyItemBuilder.buildL2CommentRow(
              context,
              comment,
              writerId: 1,
            ),
          ),
        );
      }),
    ));
    await tester.pump();

    final nickname = tester.getRect(find.text('短昵称'));
    final badge = tester.getRect(find.text('作者'));
    expect(badge.left - nickname.right, lessThan(12));
    expect(badge.left, greaterThan(nickname.left));
    expect(tester.takeException(), isNull);
  });
}
