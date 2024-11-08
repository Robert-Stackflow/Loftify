import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Utils/enums.dart';
import '../../generated/l10n.dart';

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
          ItemBuilder.buildDivider(context, horizontal: 0, vertical: 0),
          _buildButtons(),
          ItemBuilder.buildDivider(context, horizontal: 0, vertical: 0),
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
        S.current.filter,
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
            title: S.current.contentRange,
            left: 0,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ItemBuilder.buildGroupButtons(
            buttons: [
              S.current.noLimit,
              S.current.followingUser,
              S.current.haveNotVisitRecentSevenDays
            ],
            controller: _rangeController,
            onSelected: (value, index, selected) {
              params.tagRangeType = TagRangeType.values[index];
            },
          ),
          ItemBuilder.buildTitle(
            context,
            title: S.current.contentType,
            left: 0,
            topMargin: 20,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ItemBuilder.buildGroupButtons(
            buttons: [S.current.noLimit, S.current.words, S.current.images],
            controller: _postTypeController,
            onSelected: (value, index, selected) {
              params.postTypes = TagPostType.values[index];
            },
          ),
          ItemBuilder.buildTitle(
            context,
            title: S.current.releaseTime,
            left: 0,
            topMargin: 20,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ItemBuilder.buildGroupButtons(
            buttons: [
              S.current.noLimit,
              S.current.inOneDay,
              S.current.inOneWeek,
              S.current.inOneMonth
            ],
            controller: _recentDayController,
            onSelected: (value, index, selected) {
              params.recentDayType = TagRecentDayType.values[index];
            },
          ),
          ItemBuilder.buildTitle(
            context,
            title: S.current.tagProtection,
            left: 0,
            topMargin: 20,
            bottomMargin: 12,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontSizeDelta: -2),
          ),
          ItemBuilder.buildGroupButtons(
            buttons: [S.current.tagProtection],
            controller: _tagProtectedController,
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
              text: S.current.reset,
              fontSizeDelta: -2,
              onTap: reset,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: S.current.confirm,
              background: Theme.of(context).primaryColor,
              color: Colors.white,
              onTap: () {
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
