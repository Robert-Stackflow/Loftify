/*
 * Copyright (c) 2025 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Utils/app_provider.dart';
import '../../l10n/l10n.dart';
import 'about_setting_screen.dart';
import 'apperance_setting_screen.dart';
import 'experiment_setting_screen.dart';
import 'general_setting_screen.dart';
import 'image_setting_screen.dart';
import 'lofter_basic_setting_screen.dart';

/// Wide-screen settings navigation using the same pages and design foundations
/// as the mobile settings route.
class SettingNavigationScreen extends StatefulWidget {
  final int initPageIndex;

  const SettingNavigationScreen({
    super.key,
    this.initPageIndex = 0,
  });

  @override
  State<SettingNavigationScreen> createState() =>
      _SettingNavigationScreenState();
}

class _SettingNavigationScreenState
    extends BaseDynamicState<SettingNavigationScreen> {
  late int _selectedIndex;

  late final List<Widget> _pages = [
    GeneralSettingScreen(key: generalSettingScreenKey),
    const AppearanceSettingScreen(),
    const ImageSettingScreen(),
    const LofterBasicSettingScreen(),
    const ExperimentSettingScreen(),
    const AboutSettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initPageIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ChewieTheme.scaffoldBackgroundColor,
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 196,
            backgroundColor: ChewieTheme.scaffoldBackgroundColor,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
            selectedIconTheme: IconThemeData(color: colorScheme.primary),
            selectedLabelTextStyle: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            labelType: NavigationRailLabelType.none,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              _destination(
                LucideIcons.settings2,
                appLocalizations.generalSetting,
              ),
              _destination(
                LucideIcons.paintbrushVertical,
                appLocalizations.appearanceSetting,
              ),
              _destination(LucideIcons.image, appLocalizations.imageSetting),
              _destination(
                LucideIcons.settings,
                appLocalizations.lofterBasicSetting,
              ),
              _destination(
                LucideIcons.flaskConical,
                appLocalizations.experimentSetting,
              ),
              _destination(LucideIcons.info, appLocalizations.about),
            ],
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: ChewieTheme.dividerColor,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  NavigationRailDestination _destination(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon),
      selectedIcon: Icon(icon),
      label: Text(label),
    );
  }
}
