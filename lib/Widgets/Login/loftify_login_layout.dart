import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';

@immutable
class LoftifyLoginMethod {
  const LoftifyLoginMethod({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// Shared content shell for every login method.
///
/// The old screens positioned the alternative methods over the form. Keeping
/// everything in one scroll chain preserves the spacious bottom alignment on
/// tall phones while making all fields and actions reachable with a keyboard,
/// split screen, landscape, large text, and narrow Android displays.
class LoftifyLoginLayout extends StatelessWidget {
  const LoftifyLoginLayout({
    super.key,
    required this.formChildren,
    required this.primaryAction,
    required this.alternativeTitle,
    required this.alternativeMethods,
  });

  final List<Widget> formChildren;
  final Widget primaryAction;
  final String alternativeTitle;
  final List<LoftifyLoginMethod> alternativeMethods;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = design.grid.pagePaddingFor(constraints.maxWidth);
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compactHeight = constraints.maxHeight < 560 || textScale > 1.35;
        final top = compactHeight ? design.spacing.xl : design.spacing.hero;
        final sectionGap = compactHeight ? design.spacing.huge : 56.0;
        final bottom =
            design.spacing.xxxl + MediaQuery.paddingOf(context).bottom;

        return ScrollConfiguration(
          behavior: const _LoginScrollBehavior(),
          child: SingleChildScrollView(
            key: const ValueKey('loftify-login-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - top - bottom).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...formChildren,
                        SizedBox(height: design.spacing.huge),
                        Align(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: primaryAction,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(height: sectionGap),
                        _AlternativeMethods(
                          title: alternativeTitle,
                          methods: alternativeMethods,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlternativeMethods extends StatelessWidget {
  const _AlternativeMethods({required this.title, required this.methods});

  final String title;
  final List<LoftifyLoginMethod> methods;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return Column(
      key: const ValueKey('loftify-login-alternatives'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: design.colors.outline)),
            Flexible(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: design.spacing.lg),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: design.typography.label.copyWith(
                    color: design.colors.textMuted,
                  ),
                ),
              ),
            ),
            Expanded(child: Divider(color: design.colors.outline)),
          ],
        ),
        SizedBox(height: design.spacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: design.spacing.xxl,
          runSpacing: design.spacing.md,
          children: [
            for (final method in methods)
              Semantics(
                button: true,
                label: method.label,
                child: Tooltip(
                  message: method.label,
                  child: IconButton.outlined(
                    onPressed: method.onPressed,
                    icon: Icon(method.icon, size: design.icons.regular),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LoginScrollBehavior extends MaterialScrollBehavior {
  const _LoginScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
