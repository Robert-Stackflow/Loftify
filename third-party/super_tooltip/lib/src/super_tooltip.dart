import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:super_tooltip/src/utils.dart';

import 'bubble_shape.dart';
import 'enums.dart';
import 'shape_overlay.dart';
import 'super_tooltip_controller.dart';
import 'tooltip_position_delegate.dart';

class SuperTooltip extends StatefulWidget {
  final Widget content;
  final TooltipDirection popupDirection;
  final SuperTooltipController? controller;
  final void Function()? onLongPress;
  final void Function()? onShow;
  final void Function()? onHide;
  final bool snapsFarAwayVertically;
  final bool snapsFarAwayHorizontally;
  final bool? hasShadow;
  final Color? shadowColor;
  final double? shadowBlurRadius;
  final double? shadowSpreadRadius;
  final Offset? shadowOffset;
  final double? top, right, bottom, left;
  final double minimumOutsideMargin;
  final double verticalOffset;
  final Widget? child;
  final Color borderColor;
  final BoxConstraints constraints;
  final Color? backgroundColor;
  final Decoration? decoration;
  final double elevation;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final double borderRadius;
  final double borderWidth;
  final bool? showBarrier;
  final Color? barrierColor;
  final Rect? touchThroughArea;
  final ClipAreaShape touchThroughAreaShape;
  final double touchThroughAreaCornerRadius;
  final EdgeInsetsGeometry overlayDimensions;
  final EdgeInsetsGeometry bubbleDimensions;
  final bool hideTooltipOnTap;
  final bool hideTooltipOnBarrierTap;
  final bool toggleOnTap;
  final bool enableHover;

  //filter
  final bool showDropBoxFilter;
  final double sigmaX;
  final double sigmaY;

  SuperTooltip({
    Key? key,
    required this.content,
    this.popupDirection = TooltipDirection.down,
    this.controller,
    this.onLongPress,
    this.onShow,
    this.onHide,
    /**
     * showCloseButton
     * This will enable the closeButton
     */
    this.showBarrier,
    this.barrierColor,
    this.snapsFarAwayVertically = false,
    this.snapsFarAwayHorizontally = false,
    this.hasShadow,
    this.shadowColor,
    this.shadowBlurRadius,
    this.shadowSpreadRadius,
    this.shadowOffset,
    this.top,
    this.right,
    this.bottom,
    this.left,
    // TD: Make edgeinsets instead
    this.minimumOutsideMargin = 20.0,
    this.verticalOffset = 0.0,
    this.elevation = 0.0,
    // TD: The native flutter tooltip uses verticalOffset
    //  to space the tooltip from the child. But we'll likely
    // need just offset, since it's 4 way directional
    // this.verticalOffset = 24.0,
    this.backgroundColor,
    this.decoration,
    this.child,
    this.borderColor = Colors.transparent,
    this.constraints = const BoxConstraints(
      minHeight: 0.0,
      maxHeight: double.infinity,
      minWidth: 0.0,
      maxWidth: double.infinity,
    ),
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.fadeOutDuration = const Duration(milliseconds: 0),
    this.touchThroughAreaShape = ClipAreaShape.oval,
    this.touchThroughAreaCornerRadius = 5.0,
    this.touchThroughArea,
    this.borderWidth = 0.0,
    this.borderRadius = 10.0,
    this.overlayDimensions = const EdgeInsets.all(10),
    this.bubbleDimensions = const EdgeInsets.all(10),
    this.hideTooltipOnTap = false,
    this.sigmaX = 5.0,
    this.sigmaY = 5.0,
    this.showDropBoxFilter = false,
    this.hideTooltipOnBarrierTap = true,
    this.toggleOnTap = false,
    this.enableHover = true,
  })  : assert(showDropBoxFilter ? showBarrier ?? false : true,
            'showDropBoxFilter or showBarrier can\'t be false | null'),
        super(key: key);

  static Key insideCloseButtonKey = const Key("InsideCloseButtonKey");
  static Key outsideCloseButtonKey = const Key("OutsideCloseButtonKey");
  static Key barrierKey = const Key("barrierKey");
  static Key bubbleKey = const Key("bubbleKey");

  @override
  State createState() => _SuperTooltipState();
}

class _SuperTooltipState extends State<SuperTooltip>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  SuperTooltipController? _superTooltipController;
  OverlayEntry? _entry;
  OverlayEntry? _barrierEntry;
  OverlayEntry? blur;

  late bool showBarrier;
  Color? barrierColor;
  late bool hasShadow;
  late Color shadowColor;
  late double shadowBlurRadius;
  late double shadowSpreadRadius;
  late Offset shadowOffset;
  late bool showBlur;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      reverseDuration: widget.fadeOutDuration,
      vsync: this,
    );
    _superTooltipController = widget.controller ?? SuperTooltipController();
    _superTooltipController!.addListener(_onChangeNotifier);

    // TD: Mouse stuff
    super.initState();
  }

  @override
  void didUpdateWidget(SuperTooltip oldWidget) {
    if (_superTooltipController != widget.controller) {
      _superTooltipController!.removeListener(_onChangeNotifier);
      _superTooltipController = widget.controller ?? SuperTooltipController();
      _superTooltipController!.addListener(_onChangeNotifier);
    }
    super.didUpdateWidget(oldWidget);
  }

  // @override
  @override
  void dispose() {
    if (_entry != null) _removeEntries();
    _superTooltipController?.removeListener(_onChangeNotifier);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    showBarrier = widget.showBarrier ?? true;
    barrierColor = widget.barrierColor ?? Colors.black26;
    hasShadow = widget.hasShadow ?? true;
    shadowColor = widget.shadowColor ?? Theme.of(context).shadowColor;
    shadowBlurRadius = widget.shadowBlurRadius ?? 10.0;
    shadowSpreadRadius = widget.shadowSpreadRadius ?? 1.0;
    shadowOffset = widget.shadowOffset ?? const Offset(0, 4);
    showBlur = widget.showDropBoxFilter;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enableHover) _superTooltipController!.showTooltip();
        },
        onExit: (_) {
          if (widget.enableHover) _superTooltipController!.hideTooltip();
        },
        child: GestureDetector(
          onTap: () {
            if (widget.toggleOnTap && _superTooltipController!.isVisible) {
              _superTooltipController!.hideTooltip();
            } else {
              _superTooltipController!.showTooltip();
            }
          },
          onLongPress: widget.onLongPress,
          child: widget.child,
        ),
      ),
    );
  }

  void _onChangeNotifier() {
    switch (_superTooltipController!.event) {
      case Event.show:
        _showTooltip();
        break;
      case Event.hide:
        _hideTooltip();
        break;
    }
  }

  void _createOverlayEntries() {
    final renderBox = context.findRenderObject() as RenderBox;

    final overlayState = Overlay.of(context);
    RenderBox? overlay;

    // ignore: unnecessary_null_comparison
    if (overlayState != null) {
      overlay = overlayState.context.findRenderObject() as RenderBox?;
    }

    final size = renderBox.size;
    var target = renderBox.localToGlobal(size.center(Offset.zero));
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    final offsetToTarget = Offset(
      -target.dx + size.width * 2,
      -target.dy + size.height / 2,
    );
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).cardColor;

    print(
        "${size} ${size.center(Offset.zero)} ${renderBox.localToGlobal(Offset.zero)} ${target} ${offsetToTarget}");

    var constraints = widget.constraints;
    var preferredDirection = widget.popupDirection;
    var left = widget.left;
    var right = widget.right;
    var top = widget.top;
    var bottom = widget.bottom;

    if (widget.snapsFarAwayVertically) {
      constraints = constraints.copyWith(maxHeight: null);
      left = right = 0.0;

      if (overlay != null) {
        if (target.dy > overlay.size.center(Offset.zero).dy) {
          preferredDirection = TooltipDirection.up;
          top = 0.0;
        } else {
          preferredDirection = TooltipDirection.down;
          bottom = 0.0;
        }
      } else {
        // overlay is null - set default values
        preferredDirection = TooltipDirection.down;
        bottom = 0.0;
      }
    } else if (widget.snapsFarAwayHorizontally) {
      constraints = constraints.copyWith(maxHeight: null);
      top = bottom = 0.0;

      if (overlay != null) {
        if (target.dx < overlay.size.center(Offset.zero).dx) {
          preferredDirection = TooltipDirection.right;
          right = 0.0;
        } else {
          preferredDirection = TooltipDirection.left;
          left = 0.0;
        }
      } else {
        // overlay is null - set default values
        preferredDirection = TooltipDirection.left;
        left = 0.0;
      }
    }

    _barrierEntry = showBarrier
        ? OverlayEntry(
            builder: (context) => FadeTransition(
              opacity: animation,
              child: GestureDetector(
                onTap: widget.hideTooltipOnBarrierTap
                    ? _superTooltipController!.hideTooltip
                    : null,
                child: Container(
                  key: SuperTooltip.barrierKey,
                  decoration: ShapeDecoration(
                    shape: ShapeOverlay(
                      clipAreaCornerRadius: widget.touchThroughAreaCornerRadius,
                      clipAreaShape: widget.touchThroughAreaShape,
                      clipRect: widget.touchThroughArea,
                      barrierColor: barrierColor,
                      overlayDimensions: widget.overlayDimensions,
                    ),
                  ),
                ),
              ),
            ),
          )
        : null;

    blur = showBlur
        ? OverlayEntry(
            builder: (BuildContext context) => FadeTransition(
              opacity: animation,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.sigmaX,
                  sigmaY: widget.sigmaY,
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          )
        : null;

    _entry = OverlayEntry(
      builder: (BuildContext context) => FadeTransition(
        opacity: animation,
        child: Center(
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: offsetToTarget,
            child: CustomSingleChildLayout(
              delegate: TooltipPositionDelegate(
                preferredDirection: preferredDirection,
                constraints: constraints,
                top: top,
                bottom: bottom,
                left: left,
                right: right,
                target: target,
                // verticalOffset: widget.verticalOffset,
                overlay: overlay,
                margin: widget.minimumOutsideMargin,
                snapsFarAwayHorizontally: widget.snapsFarAwayHorizontally,
                snapsFarAwayVertically: widget.snapsFarAwayVertically,
              ),
              // TD:  Text fields and such will need a material ancestor
              // In order to function properly. Need to find more elegant way
              // to add this.
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.hideTooltipOnTap)
                          _superTooltipController!.hideTooltip();
                      },
                      child: Container(
                        key: SuperTooltip.bubbleKey,
                        margin: SuperUtils.getTooltipMargin(
                            preferredDirection: preferredDirection),
                        padding: SuperUtils.getTooltipPadding(),
                        decoration: widget.decoration ??
                            ShapeDecoration(
                              color: backgroundColor,
                              shadows: hasShadow
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        blurRadius: shadowBlurRadius,
                                        spreadRadius: shadowSpreadRadius,
                                        color: shadowColor,
                                        offset: shadowOffset,
                                      ).scale(2),
                                    ]
                                  : null,
                              shape: BubbleShape(
                                borderColor: widget.borderColor,
                                borderRadius: widget.borderRadius,
                                borderWidth: widget.borderWidth,
                                bottom: bottom,
                                left: left,
                                preferredDirection: preferredDirection,
                                right: right,
                                target: target,
                                top: top,
                                bubbleDimensions: widget.bubbleDimensions,
                              ),
                            ),
                        child: widget.content,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // ignore: unnecessary_null_comparison
    if (overlayState != null) {
      overlayState.insertAll([
        if (showBlur) blur!,
        if (showBarrier) _barrierEntry!,
        _entry!,
      ]);
    }
  }

  _showTooltip() async {
    widget.onShow?.call();

    // Already visible.
    if (_entry != null) return;

    _createOverlayEntries();

    await _animationController
        .forward()
        .whenComplete(_superTooltipController!.complete);
  }

  _removeEntries() {
    _entry?.remove();
    _entry = null;
    _barrierEntry?.remove();
    _entry = null;
    blur?.remove();
  }

  _hideTooltip() async {
    widget.onHide?.call();
    await _animationController
        .reverse()
        .whenComplete(_superTooltipController!.complete);

    _removeEntries();
  }
}
