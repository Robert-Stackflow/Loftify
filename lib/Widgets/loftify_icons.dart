import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Product-level icon semantics. Pages should use these names instead of
/// importing an icon font directly.
abstract final class LoftifyIcons {
  static const IconData generalSettings = LucideIcons.settings2;
  static const IconData appearance = LucideIcons.paintbrushVertical;
  static const IconData image = LucideIcons.image;
  static const IconData basicSettings = LucideIcons.settings;
  static const IconData experiment = LucideIcons.flaskConical;
  static const IconData about = LucideIcons.info;

  static const IconData download = LucideIcons.download;
  static const IconData file = LucideIcons.file;
  static const IconData video = LucideIcons.video;
  static const IconData pause = LucideIcons.pause;
  static const IconData play = LucideIcons.play;
  static const IconData retry = LucideIcons.rotateCcw;
  static const IconData close = LucideIcons.x;
  static const IconData delete = LucideIcons.trash2;
}
