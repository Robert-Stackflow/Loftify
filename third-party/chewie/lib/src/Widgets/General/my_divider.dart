import 'package:flutter/material.dart';

class MyDivider extends StatefulWidget {
  final double vertical;
  final double horizontal;
  final double? width;
  final EdgeInsets? margin;

  const MyDivider({
    super.key,
    this.vertical = 8,
    this.horizontal = 16,
    this.width,
    this.margin,
  });

  @override
  State<MyDivider> createState() => _MyDividerState();
}

class _MyDividerState extends State<MyDivider> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Container(
      margin: widget.margin ??
          EdgeInsets.symmetric(
            vertical: widget.vertical,
            horizontal: widget.horizontal,
          ),
      height: widget.width ?? 0.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}
