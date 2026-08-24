import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Models/account_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/hive_util.dart';
import '../Item/item_builder.dart';

/// Overlay geometry shared by the four primary navigation pages.
///
/// The matching [contentTopInset] belongs inside each page's scrollable. It
/// preserves the familiar first-frame spacing, then scrolls away so content can
/// naturally continue beneath the system status bar and this floating layer.
class LoftifyFloatingNavigationHeader extends StatelessWidget {
  const LoftifyFloatingNavigationHeader({
    super.key,
    required this.child,
  });

  final Widget child;

  static const double height = 48;
  static const double topGap = 6;
  static const double contentGap = 8;

  static double horizontalInset(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 16 : 12;

  static double topOffset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topGap;

  static double contentTopInset(BuildContext context) =>
      topOffset(context) + height + contentGap;

  @override
  Widget build(BuildContext context) {
    final horizontal = horizontalInset(context);
    return Positioned(
      top: topOffset(context),
      left: horizontal,
      right: horizontal,
      height: height,
      child: child,
    );
  }
}

/// A low-noise, full-radius floating surface for navigation-page controls.
class LoftifyFloatingCapsule extends StatelessWidget {
  const LoftifyFloatingCapsule({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.enableBlur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool enableBlur;

  static const double blurSigma = 16;

  static bool shouldUseBlur(
    MediaQueryData mediaQuery, {
    required bool enabled,
  }) {
    return enabled &&
        !kIsWeb &&
        !mediaQuery.highContrast &&
        !mediaQuery.disableAnimations &&
        !mediaQuery.accessibleNavigation;
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final mediaQuery = MediaQuery.of(context);
    final useBlur = shouldUseBlur(mediaQuery, enabled: enableBlur);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(design.radii.full);
    final surface = useBlur
        ? design.colors.surfaceRaised.withValues(alpha: isDark ? 0.86 : 0.82)
        : design.colors.surfaceRaised;
    final borderColor = mediaQuery.highContrast
        ? design.colors.outlineStrong
        : design.colors.outline.withValues(alpha: isDark ? 0.9 : 0.72);
    final content = DecoratedBox(
      key: const ValueKey('loftify-floating-capsule-surface'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: mediaQuery.highContrast
              ? design.borders.regular
              : design.borders.hairline,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: design.shadows.floating,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: useBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}

/// Cached-account avatar used by Home and Search floating headers.
class LoftifyNavigationAvatarButton extends StatefulWidget {
  const LoftifyNavigationAvatarButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.enableBlur = true,
  });

  final VoidCallback onPressed;
  final String semanticLabel;
  final bool enableBlur;

  @override
  State<LoftifyNavigationAvatarButton> createState() =>
      _LoftifyNavigationAvatarButtonState();
}

class _LoftifyNavigationAvatarButtonState
    extends State<LoftifyNavigationAvatarButton> {
  late final Future<FullBlogInfo?> _userInfo = HiveUtil.getUserInfo();

  @override
  Widget build(BuildContext context) {
    return LoftifyFloatingCapsule(
      enableBlur: widget.enableBlur,
      padding: const EdgeInsets.all(5),
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        onTap: widget.onPressed,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: FutureBuilder<FullBlogInfo?>(
            future: _userInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              return ItemBuilder.buildAvatar(
                context: context,
                imageUrl: info?.bigAvaImg ?? '',
                size: 38,
                showLoading: false,
                showBorder: false,
                useDefaultAvatar: info == null,
                clickable: false,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A single circular control carried by a floating capsule.
class LoftifyFloatingHeaderAction extends StatelessWidget {
  const LoftifyFloatingHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enableBlur = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    return LoftifyFloatingCapsule(
      enableBlur: enableBlur,
      child: ChewieIconButton(
        icon: icon,
        tooltip: tooltip,
        tapTargetSize: LoftifyFloatingNavigationHeader.height,
        onPressed: onPressed,
      ),
    );
  }
}

/// Compact title carried by the center slot of a primary navigation header.
class LoftifyFloatingHeaderTitle extends StatelessWidget {
  const LoftifyFloatingHeaderTitle({
    super.key,
    required this.title,
    this.enableBlur = true,
  });

  final String title;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LoftifyFloatingCapsule(
      enableBlur: enableBlur,
      padding: EdgeInsets.symmetric(horizontal: design.spacing.xl),
      child: Center(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: design.typography.sectionTitle,
        ),
      ),
    );
  }
}
