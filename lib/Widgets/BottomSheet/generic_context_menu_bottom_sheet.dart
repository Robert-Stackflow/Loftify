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

import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';

import '../../Utils/responsive_util.dart';
import '../Item/item_builder.dart';

class GenericContextMenuBottomSheet extends StatefulWidget {
  const GenericContextMenuBottomSheet({
    super.key,
    required this.menu,
  });

  final GenericContextMenu menu;

  @override
  GenericContextMenuBottomSheetState createState() =>
      GenericContextMenuBottomSheetState();
}

class GenericContextMenuBottomSheetState
    extends State<GenericContextMenuBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isWideLandscape()
                    ? const Radius.circular(20)
                    : Radius.zero),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ],
              ),
              for (var config in widget.menu.buttonConfigs)
                _buildConfigItem(config),
            ],
          ),
        ),
      ],
    );
  }

  _buildConfigItem(ContextMenuButtonConfig? config) {
    if (config == null || config.type == ContextMenuButtonConfigType.divider) {
      return ItemBuilder.buildDivider(
        context,
        width: 1.5,
        vertical: 12,
        horizontal: 16,
      );
    } else {
      return Material(
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            config.onPressed?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (config.icon != null) config.icon!,
                if (config.icon != null) const SizedBox(width: 10),
                Text(
                  config.label,
                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                        fontSizeDelta: ResponsiveUtil.isMobile() ? 2 : 0,
                        color: config.textColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
