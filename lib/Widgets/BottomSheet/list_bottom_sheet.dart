import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../Theme/loftify_design_theme.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';

class TileList extends StatelessWidget {
  const TileList(
    this.children, {
    required this.title,
    this.onCloseTap,
    this.showTitle = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.showCancel = false,
    super.key,
  });

  TileList.fromOptions(
    List<Tuple2<String, dynamic>> options,
    Function onSelected, {
    List<dynamic> redOptions = const [],
    dynamic selected,
    this.onCloseTap,
    this.title = "",
    this.showTitle = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    required BuildContext context,
    this.showCancel = false,
    super.key,
  }) : children = options
            .map(
              (option) => LoftifyMenuItem(
                label: option.item1,
                selected: option.item2 == selected,
                showTrailing: option.item2 == selected,
                status: redOptions.contains(option.item2)
                    ? LoftifyMenuStatus.danger
                    : LoftifyMenuStatus.normal,
                onTap: () => onSelected(option.item2),
              ),
            )
            .toList();

  final Iterable<Widget> children;
  final String title;
  final Function()? onCloseTap;
  final bool showTitle;
  final bool showCancel;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: LoftifyPanel(
        title: showTitle ? title : null,
        centerTitle: false,
        expandBody: true,
        body: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            design.spacing.lg,
            design.spacing.xs,
            design.spacing.lg,
            design.spacing.sm,
          ),
          children: [
            for (final child in children)
              Padding(
                padding: EdgeInsets.only(bottom: design.spacing.xs),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(design.radii.control),
                  child: ColoredBox(
                    color: design.colors.surfaceMuted,
                    child: child,
                  ),
                ),
              ),
          ],
        ),
        footer: showCancel
            ? LoftifyButton(
                label: MaterialLocalizations.of(context).cancelButtonLabel,
                variant: LoftifyButtonVariant.secondary,
                onPressed: onCloseTap ?? () => Navigator.of(context).maybePop(),
                expand: true,
              )
            : null,
        footerPadding: EdgeInsets.fromLTRB(
          design.spacing.lg,
          design.spacing.sm,
          design.spacing.lg,
          design.spacing.lg,
        ),
      ),
    );
  }
}
