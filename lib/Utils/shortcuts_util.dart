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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../generated/l10n.dart';

typedef LocalizationsProvider = String Function(S);

class LockIntent extends Intent {
  const LockIntent();
}

class SettingIntent extends Intent {
  const SettingIntent();
}

class KeyboardShortcutHelpIntent extends Intent {
  const KeyboardShortcutHelpIntent();
}

class ChangeDayNightModeIntent extends Intent {
  const ChangeDayNightModeIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class HomeIntent extends Intent {
  const HomeIntent();
}

final defaultLoftifyShortcuts = [
  LoftifyShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyH,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const HomeIntent(),
    labelProvider: (s) => s.home,
  ),
  LoftifyShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyD,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ChangeDayNightModeIntent(),
    labelProvider: (s) => s.changeDayNightMode,
  ),
  LoftifyShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const SettingIntent(),
    labelProvider: (s) => s.setting,
  ),
  LoftifyShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyL,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const LockIntent(),
    labelProvider: (s) => s.lock,
  ),
  // LoftifyShortcut.all(
  //   key: HotKey(
  //     key: LogicalKeyboardKey.escape,
  //   ).singleActivator,
  //   intent: const EscapeIntent(),
  //   labelProvider: (s) => s.escape,
  // ),
  LoftifyShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.f1,
    ).singleActivator,
    intent: const KeyboardShortcutHelpIntent(),
    labelProvider: (s) => s.shortcutHelp,
  ),
];

class LoftifyShortcut {
  const LoftifyShortcut({
    required this.mac,
    required this.linux,
    required this.windows,
    required this.intent,
    required this.labelProvider,
  });

  LoftifyShortcut.all({
    required SingleActivator key,
    required Intent intent,
    required LocalizationsProvider labelProvider,
  }) : this(
          mac: key,
          linux: key,
          windows: key,
          intent: intent,
          labelProvider: labelProvider,
        );

  final SingleActivator mac;
  final SingleActivator linux;
  final SingleActivator windows;
  final Intent intent;
  final LocalizationsProvider labelProvider;

  bool get isControlPressed => triggerForPlatform().control;

  bool get isMetaPressed => triggerForPlatform().meta;

  bool get isShiftPressed => triggerForPlatform().shift;

  bool get isAltPressed => triggerForPlatform().alt;

  String get triggerLabel {
    SingleActivator tr = triggerForPlatform();
    LogicalKeyboardKey key = tr.trigger;
    if (key == LogicalKeyboardKey.arrowLeft) {
      return "←";
    } else if (key == LogicalKeyboardKey.arrowRight) {
      return "→";
    } else if (key == LogicalKeyboardKey.arrowUp) {
      return "↑";
    } else if (key == LogicalKeyboardKey.arrowDown) {
      return "↓";
    } else if (key == LogicalKeyboardKey.delete) {
      return "\u232B";
    } else if (key == LogicalKeyboardKey.enter) {
      return '\u2B90';
    } else {
      return key.keyLabel;
    }
  }

  SingleActivator triggerForPlatform() {
    late TargetPlatform platform;
    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else if (Platform.isIOS) {
      platform = TargetPlatform.iOS;
    } else if (Platform.isLinux) {
      platform = TargetPlatform.linux;
    } else if (Platform.isMacOS) {
      platform = TargetPlatform.macOS;
    } else if (Platform.isWindows) {
      platform = TargetPlatform.windows;
    } else {
      platform = TargetPlatform.windows;
    }
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.iOS:
        return mac;
      case TargetPlatform.macOS:
        return mac;
      case TargetPlatform.windows:
        return windows;
    }
  }
}

class CharConstants {
  static const empty = '';
  static const underScore = '_';
  static const plus = '+';

  static const space = ' ';
  static const curlyOpen = '{';

  static const chevronRight = ' » ';

  static const slash = '/';
  static const newLine = '\n';

  static const colon = ':';
  static const comma = ',';

  static const semiColon = ';';

  static const equalSign = '=';

  static const star = '*';

  static const questionMark = '?';
}

extension HotKeyExt on HotKey {
  SingleActivator get singleActivator {
    final activator = SingleActivator(
      logicalKey,
      shift: (modifiers ?? []).contains(HotKeyModifier.shift),
      control: (modifiers ?? []).contains(HotKeyModifier.control),
      alt: (modifiers ?? []).contains(HotKeyModifier.alt),
      meta: (modifiers ?? []).contains(HotKeyModifier.meta),
    );
    return activator;
  }
}
