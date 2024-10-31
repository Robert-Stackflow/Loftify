import 'dart:io';

import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Suit/custom_bg_avatar_list_screen.dart';

import '../../Widgets/Item/item_builder.dart';
import 'custom_dress_list_screen.dart';

class UserMarketScreen extends StatefulWidget {
  const UserMarketScreen({super.key, required this.blogId});

  static const String routeName = "/info/userMarket";

  final int blogId;

  @override
  State<UserMarketScreen> createState() => _UserMarketScreenState();
}

class _UserMarketScreenState extends State<UserMarketScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentCustomBottomBarIndex = 0;
  List<Widget> _customPageList = [];
  final PageController _customPageController = PageController();

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    initPage();
  }

  initPage() {
    _customPageList = [
      CustomBgAvatarListScreen(blogId: widget.blogId),
      CustomDressListScreen(blogId: widget.blogId, propType: 2),
      CustomDressListScreen(blogId: widget.blogId, propType: 3),
    ];
    _customPageController.addListener(() {
      if (_customPageController.page != _currentCustomBottomBarIndex) {
        setState(() {
          _currentCustomBottomBarIndex = _customPageController.page!.round();
        });
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: PageView(
        physics: const ClampingScrollPhysics(),
        controller: _customPageController,
        children: _customPageList,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildDesktopAppBar(
      context: context,
      showBack: true,
      title: "TA的商品",
      actions: [
        ItemBuilder.buildBlankIconButton(context),
        const SizedBox(width: 5),
      ],
      bottomHeight: 56,
      bottom: _buildCustomBottomBar(),
    );
  }

  _buildCustomBottomBar([double height = 56]) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MyTheme.getBackground(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: CustomSlidingSegmentedControl(
              isStretch: true,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(50),
              ),
              thumbDecoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.circular(50),
              ),
              height: height,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              children: const <int, Widget>{
                0: Text("壁纸头像"),
                1: Text("装扮"),
                2: Text("表情包"),
              },
              initialValue: _currentCustomBottomBarIndex,
              onValueChanged: (index) {
                _currentCustomBottomBarIndex = index;
                setState(() {});
                _customPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
