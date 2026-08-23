import 'package:flutter/material.dart';

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.children,
    this.horizontalPadding = 10,
    this.spacing = 4,
  });

  final List<Widget> children;
  final double horizontalPadding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: Container(
          height: 64,
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index != children.length - 1) SizedBox(width: spacing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DetailActionSlot extends StatelessWidget {
  const DetailActionSlot({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class DetailActionButton extends StatelessWidget {
  const DetailActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.foregroundColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).iconTheme.color;
    return DetailActionSlot(
      semanticLabel: label,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconTheme.of(context).copyWith(color: color, size: 24),
              child: icon,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
