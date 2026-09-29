import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Semantic Lucide glyphs shared by reusable Chewie components.
///
/// Names describe meaning instead of visual variants. Persistent selected
/// states keep the same glyph and express emphasis through color or a
/// container; action pairs may use different glyphs when their meaning changes.
abstract final class ChewieIcons {
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData previous = LucideIcons.chevronLeft;
  static const IconData next = LucideIcons.chevronRight;
  static const IconData expand = LucideIcons.chevronDown;
  static const IconData collapse = LucideIcons.chevronUp;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData arrowDown = LucideIcons.arrowDown;
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData arrowRight = LucideIcons.arrowRight;

  static const IconData add = LucideIcons.plus;
  static const IconData remove = LucideIcons.minus;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData copy = LucideIcons.copy;
  static const IconData copyDone = LucideIcons.copyCheck;
  static const IconData more = LucideIcons.ellipsisVertical;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData retry = LucideIcons.refreshCw;
  static const IconData search = LucideIcons.search;
  static const IconData share = LucideIcons.share2;
  static const IconData openExternal = LucideIcons.externalLink;

  static const IconData info = LucideIcons.info;
  static const IconData success = LucideIcons.circleCheck;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData error = LucideIcons.circleX;
  static const IconData imageUnavailable = LucideIcons.imageOff;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData archive = LucideIcons.archive;
  static const IconData star = LucideIcons.star;
  static const IconData starHalf = LucideIcons.starHalf;

  static const IconData pin = LucideIcons.pin;
  static const IconData minimizeWindow = LucideIcons.minus;
  static const IconData maximizeWindow = LucideIcons.maximize2;
  static const IconData restoreWindow = LucideIcons.minimize2;
  static const IconData closeWindow = LucideIcons.x;
  static const IconData square = LucideIcons.square;
  static const IconData alarm = LucideIcons.alarmClock;
  static const IconData time = LucideIcons.clock3;
}
