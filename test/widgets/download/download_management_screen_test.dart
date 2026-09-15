import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/download_task.dart';
import 'package:loftify/Screens/Download/download_group_detail_screen.dart';
import 'package:loftify/Screens/Download/download_management_screen.dart';
import 'package:loftify/Utils/download_task_manager.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:loftify/Widgets/Design/loftify_state_view.dart';

class _MemoryStore implements DownloadTaskStore {
  List<DownloadTask> tasks = <DownloadTask>[];
  List<DownloadGroup> groups = <DownloadGroup>[];

  @override
  Future<List<DownloadTask>> read() async => tasks;

  @override
  Future<List<DownloadGroup>> readGroups() async => groups;

  @override
  Future<void> write(List<DownloadTask> value) async {
    tasks = List<DownloadTask>.from(value);
  }

  @override
  Future<void> writeGroups(List<DownloadGroup> value) async {
    groups = List<DownloadGroup>.from(value);
  }
}

class _PendingExecutor extends DownloadTaskExecutor {
  @override
  Future<DownloadTaskResult> run(
    DownloadTask task, {
    required CancelToken cancelToken,
    required DownloadProgressCallback onProgress,
  }) {
    return Completer<DownloadTaskResult>().future;
  }

  @override
  Future<void> deleteTemporaryFiles(DownloadTask task) async {}
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('zh'),
  bool dark = false,
  double textScale = 1,
}) =>
    MaterialApp(
      locale: locale,
      theme: (dark
              ? ChewieThemeColorData.defaultDarkThemes.first
              : ChewieThemeColorData.defaultLightThemes.first)
          .toThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: const [
        ChewieLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          chewieProvider.setRootContext(context);
          return child;
        },
      ),
    );

void main() {
  setUpAll(() async {
    final directory = Directory(
      '${Directory.current.path}/build/test_hive/download_management_screen',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  for (final detail in [false, true]) {
    for (final size in [const Size(280, 320), const Size(720, 320)]) {
      for (final locale in [
        const Locale('en'),
        const Locale('zh'),
        const Locale('zh', 'TW')
      ]) {
        for (final dark in [false, true]) {
          testWidgets(
              'download empty state is initially visible detail=$detail $size $locale dark=$dark',
              (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final previousBuilder = chewieProvider.stateWidgetBuilder;
            chewieProvider.stateWidgetBuilder = LoftifyStateView.fromChewie;
            addTearDown(
                () => chewieProvider.stateWidgetBuilder = previousBuilder);
            final manager = DownloadTaskManager(
                store: _MemoryStore(), executor: _PendingExecutor());
            await manager.initialize();
            await tester.pumpWidget(_host(
              detail
                  ? DownloadGroupDetailScreen(
                      groupId: 'missing', manager: manager)
                  : DownloadManagementScreen(manager: manager),
              locale: locale,
              dark: dark,
              textScale: 2,
            ));
            await tester.pumpAndSettle();
            final state =
                tester.widget<LoftifyStateView>(find.byType(LoftifyStateView));
            expect(state.visual, LoftifyStateVisual.empty);
            final label = find.text(state.title);
            expect(
                tester.getRect(label).bottom, lessThanOrEqualTo(size.height));
            expect(label.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            manager.dispose();
          });
        }
      }
    }
  }

  for (final width in [280.0, 720.0]) {
    for (final locale in [
      const Locale('en'),
      const Locale('zh'),
      const Locale('zh', 'TW')
    ]) {
      for (final dark in [false, true]) {
        testWidgets(
            'group actions retain text and work $width $locale dark=$dark',
            (tester) async {
          tester.view.physicalSize = Size(width, 480);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final manager = DownloadTaskManager(
              store: _MemoryStore(), executor: _PendingExecutor());
          await manager.initialize();
          final result = await manager.enqueueBatch(const [
            DownloadRequest(
              url: 'https://example.com/group-actions.jpg',
              fileName: 'group-actions.jpg',
              mediaType: DownloadMediaType.image,
            )
          ],
              source: const DownloadSourceDescriptor(
                  type: DownloadSourceType.collection,
                  sourceId: '42',
                  title: 'Collection'));
          await tester.pumpWidget(_host(
              DownloadGroupDetailScreen(
                  groupId: result.group!.id, manager: manager),
              locale: locale,
              dark: dark,
              textScale: 2));
          Future<void> pumpFrames() async {
            for (var frame = 0; frame < 5; frame++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
          }

          await pumpFrames();
          Future<void> checkButton(String key, {bool tap = true}) async {
            final button = find.byKey(Key(key));
            await tester.scrollUntilVisible(button, 160,
                scrollable: find.byType(Scrollable).first);
            await tester.ensureVisible(button);
            await pumpFrames();
            final texts =
                find.descendant(of: button, matching: find.byType(Text));
            expect(texts, findsOneWidget);
            final text = tester.widget<Text>(texts);
            final paragraph = tester.renderObject<RenderParagraph>(texts);
            for (final box in paragraph.getBoxesForSelection(TextSelection(
                baseOffset: 0, extentOffset: text.data!.length))) {
              expect(box.bottom, lessThanOrEqualTo(paragraph.size.height),
                  reason: text.data);
            }
            expect(button.hitTestable(), findsOneWidget);
            if (tap) {
              await tester.tap(button);
              await pumpFrames();
            }
          }

          await checkButton('download-view-original', tap: false);
          await checkButton('download-group-pause');
          expect(manager.tasks.single.status, DownloadTaskStatus.paused);
          await checkButton('download-group-resume');
          expect(manager.tasks.single.isActive, isTrue);
          await checkButton('download-group-cancel');
          expect(manager.tasks.single.status, DownloadTaskStatus.cancelled);
          await checkButton('download-group-retry');
          expect(manager.tasks.single.isActive, isTrue);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          manager.dispose();
        });
      }
    }
  }

  for (final detail in [false, true]) {
    for (final status in [
      DownloadTaskStatus.paused,
      DownloadTaskStatus.cancelled,
      DownloadTaskStatus.failed,
      DownloadTaskStatus.completed
    ]) {
      testWidgets(
          'unknown-size stopped task has static progress detail=$detail $status',
          (tester) async {
        final now = DateTime(2026, 9, 16);
        final task = DownloadTask(
            id: 'stopped',
            url: 'https://example.com/stopped.jpg',
            fileName: 'stopped.jpg',
            mediaType: DownloadMediaType.image,
            status: status,
            createdAt: now,
            updatedAt: now);
        final store = _MemoryStore()..tasks = [task];
        if (detail) {
          store.groups = [
            DownloadGroup(
                id: 'group',
                source: const DownloadSourceDescriptor(
                    type: DownloadSourceType.collection,
                    sourceId: '42',
                    title: 'Collection'),
                taskIds: [task.id],
                requestedCount: 1,
                createdAt: now,
                updatedAt: now)
          ];
        }
        final manager =
            DownloadTaskManager(store: store, executor: _PendingExecutor());
        await manager.initialize();
        await tester.pumpWidget(_host(detail
            ? DownloadGroupDetailScreen(groupId: 'group', manager: manager)
            : DownloadManagementScreen(manager: manager)));
        await tester.pump(const Duration(milliseconds: 200));
        if (detail) {
          await tester.scrollUntilVisible(
              find.byKey(const ValueKey('download-resource-stopped')), 150,
              scrollable: find.byType(Scrollable).first);
          await tester.pump(const Duration(milliseconds: 200));
        }
        final bars = tester.widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator));
        expect(bars, isNotEmpty);
        for (final bar in bars) {
          expect(bar.value, isNotNull);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        manager.dispose();
      });
    }
  }

  testWidgets('download manager shows one parent instead of flat child tasks',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    final result = await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/first.jpg',
          fileName: 'first.jpg',
          mediaType: DownloadMediaType.image,
          title: 'First child',
        ),
        DownloadRequest(
          url: 'https://example.com/second.jpg',
          fileName: 'second.jpg',
          mediaType: DownloadMediaType.image,
          title: 'Second child',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: 'Parent collection',
      ),
    );
    await tester.pumpWidget(
      _host(DownloadManagementScreen(manager: manager)),
    );
    await tester.pump();

    expect(find.text('Parent collection'), findsOneWidget);
    expect(find.text('合集'), findsOneWidget);
    expect(find.text('First child'), findsNothing);
    expect(find.text('Second child'), findsNothing);
    expect(find.text('first.jpg'), findsNothing);
    expect(find.text('second.jpg'), findsNothing);
    expect(find.textContaining('/ 2'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(ValueKey('download-group-${result.group!.id}')),
          )
          .onTap,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('group detail shows child progress and controls on narrow phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    final result = await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/detail-first.jpg',
          fileName: 'detail-first.jpg',
          mediaType: DownloadMediaType.image,
          title: 'First child',
        ),
        DownloadRequest(
          url: 'https://example.com/detail-second.jpg',
          fileName: 'detail-second.jpg',
          mediaType: DownloadMediaType.image,
          title: 'Second child',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.collection,
        sourceId: '42',
        title: 'Parent collection',
      ),
    );
    await tester.pumpWidget(
      _host(
        DownloadGroupDetailScreen(
          groupId: result.group!.id,
          manager: manager,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('下载任务详情'), findsOneWidget);
    expect(find.text('查看原内容'), findsOneWidget);
    expect(find.text('First child'), findsOneWidget);
    expect(find.text('Second child'), findsOneWidget);
    expect(find.text('资源列表'), findsOneWidget);
    expect(find.byKey(const Key('download-group-pause')), findsOneWidget);
    expect(find.byKey(const Key('download-group-cancel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('download tiles remain usable at two-times text scale',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/large-text-group.jpg',
          fileName: 'large-text-group.jpg',
          mediaType: DownloadMediaType.image,
          title: 'A very long child title for the grouped download',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.favoriteFolder,
        sourceId: 'large-text',
        title: 'A very long favorite folder download title',
      ),
    );
    await manager.enqueue(
      url: 'https://example.com/large-text-standalone.mp4',
      fileName: 'a-very-long-standalone-video-file-name.mp4',
      mediaType: DownloadMediaType.video,
      title: 'A very long standalone download title',
    );

    await tester.pumpWidget(
      _host(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: DownloadManagementScreen(manager: manager),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    expect(find.text('A very long favorite folder download title'),
        findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('download-group-status'))).right,
      lessThanOrEqualTo(280),
    );
    await tester.scrollUntilVisible(
      find.text('A very long standalone download title'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('download-task-actions')),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    expect(find.text('A very long standalone download title'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('download-task-status'))).right,
      lessThanOrEqualTo(280),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('download-task-actions'))).right,
      lessThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('download group details reflow on narrow large-text screens',
      (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = DownloadTaskManager(
      store: _MemoryStore(),
      executor: _PendingExecutor(),
      maxConcurrentTasks: 1,
    );
    await manager.initialize();
    final result = await manager.enqueueBatch(
      const <DownloadRequest>[
        DownloadRequest(
          url: 'https://example.com/detail-large-one.jpg',
          fileName: 'detail-large-one.jpg',
          mediaType: DownloadMediaType.image,
          title: 'A very long first resource download title',
        ),
        DownloadRequest(
          url: 'https://example.com/detail-large-two.jpg',
          fileName: 'detail-large-two.jpg',
          mediaType: DownloadMediaType.image,
          title: 'A very long second resource download title',
        ),
      ],
      source: const DownloadSourceDescriptor(
        type: DownloadSourceType.favoriteFolder,
        sourceId: 'detail-large-text',
        title: 'A very long source title for download details',
      ),
    );
    final secondTaskId = result.tasks.last.id;

    await tester.pumpWidget(
      _host(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: DownloadGroupDetailScreen(
            groupId: result.group!.id,
            manager: manager,
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
    expect(find.text('A very long source title for download details'),
        findsOneWidget);
    final detailScrollable = find.descendant(
      of: find.byKey(const Key('download-group-detail-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('download-group-overview-status')),
      120,
      scrollable: detailScrollable,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('download-group-cancel')),
      120,
      scrollable: detailScrollable,
    );
    expect(
      tester
          .getRect(find.byKey(const Key('download-group-overview-status')))
          .right,
      lessThanOrEqualTo(280),
    );
    expect(
      tester.getRect(find.byKey(const Key('download-group-cancel'))).right,
      lessThanOrEqualTo(280),
    );
    await tester.scrollUntilVisible(
      find.text('A very long second resource download title'),
      180,
      scrollable: detailScrollable,
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('download-resource-actions-$secondTaskId')),
      100,
      scrollable: detailScrollable,
    );
    await tester.pump();

    expect(find.text('A very long second resource download title'),
        findsOneWidget);
    expect(
      tester
          .getRect(
            find.byKey(ValueKey('download-resource-status-$secondTaskId')),
          )
          .right,
      lessThanOrEqualTo(280),
    );
    expect(
      tester
          .getRect(
            find.byKey(ValueKey('download-resource-actions-$secondTaskId')),
          )
          .right,
      lessThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);
  });
}
