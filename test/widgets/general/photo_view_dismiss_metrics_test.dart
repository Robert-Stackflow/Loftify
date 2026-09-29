import 'package:awesome_chewie/src/Widgets/Basic/photo_view_dismiss_metrics.dart';
import 'package:awesome_chewie/src/Widgets/Basic/hero_photo_view_screen.dart';
import 'package:awesome_chewie/src/Utils/System/route_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoViewDismissMetrics', () {
    test('uses a reachable distance threshold on small and large screens', () {
      expect(PhotoViewDismissMetrics.threshold(400), 96);
      expect(PhotoViewDismissMetrics.threshold(1000), 140);
    });

    test('normalizes visual progress and clamps its bounds', () {
      expect(PhotoViewDismissMetrics.progress(-20, 800), 0);
      expect(PhotoViewDismissMetrics.progress(136, 800), closeTo(0.5, 0.001));
      expect(PhotoViewDismissMetrics.progress(900, 800), 1);
      expect(PhotoViewDismissMetrics.scale(1), 0.86);
      expect(PhotoViewDismissMetrics.backgroundOpacity(1), 0);
      expect(PhotoViewDismissMetrics.contentOpacity(1), 0.88);
      expect(PhotoViewDismissMetrics.appBarOpacity(0), 1);
      expect(PhotoViewDismissMetrics.appBarOpacity(0.2), 0.5);
      expect(PhotoViewDismissMetrics.appBarOpacity(0.4), 0);
    });

    test('dismisses by distance or a deliberate downward fling', () {
      expect(
        PhotoViewDismissMetrics.shouldDismiss(
          distance: 120,
          velocity: 0,
          viewportHeight: 800,
        ),
        isTrue,
      );
      expect(
        PhotoViewDismissMetrics.shouldDismiss(
          distance: 80,
          velocity: 1000,
          viewportHeight: 800,
        ),
        isTrue,
      );
      expect(
        PhotoViewDismissMetrics.shouldDismiss(
          distance: 60,
          velocity: 1500,
          viewportHeight: 800,
        ),
        isFalse,
      );
      expect(
        PhotoViewDismissMetrics.shouldDismiss(
          distance: 80,
          velocity: 400,
          viewportHeight: 800,
        ),
        isFalse,
      );
    });
  });

  test('photo viewer fade routes can reveal the page underneath', () {
    final route = RouteUtil.getFadeRoute(
      const SizedBox.shrink(),
      opaque: false,
    ) as PageRoute<dynamic>;

    expect(route.opaque, isFalse);
    expect(route.barrierColor, Colors.transparent);
  });

  test('photo viewer strips thumbnail processing without changing hero input',
      () {
    expect(
      resolvePhotoViewOriginalUrl(
        'https://img.example/a.jpg?imageView&thumbnail=500x0&quality=96',
      ),
      'https://img.example/a.jpg',
    );
    expect(
      resolvePhotoViewOriginalUrl('https://img.example/a.jpg?token=required'),
      'https://img.example/a.jpg?token=required',
    );
  });
}
