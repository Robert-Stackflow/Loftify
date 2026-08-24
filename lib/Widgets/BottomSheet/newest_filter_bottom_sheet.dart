import 'package:flutter/material.dart';
import 'package:loftify/Api/tag_api.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/enums.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

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
  late GetTagPostListParams params;

  @override
  void initState() {
    super.initState();
    params = widget.params;
  }

  void reset() {
    setState(() {
      params.tagRangeType = TagRangeType.noLimit;
      params.postTypes = TagPostType.noLimit;
      params.recentDayType = TagRecentDayType.noLimit;
      params.protectedFlag = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoftifyPanel(
      title: appLocalizations.filter,
      expandBody: true,
      body: SingleChildScrollView(
        primary: false,
        child: _buildButtons(),
      ),
      footer: _buildFooter(),
    );
  }

  Widget _buildButtons() {
    final design = context.design;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: design.spacing.xl,
        right: design.spacing.xl,
        top: design.spacing.sectionTop,
        bottom: design.spacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(appLocalizations.contentRange),
          LoftifyChoiceGroup<TagRangeType>(
            values: const [
              TagRangeType.noLimit,
              TagRangeType.follow,
              TagRangeType.notViewInPastSevenDays,
            ],
            selectedValue: params.tagRangeType,
            labelBuilder: EnumsLabelGetter.getTagRangeTypeLabel,
            onSelected: (value) => setState(() {
              params.tagRangeType = value;
            }),
          ),
          _buildTitle(appLocalizations.contentType, top: true),
          LoftifyChoiceGroup<TagPostType>(
            values: const [
              TagPostType.noLimit,
              TagPostType.article,
              TagPostType.image,
            ],
            selectedValue: params.postTypes,
            labelBuilder: EnumsLabelGetter.getTagPostTypeLabel,
            onSelected: (value) => setState(() {
              params.postTypes = value;
            }),
          ),
          _buildTitle(appLocalizations.releaseTime, top: true),
          LoftifyChoiceGroup<TagRecentDayType>(
            values: const [
              TagRecentDayType.noLimit,
              TagRecentDayType.oneDay,
              TagRecentDayType.oneWeek,
              TagRecentDayType.oneMonth,
            ],
            selectedValue: params.recentDayType,
            labelBuilder: EnumsLabelGetter.getTagRecentDayTypeLabel,
            onSelected: (value) => setState(() {
              params.recentDayType = value;
            }),
          ),
          _buildTitle(appLocalizations.tagProtection, top: true),
          LoftifyTag(
            label: appLocalizations.tagProtection,
            selected: params.protectedFlag,
            onPressed: () => setState(() {
              params.protectedFlag = !params.protectedFlag;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title, {bool top = false}) {
    final design = context.design;
    return Padding(
      padding: EdgeInsets.only(
        top: top ? design.spacing.xxl : 0,
        bottom: design.spacing.lg,
      ),
      child: Text(title, style: design.typography.sectionTitle),
    );
  }

  Widget _buildFooter() {
    final design = context.design;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: LoftifyButton(
            label: appLocalizations.reset,
            icon: LoftifyIcons.reset,
            variant: LoftifyButtonVariant.secondary,
            onPressed: reset,
            expand: true,
          ),
        ),
        SizedBox(width: design.spacing.lg),
        Expanded(
          flex: 2,
          child: LoftifyButton(
            label: appLocalizations.confirm,
            onPressed: () {
              widget.onConfirm?.call(params);
              Navigator.pop(context, params);
            },
            expand: true,
          ),
        ),
      ],
    );
  }
}
