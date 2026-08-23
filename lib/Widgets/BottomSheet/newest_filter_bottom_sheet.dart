import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Utils/enums.dart';
import '../../l10n/l10n.dart';

class NewestFilterBottomSheet extends StatefulWidget {
  const NewestFilterBottomSheet({
    super.key,
    required this.params,
    this.onConfirm,
  });

  final Function(GetTagPostListParams params)? onConfirm;
  final GetTagPostListParams params;

  @override
  NewestFilterBottomSheetState createState() => NewestFilterBottomSheetState();
}

class NewestFilterBottomSheetState extends State<NewestFilterBottomSheet> {
  final GroupButtonController _rangeController = GroupButtonController();
  final GroupButtonController _postTypeController = GroupButtonController();
  final GroupButtonController _recentDayController = GroupButtonController();
  final GroupButtonController _tagProtectedController = GroupButtonController();
  late GetTagPostListParams params;

  @override
  void initState() {
    super.initState();
    params = widget.params;
    init();
  }

  init() {
    _rangeController.selectIndex(params.tagRangeType.index);
    _postTypeController.selectIndex(params.postTypes.index);
    _recentDayController.selectIndex(params.recentDayType.index);
    _tagProtectedController.selectIndex(params.protectedFlag ? 0 : -1);
  }

  reset() {
    params.tagRangeType = TagRangeType.noLimit;
    params.postTypes = TagPostType.noLimit;
    params.recentDayType = TagRecentDayType.noLimit;
    params.protectedFlag = false;
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: Theme.of(context).canvasColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          MyDivider(horizontal: 0, vertical: 0),
          _buildButtons(),
          MyDivider(horizontal: 0, vertical: 0),
          _buildFooter(),
        ],
      ),
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        appLocalizations.filter,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _buildButtons() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemBuilder.buildTitle(
            context,
            title: appLocalizations.contentRange,
            left: 0,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ChewieItemBuilder.buildGroupButtons(
            buttons: [
              appLocalizations.noLimit,
              appLocalizations.followingUser,
              appLocalizations.haveNotVisitRecentSevenDays
            ],
            controller: _rangeController,
            constraintWidth: false,
            onSelected: (value, index, selected) {
              params.tagRangeType = TagRangeType.values[index];
            },
          ),
          ItemBuilder.buildTitle(
            context,
            title: appLocalizations.contentType,
            left: 0,
            topMargin: 20,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ChewieItemBuilder.buildGroupButtons(
            buttons: [
              appLocalizations.noLimit,
              appLocalizations.words,
              appLocalizations.images
            ],
            controller: _postTypeController,
            constraintWidth: false,
            onSelected: (value, index, selected) {
              params.postTypes = TagPostType.values[index];
            },
          ),
          ItemBuilder.buildTitle(
            context,
            title: appLocalizations.releaseTime,
            left: 0,
            topMargin: 20,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ChewieItemBuilder.buildGroupButtons(
            buttons: [
              appLocalizations.noLimit,
              appLocalizations.inOneDay,
              appLocalizations.inOneWeek,
              appLocalizations.inOneMonth
            ],
            controller: _recentDayController,
            constraintWidth: false,
            onSelected: (value, index, selected) {
              params.recentDayType = TagRecentDayType.values[index];
            },
          ),
          ItemBuilder.buildTitle(
            context,
            title: appLocalizations.tagProtection,
            left: 0,
            topMargin: 20,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ChewieItemBuilder.buildGroupButtons(
            buttons: [appLocalizations.tagProtection],
            controller: _tagProtectedController,
            constraintWidth: false,
            enableDeselect: true,
            onSelected: (value, index, selected) {
              params.protectedFlag = selected;
            },
          ),
        ],
      ),
    );
  }

  _buildFooter() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ItemBuilder.buildIconTextButton(
              context,
              icon: const Icon(Icons.refresh_rounded, size: 24),
              direction: Axis.vertical,
              text: appLocalizations.reset,
              fontSizeDelta: -2,
              onTap: reset,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: RoundIconTextButton(
              text: appLocalizations.confirm,
              background: Theme.of(context).primaryColor,
              color: Colors.white,
              onPressed: () {
                widget.onConfirm?.call(params);
                Navigator.pop(context, params);
              },
            ),
          ),
        ],
      ),
    );
  }
}
