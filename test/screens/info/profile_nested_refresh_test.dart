import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';

void main() {
  testWidgets('profile body pull reveals the refresh header', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var refreshes = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExtendedNestedScrollView(
          onlyOneScrollInBody: true,
          headerSliverBuilder: (context, _) => [
            const SliverAppBar(
              expandedHeight: 500,
              pinned: true,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: SizedBox(height: 56, child: Text('Tabs')),
              ),
            ),
          ],
          body: EasyRefresh.builder(
            header: buildNestedRefreshHeader(),
            onRefresh: () async {
              refreshes++;
            },
            childBuilder: (context, physics) => CustomScrollView(
              physics: physics,
              slivers: [
                SliverList.builder(
                  itemCount: 20,
                  itemBuilder: (context, index) => SizedBox(
                    height: 100,
                    child: Text('Item $index'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.drag(find.text('Item 0'), const Offset(0, 430));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(tester.takeException(), isNull);
  });
}
