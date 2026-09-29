import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_notifier/local_notifier.dart';

class IToast {
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;
  static final GlobalKey<_MobileToastState> _toastKey =
      GlobalKey<_MobileToastState>();
  static final ValueNotifier<_ToastContent> _toastContent =
      ValueNotifier(const _ToastContent(''));

  static FToast? show(
    String text, {
    Icon? icon,
    String? decription,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    if (ResponsiveUtil.isDesktop()) {
      NotificationManager().show(
        chewieProvider.rootContext,
        text,
        overlayState: chewieProvider.globalNavigatorState?.overlay,
        description: decription,
        duration: Duration(seconds: seconds),
        style: NotificationStyle(icon: icon?.icon, iconColor: icon?.color),
      );
    } else {
      final overlay = chewieProvider.globalNavigatorState?.overlay;
      if (overlay == null || !overlay.mounted) return null;
      _toastTimer?.cancel();
      _toastContent.value = _ToastContent(
        text,
        icon: icon,
        description: decription,
        gravity: gravity,
      );
      if (_toastEntry == null) {
        _toastEntry = OverlayEntry(
          builder: (context) => _MobileToast(
            key: _toastKey,
            content: _toastContent,
            onDismissed: () {
              _toastEntry?.remove();
              _toastEntry = null;
            },
          ),
        );
        overlay.insert(_toastEntry!);
      } else {
        _toastKey.currentState?.show();
      }
      _toastTimer = Timer(Duration(seconds: seconds), () {
        _toastKey.currentState?.dismiss();
      });
    }
    return null;
  }

  static FToast? showTop(
    String text, {
    Icon? icon,
    String? decription,
  }) {
    if (text.nullOrEmpty) return null;
    return show(
      text,
      icon: icon,
      decription: decription,
    );
  }

  static FToast? showBottom(
    String text, {
    Icon? icon,
  }) {
    return show(text, icon: icon, gravity: ToastGravity.BOTTOM);
  }

  static LocalNotification? showDesktopNotification(
    String title, {
    String? subTitle,
    String? body,
    List<String> actions = const [],
    Function()? onClick,
    Function(int)? onClickAction,
  }) {
    if (!ResponsiveUtil.isDesktop()) return null;
    var nActions =
        actions.map((e) => LocalNotificationAction(text: e)).toList();
    LocalNotification notification = LocalNotification(
      identifier: StringUtil.generateUid(),
      title: title,
      subtitle: subTitle,
      body: body,
      actions: nActions,
    );
    notification.onShow = () {};
    notification.onClose = (closeReason) {
      switch (closeReason) {
        case LocalNotificationCloseReason.userCanceled:
          break;
        case LocalNotificationCloseReason.timedOut:
          break;
        default:
      }
    };
    notification.onClick = onClick;
    notification.onClickAction = onClickAction;
    notification.show();
    return notification;
  }
}

class _ToastContent {
  const _ToastContent(
    this.text, {
    this.icon,
    this.description,
    this.gravity = ToastGravity.TOP,
  });

  final String text;
  final Icon? icon;
  final String? description;
  final ToastGravity gravity;
}

class _MobileToast extends StatefulWidget {
  const _MobileToast({
    super.key,
    required this.content,
    required this.onDismissed,
  });

  final ValueListenable<_ToastContent> content;
  final VoidCallback onDismissed;

  @override
  State<_MobileToast> createState() => _MobileToastState();
}

class _MobileToastState extends State<_MobileToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 140),
  )..forward();

  void show() => _controller.forward();

  Future<void> dismiss() async {
    await _controller.reverse();
    if (mounted && _controller.isDismissed) widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ValueListenableBuilder<_ToastContent>(
            valueListenable: widget.content,
            builder: (context, value, _) {
              final bottom = value.gravity == ToastGravity.BOTTOM;
              final theme = Theme.of(context);
              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              final foreground = theme.colorScheme.onSurface;
              return Align(
                alignment:
                    bottom ? Alignment.bottomCenter : Alignment.topCenter,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = reduceMotion
                        ? 1.0
                        : Curves.easeOutCubic.transform(_controller.value);
                    return Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, (bottom ? 10 : -10) * (1 - progress)),
                        child: child,
                      ),
                    );
                  },
                  child: Semantics(
                    liveRegion: true,
                    child: Material(
                      color: theme.scaffoldBackgroundColor,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.dividerColor,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (value.icon != null) ...[
                                IconTheme(
                                  data: IconThemeData(
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  child: value.icon!,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      value.text,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: foreground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (value.description?.isNotEmpty ?? false)
                                      Text(
                                        value.description!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
