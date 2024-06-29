import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class AutoSlideUpPanel extends StatefulWidget {
  final double minHeight;
  final double maxHeight;
  final Widget? child;
  final Widget Function(ScrollController controller)? panelBuilder;
  final void Function(double)? onPanelSlide;

  const AutoSlideUpPanel({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    this.child,
    this.onPanelSlide,
    this.panelBuilder,
  });

  @override
  State<AutoSlideUpPanel> createState() => _PokemonInfoCardState();
}

class _PokemonInfoCardState extends State<AutoSlideUpPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _autoSlideUpController;

  @override
  void initState() {
    _autoSlideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    )..forward();

    super.initState();
  }

  @override
  void dispose() {
    _autoSlideUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _autoSlideUpController,
      child: widget.child,
      builder: (_, child) {
        return SlidingUpPanel(
          minHeight: widget.minHeight * _autoSlideUpController.value,
          maxHeight: widget.maxHeight,
          boxShadow: null,
          color: Colors.transparent,
          panel: child,
          panelBuilder: widget.panelBuilder,
          onPanelSlide: widget.onPanelSlide,
        );
      },
    );
  }
}
