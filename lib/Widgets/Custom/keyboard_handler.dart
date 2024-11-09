/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Setting/setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/utils.dart';
import 'package:provider/provider.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/shortcuts_util.dart';
import '../../generated/l10n.dart';

class KeyboardHandler extends StatefulWidget {
  const KeyboardHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  KeyboardHandlerState createState() => KeyboardHandlerState();
}

class KeyboardHandlerState extends State<KeyboardHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  focus() {
    _focusNode.requestFocus();
  }

  Map<Type, Action<Intent>> generalActions(BuildContext context) {
    return {
      KeyboardShortcutHelpIntent: CallbackAction(
        onInvoke: (_) {
          return Utils.showHelp(context);
        },
      ),
      LockIntent: CallbackAction(
        onInvoke: (_) {
          if (HiveUtil.canLock()) {
            mainScreenState?.jumpToLock();
          } else {
            IToast.showTop(S.current.noGestureLock);
          }
          return null;
        },
      ),
      EscapeIntent: CallbackAction(
        onInvoke: (_) {
          if (Navigator.of(rootContext).canPop()) {
            Navigator.of(rootContext).pop();
          }
          return null;
        },
      ),
    };
  }

  static Map<Type, Action<Intent>> mainScreenShortcuts = {
    SettingIntent: CallbackAction(
      onInvoke: (_) {
        RouteUtil.pushPanelCupertinoRoute(rootContext, const SettingScreen());
        return null;
      },
    ),
    ChangeDayNightModeIntent: CallbackAction(
      onInvoke: (_) {
        mainScreenState?.changeMode();
        return null;
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts.manager(
      manager: LoggingShortcutManager(
          shortcuts: Map.fromEntries(defaultLoftifyShortcuts
              .map((e) => MapEntry(e.triggerForPlatform(), e.intent)))),
      child: Selector<AppProvider, Map<Type, Action<Intent>>>(
        selector: (context, appProvider) => appProvider.dynamicShortcuts,
        builder: (context, dynamicShortcuts, child) => Actions(
          actions: {
            ...dynamicShortcuts,
            ...generalActions(context),
          },
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            canRequestFocus: true,
            descendantsAreFocusable: true,
            onKeyEvent: (node, event) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                if (Navigator.of(rootContext).canPop()) {
                  Navigator.of(rootContext).pop();
                }
              }
              return KeyEventResult.ignored;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class LoggingShortcutManager extends ShortcutManager {
  LoggingShortcutManager({required super.shortcuts});

  @override
  KeyEventResult handleKeypress(
    BuildContext context,
    KeyEvent event, {
    LogicalKeySet? keysPressed,
  }) {
    final KeyEventResult result = super.handleKeypress(context, event);
    // ILogger.info("Loftify",'handleKeyPress($event, $keysPressed) result: $result');
    return result;
  }
}
