import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Widgets/Favorite/favorite_folder_card.dart';

void main() {
  testWidgets('favorite folder card grows on a narrow large-text viewport',
      (tester) async {
    var opened = 0;
    var edited = 0;
    var deleted = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: LoftifyFavoriteFolderCard(
                title: 'A very long favorite folder title that can wrap',
                folderIdLabel: 'Folder identifier: 12345678901234567890',
                postCountLabel: '123456 posts',
                cover: const ColoredBox(color: Colors.teal),
                editLabel: 'Edit folder',
                deleteLabel: 'Delete folder',
                onTap: () => opened++,
                onEdit: () => edited++,
                onDelete: () => deleted++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LoftifyFavoriteFolderCard)).height,
        greaterThan(120));
    await tester.tap(find.byTooltip('Edit folder'));
    await tester.tap(find.byTooltip('Delete folder'));
    expect(edited, 1);
    expect(deleted, 1);
    expect(opened, 0);
  });

  testWidgets('default folder can omit the destructive action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoftifyFavoriteFolderCard(
            title: 'Default',
            folderIdLabel: 'ID: 1',
            postCountLabel: '2 posts',
            cover: const ColoredBox(color: Colors.teal),
            editLabel: 'Edit folder',
            deleteLabel: 'Delete folder',
            onTap: () {},
            onEdit: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Edit folder'), findsOneWidget);
    expect(find.byTooltip('Delete folder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('favorite folder page uses the shared cover card', () {
    final source = File(
      'lib/Screens/Info/favorite_folder_list_screen.dart',
    ).readAsStringSync();
    expect(source, contains('LoftifyFavoriteFolderCard('));
    expect(source, contains('fit: BoxFit.cover'));
    expect(source, isNot(contains('height: 80')));
    expect(source, isNot(contains('width: 80')));
  });
}
