import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';

const double loftifyPageMaxContentWidth = 1180;

/// A shared centered content column for wide pages. Callers keep the original
/// phone tree and opt in only for their desktop/tablet layouts.
class LoftifyContentFrame extends StatelessWidget {
  const LoftifyContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.design.spacing.xl),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: loftifyPageMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
