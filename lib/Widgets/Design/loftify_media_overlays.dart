import 'package:flutter/material.dart';

/// Stable cover scrim for white content rendered over user-provided artwork.
///
/// The lightest stop keeps primary and secondary content readable even when
/// the source image is entirely white. Keep this shared across profile,
/// collection and grain headers so their contrast does not drift independently.
class LoftifyCoverScrim extends StatelessWidget {
  const LoftifyCoverScrim({super.key});

  static const topColor = Color.fromRGBO(0, 0, 0, 0.58);
  static const bottomColor = Color.fromRGBO(0, 0, 0, 0.72);
  static const secondaryForeground = Color.fromRGBO(255, 255, 255, 0.88);

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      key: ValueKey('loftify-cover-scrim'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
    );
  }
}
