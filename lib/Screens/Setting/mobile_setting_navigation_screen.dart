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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Utils/app_provider.dart';
import '../../l10n/l10n.dart';
import 'apperance_setting_screen.dart';
import 'experiment_setting_screen.dart';
import 'general_setting_screen.dart';
import 'image_setting_screen.dart';
import 'lofter_basic_setting_screen.dart';

class MobileSettingNavigationScreen extends StatefulWidget {
  const MobileSettingNavigationScreen({super.key});

  static const String routeName = "/setting/navigation";

  @override
  State<MobileSettingNavigationScreen> createState() =>
      _MobileSettingNavigationScreenState();
}

class _MobileSettingNavigationScreenState
    extends BaseDynamicState<MobileSettingNavigationScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveAppBar(
          title: appLocalizations.setting,
          showBack: true,
          showBorder: true,
          actions: const [
            BlankIconButton(),
            SizedBox(width: 5),
          ],
        ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              CaptionItem(
                context: context,
                title: appLocalizations.setting,
                children: [
                  EntryItem(
                    title: appLocalizations.generalSetting,
                    leading: LucideIcons.settings2,
                    showLeading: true,
                    onTap: () {
                      RouteUtil.pushCupertinoRoute(
                        context,
                        GeneralSettingScreen(key: generalSettingScreenKey),
                      );
                    },
                  ),
                  EntryItem(
                    title: appLocalizations.appearanceSetting,
                    leading: LucideIcons.paintbrushVertical,
                    showLeading: true,
                    onTap: () {
                      RouteUtil.pushCupertinoRoute(
                          context, const AppearanceSettingScreen());
                    },
                  ),
                  EntryItem(
                    title: appLocalizations.imageSetting,
                    leading: LucideIcons.image,
                    showLeading: true,
                    onTap: () {
                      RouteUtil.pushCupertinoRoute(
                          context, const ImageSettingScreen());
                    },
                  ),
                  EntryItem(
                    title: appLocalizations.lofterBasicSetting,
                    leading: LucideIcons.settings,
                    showLeading: true,
                    onTap: () {
                      RouteUtil.pushCupertinoRoute(
                          context, const LofterBasicSettingScreen());
                    },
                  ),
                  EntryItem(
                    title: appLocalizations.experimentSetting,
                    leading: LucideIcons.flaskConical,
                    showLeading: true,
                    onTap: () {
                      RouteUtil.pushCupertinoRoute(
                          context, const ExperimentSettingScreen());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
