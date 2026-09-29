import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

abstract class BaseSettingScreen extends StatefulWidget {
  static const double sectionTopMargin = 10;
  static const EdgeInsets defaultPagePadding =
      EdgeInsets.symmetric(horizontal: 10);

  const BaseSettingScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = defaultPagePadding,
    this.searchText = "",
    this.searchConfig,
  });

  final bool showTitleBar;
  final EdgeInsets padding;
  final String searchText;
  final SearchConfig? searchConfig;

  @override
  State<StatefulWidget> createState();
}
