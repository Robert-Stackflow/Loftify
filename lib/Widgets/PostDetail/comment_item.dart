import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({
    super.key,
    required this.avatar,
    required this.header,
    required this.content,
    required this.metadata,
    this.trailing,
    this.replies = const [],
    this.footer,
    this.onTap,
    this.nested = false,
    this.margin,
  });

  final Widget avatar;
  final Widget header;
  final Widget content;
  final Widget metadata;
  final Widget? trailing;
  final List<Widget> replies;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool nested;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ??
          (nested
              ? const EdgeInsets.only(top: 10)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            SizedBox(width: nested ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: nested ? 28 : 38),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: header,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 10),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  content,
                  const SizedBox(height: 5),
                  metadata,
                  if (replies.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    ...replies,
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: 8),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
