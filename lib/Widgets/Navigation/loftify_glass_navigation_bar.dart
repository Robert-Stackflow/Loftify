import 'dart:async';
import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class LoftifyNavigationDestination {
  const LoftifyNavigationDestination({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
}

/// A floating bottom navigation surface that keeps content visible beneath it.
///
/// Blur is automatically disabled for web, high-contrast, reduced-motion and
/// accessible-navigation environments. [enableBlur] provides an explicit
/// solid fallback for devices where transparency is undesirable or expensive.
class LoftifyGlassNavigationBar extends StatelessWidget {
  const LoftifyGlassNavigationBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    this.onDoubleTap,
    this.enableBlur = true,
  })  : assert(destinations.length >= 2),
        assert(currentIndex >= 0 && currentIndex < destinations.length);

  final List<LoftifyNavigationDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int>? onDoubleTap;
  final bool enableBlur;

  static const double barHeight = 64;
  static const double horizontalMargin = 10;
  static const double blurSigma = 18;

  static bool shouldUseBlur(
    MediaQueryData mediaQuery, {
    required bool enabled,
    bool isWeb = kIsWeb,
    bool? platformReduceMotion,
  }) {
    final reduceMotion = platformReduceMotion ??
        WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures.reduceMotion;
    return enabled &&
        !isWeb &&
        !reduceMotion &&
        !mediaQuery.disableAnimations &&
        !mediaQuery.accessibleNavigation &&
        !mediaQuery.highContrast;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useBlur = shouldUseBlur(mediaQuery, enabled: enableBlur);
    final bottomInset = mediaQuery.viewPadding.bottom;
    final surfaceColor = theme.colorScheme.surface;
    final backgroundColor = useBlur
        ? surfaceColor.withValues(alpha: isDark ? 0.78 : 0.72)
        : surfaceColor;
    final borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.78 : 0.9,
    );
    final radius = BorderRadius.circular(24);
    final content = DecoratedBox(
      key: const ValueKey('loftify-glass-navigation-surface'),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: List.generate(destinations.length, (index) {
            return Expanded(
              child: _LoftifyNavigationItem(
                destination: destinations[index],
                selected: currentIndex == index,
                onTap: () => onSelect(index),
                onDoubleTap:
                    onDoubleTap == null ? null : () => onDoubleTap!(index),
              ),
            );
          }),
        ),
      ),
    );

    return RepaintBoundary(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalMargin,
            6,
            horizontalMargin,
            bottomInset + 6,
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
      ),
    );
  }
}

class _LoftifyNavigationItem extends StatefulWidget {
  const _LoftifyNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.onDoubleTap,
  });

  final LoftifyNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<_LoftifyNavigationItem> createState() => _LoftifyNavigationItemState();
}

class _LoftifyNavigationItemState extends State<_LoftifyNavigationItem> {
  bool _pressed = false;
  Timer? _doubleTapWindow;

  @override
  void dispose() {
    _doubleTapWindow?.cancel();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    widget.onTap();
    if (widget.onDoubleTap == null) return;
    if (_doubleTapWindow?.isActive == true) {
      _doubleTapWindow?.cancel();
      _doubleTapWindow = null;
      widget.onDoubleTap!();
      return;
    }
    _doubleTapWindow = Timer(
      const Duration(milliseconds: 300),
      () => _doubleTapWindow = null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;
    final foregroundColor = widget.selected ? selectedColor : unselectedColor;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    final semanticLabel = widget.destination.badgeCount > 0
        ? '${widget.destination.label}, ${widget.destination.badgeCount}'
        : widget.destination.label;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: _handleTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: widget.selected
                    ? selectedColor.withValues(alpha: 0.11)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.selected
                      ? selectedColor.withValues(alpha: 0.22)
                      : Colors.transparent,
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavigationIcon(
                    icon: widget.destination.icon,
                    badgeCount: widget.destination.badgeCount,
                    color: foregroundColor,
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    style: (theme.textTheme.labelSmall ?? const TextStyle())
                        .copyWith(
                      color: foregroundColor,
                      fontSize: 10.5,
                      height: 1,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(
                      widget.destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.icon,
    required this.badgeCount,
    required this.color,
  });

  final IconData icon;
  final int badgeCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 23,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ChewieIcon(icon, size: 22, color: color),
          if (badgeCount > 0)
            Positioned(
              top: -3,
              right: -7,
              child: Semantics(
                label: '$badgeCount',
                child: Container(
                  constraints: const BoxConstraints(minWidth: 15),
                  height: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    maxLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 8,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
