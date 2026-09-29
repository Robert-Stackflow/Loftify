import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/lottie_files.dart';

import '../../Models/cloud_control.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';

class EggScreen extends StatefulWidget {
  const EggScreen({super.key});

  static const String routeName = "/setting/egg";

  @override
  State<EggScreen> createState() => _EggScreenState();
}

class _EggScreenState extends BaseDynamicState<EggScreen>
    with TickerProviderStateMixin {
  Widget? celebrateWidget;
  bool _showCelebrate = false;
  late AnimationController _celebrateController;
  bool overrideCloudControl = ChewieHiveUtil.getBool(
      HiveUtil.overrideCloudControlKey,
      defaultValue: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _celebrateController = AnimationController(
          duration: const Duration(seconds: 5), vsync: this);
      celebrateWidget = LottieFiles.buildAnimation(
        LottieFiles.celebrate,
        size: MediaQuery.sizeOf(context).width * 2,
        controller: _celebrateController,
      );
      diaplayCelebrate();
    });
  }

  @override
  void dispose() {
    _celebrateController.dispose();
    super.dispose();
  }

  diaplayCelebrate() {
    if (_showCelebrate) return;
    _showCelebrate = true;
    _celebrateController.forward(from: 0);
    _celebrateController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showCelebrate = false;
        setState(() {});
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: ResponsiveAppBar(
            showBack: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: EasyRefresh(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ClickableWrapper(
                    child: GestureDetector(
                      onTap: diaplayCelebrate,
                      child: Hero(
                        tag: "logo-egg",
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/logo.png',
                              height: 120,
                              width: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ContainerItem(
                  backgroundColor: Theme.of(context).canvasColor,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: CustomHtmlWidget(
                      content: appLocalizations.eggMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                ..._buildButton(),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _showCelebrate,
          child: Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: celebrateWidget,
            ),
          ),
        ),
      ],
    );
  }

  _buildButton() {
    return [
      const SizedBox(height: 10),
      CheckboxItem(
        value: overrideCloudControl,
        title: appLocalizations.overrideCloudControl,
        description: appLocalizations.overrideCloudControlDescription,
        roundTop: true,
        roundBottom: true,
        onTap: () {
          setState(() {
            overrideCloudControl = !overrideCloudControl;
            ChewieHiveUtil.put(
                HiveUtil.overrideCloudControlKey, overrideCloudControl);
            if (overrideCloudControl) {
              controlProvider.globalControl =
                  LoftifyControl.getOverridedCloudControl(
                      controlProvider.originalCloudControl);
            } else {
              controlProvider.globalControl =
                  controlProvider.originalCloudControl;
            }
          });
        },
      ),
    ];
  }
}
