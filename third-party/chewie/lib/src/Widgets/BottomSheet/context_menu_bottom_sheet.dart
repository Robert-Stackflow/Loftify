/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class ContextMenuBottomSheet extends StatefulWidget {
  const ContextMenuBottomSheet({
    super.key,
    required this.menu,
  });

  final FlutterContextMenu menu;

  @override
  ContextMenuBottomSheetState createState() => ContextMenuBottomSheetState();
}

class ContextMenuBottomSheetState extends State<ContextMenuBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  Radius radius = ChewieDimens.defaultRadius;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final obscuredBottom = max(
      mediaQuery.viewPadding.bottom,
      mediaQuery.viewInsets.bottom,
    );
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - obscuredBottom - 24;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: max(0, availableHeight)),
      child: Container(
        decoration: BoxDecoration(
          color: ChewieTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: radius,
            bottom: ResponsiveUtil.isWideDevice() ? radius : Radius.zero,
          ),
          border: ChewieTheme.responsiveBorder,
          boxShadow: ChewieTheme.defaultBoxShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!ResponsiveUtil.isWideDevice())
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(height: 36),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ChewieTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ],
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    14, ResponsiveUtil.isWideDevice() ? 14 : 0, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var config in widget.menu.entries)
                      _buildConfigItem(config),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(ContextMenuEntry config) {
    if (config is MenuHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            config.disableUppercase ? config.text : config.text.toUpperCase(),
            style: ChewieTheme.labelMedium.apply(
              color: ChewieTheme.textLightGreyColor,
            ),
          ),
        ),
      );
    }
    if (config is MenuDivider) {
      final thickness = config.thickness ?? 0.6;
      return Container(
        height: config.height ?? 13,
        margin: EdgeInsetsDirectional.only(
          start: config.indent ?? 8,
          end: config.endIndent ?? 8,
        ),
        alignment: Alignment.center,
        child: Container(
          height: thickness,
          decoration: BoxDecoration(
            color: config.color ?? ChewieTheme.dividerColor,
            borderRadius: BorderRadius.circular(thickness),
          ),
        ),
      );
    }
    if (config is! FlutterContextMenuItem) {
      return const SizedBox.shrink();
    }

    Color? textColor;
    if (config.type == MenuItemType.divider) {
      return const MyDivider(width: 0.6, vertical: 6, horizontal: 8);
    } else {
      Color iconColor = ChewieTheme.primaryColor;
      switch (config.status) {
        case MenuItemStatus.success:
          textColor = ChewieTheme.successColor;
          iconColor = ChewieTheme.successColor;
          break;
        case MenuItemStatus.warning:
          textColor = ChewieTheme.warningColor;
          iconColor = ChewieTheme.warningColor;
          break;
        case MenuItemStatus.error:
          textColor = ChewieTheme.errorColor;
          iconColor = ChewieTheme.errorColor;
          break;
        default:
          textColor = null;
          iconColor = ChewieTheme.primaryColor;
          break;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: ChewieTheme.canvasColor,
          borderRadius: ChewieDimens.borderRadius12,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: ChewieDimens.borderRadius12,
            onTap: () {
              Navigator.of(context).pop();
              config.onPressed?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  if (config.type != MenuItemType.checkbox &&
                      config.iconData != null) ...[
                    _buildIcon(config.iconData!, iconColor),
                    const SizedBox(width: 12),
                  ],
                  if (config.type == MenuItemType.checkbox) ...[
                    config.checked
                        ? _buildIcon(Icons.check_rounded, iconColor)
                        : const SizedBox(width: 34, height: 34),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      config.label,
                      style: ChewieTheme.bodyLarge.apply(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}
