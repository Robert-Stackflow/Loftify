import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingScrollController extends ScrollController {
  int added = 0;
  int removed = 0;

  @override
  void addListener(VoidCallback listener) {
    added++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removed++;
    super.removeListener(listener);
  }
}

void main() {
  testWidgets('ScrollToHide moves and releases controller listeners',
      (tester) async {
    final first = _TrackingScrollController();
    final second = _TrackingScrollController();
    final visibility = ScrollToHideController();

    Widget build(ScrollController controller) {
      return MaterialApp(
        home: ScrollToHide(
          scrollController: controller,
          hideDirection: Axis.vertical,
          controller: visibility,
          child: const SizedBox(height: 40),
        ),
      );
    }

    await tester.pumpWidget(build(first));
    expect(first.added, 1);
    expect(visibility.doHide, isNotNull);

    await tester.pumpWidget(build(second));
    expect(first.removed, 1);
    expect(second.added, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.removed, 1);
    expect(visibility.doShow, isNull);
    expect(visibility.doHide, isNull);

    first.dispose();
    second.dispose();
  });
}
