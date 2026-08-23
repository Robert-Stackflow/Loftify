import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_chewie/src/Widgets/Component/auto_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pending image retries are cancelled after disposal',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyCachedNetworkImage(
          imageUrl: 'https://invalid.localhost/image.png',
          width: 120,
          height: 120,
          simpleError: true,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });

  testWidgets('network thumbnails decode to width without changing aspect',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            height: 80,
            child: MyCachedNetworkImage(
              imageUrl: 'https://invalid.localhost/thumbnail.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 360);
    expect(image.memCacheHeight, isNull);
    expect(image.filterQuality, FilterQuality.medium);
  });

  testWidgets('explicit memory cache width preserves the source aspect ratio',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyCachedNetworkImage(
          imageUrl: 'https://invalid.localhost/thumbnail.png',
          width: 120,
          height: 80,
          memCacheWidth: 240,
          memCacheHeight: 160,
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 240);
    expect(image.memCacheHeight, isNull);
  });

  testWidgets('auto image updates reused items and recognizes query URLs',
      (tester) async {
    Widget buildImage(String url) => MaterialApp(
          home: AutoImage(
            imageUrl: url,
            showLoading: false,
          ),
        );

    await tester.pumpWidget(
      buildImage('https://invalid.localhost/first.png?quality=small'),
    );
    await tester.pump();
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .imageUrl,
      contains('first.png'),
    );

    await tester.pumpWidget(
      buildImage('https://invalid.localhost/second.webp?quality=middle'),
    );
    await tester.pump();
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .imageUrl,
      contains('second.webp'),
    );
  });
}
