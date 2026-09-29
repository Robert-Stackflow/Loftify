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

  Radius radius = const Radius.circular(20);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final entries = widget.menu.entries.toList();
    final firstHeader = entries.isNotEmpty && entries.first is MenuHeader
        ? entries.first as MenuHeader
        : null;
    final listEntries = firstHeader == null ? entries : entries.skip(1);
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!ResponsiveUtil.isWideDevice())
              SizedBox(
                height: 24,
                child: Center(
                  child: Container(
                    key: const ValueKey('context-menu-handle'),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.46),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            if (firstHeader != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    firstHeader.disableUppercase
                        ? firstHeader.text
                        : firstHeader.text.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(16, firstHeader == null ? 8 : 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var config in listEntries) _buildConfigItem(config),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
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
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pop();
              config.onPressed?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (config.type != MenuItemType.checkbox &&
                      config.iconData != null) ...[
                    _buildIcon(config.iconData!, iconColor),
                    const SizedBox(width: 12),
                  ],
                  if (config.type == MenuItemType.checkbox) ...[
                    config.checked
                        ? _buildIcon(ChewieIcons.check, iconColor)
                        : const SizedBox(width: 34, height: 34),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      config.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                          ),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
