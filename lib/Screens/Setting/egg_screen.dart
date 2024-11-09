import 'package:flutter/material.dart';

import '../../Models/cloud_control.dart';
import '../../Utils/cloud_control_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/lottie_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class EggScreen extends StatefulWidget {
  const EggScreen({super.key});

  static const String routeName = "/setting/egg";

  @override
  State<EggScreen> createState() => _EggScreenState();
}

class _EggScreenState extends State<EggScreen> with TickerProviderStateMixin {
  Widget? celebrateWidget;
  bool _showCelebrate = false;
  late AnimationController _celebrateController;
  bool overrideCloudControl =
      HiveUtil.getBool(HiveUtil.overrideCloudControlKey, defaultValue: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _celebrateController = AnimationController(
          duration: const Duration(seconds: 5), vsync: this);
      celebrateWidget = LottieUtil.load(
        LottieUtil.celebrate,
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
          appBar: ItemBuilder.buildResponsiveAppBar(
            transparent: true,
            context: context,
            showBack: true,
            background: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: EasyRefresh(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ItemBuilder.buildClickable(
                    GestureDetector(
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
                ItemBuilder.buildContainerItem(
                  backgroundColor: Theme.of(context).canvasColor,
                  bottomRadius: true,
                  topRadius: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: ItemBuilder.buildHtmlWidget(
                      context,
                      S.current.eggMessage,
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  context: context,
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
      ItemBuilder.buildRadioItem(
        value: overrideCloudControl,
        context: context,
        title: S.current.overrideCloudControl,
        description: S.current.overrideCloudControlDescription,
        roundTop: true,
        roundBottom: true,
        onTap: () {
          setState(() {
            overrideCloudControl = !overrideCloudControl;
            HiveUtil.put(
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
