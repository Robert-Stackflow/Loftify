import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class ToggleIconButton extends StatefulWidget {
  final Duration resetDuration;
  final Icon iconA;
  final Icon iconB;
  final String? tooltip;
  final VoidCallback? onPressed;

  const ToggleIconButton({
    super.key,
    this.tooltip,
    this.onPressed,
    this.resetDuration = const Duration(seconds: 2),
    this.iconA = const Icon(ChewieIcons.alarm),
    this.iconB = const Icon(ChewieIcons.time),
  });

  @override
  State<ToggleIconButton> createState() => _ToggleIconButtonState();
}

class _ToggleIconButtonState extends State<ToggleIconButton> {
  bool _isA = true;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    widget.onPressed?.call();
    _timer?.cancel();
    setState(() => _isA = false);

    _timer = Timer(widget.resetDuration, () {
      if (mounted) {
        setState(() => _isA = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !_isA,
      child: PressableAnimation(
        onTap: _handlePress,
        child: HoverIconButton(
          tooltip: widget.tooltip,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInBack,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: _isA
                ? Container(
                    key: const ValueKey('iconA'),
                    child: widget.iconA,
                  )
                : Container(
                    key: const ValueKey('iconB'),
                    child: widget.iconB,
                  ),
          ),
          onPressed: _handlePress,
        ),
      ),
    );
  }
}
