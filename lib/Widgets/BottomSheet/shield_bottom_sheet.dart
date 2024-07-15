import 'package:flutter/material.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Models/enums.dart';
import '../../Resources/theme.dart';

class ShieldBottomSheet extends StatefulWidget {
  const ShieldBottomSheet({
    super.key,
    required this.tags,
    this.onShieldTag,
    this.onShieldContent,
    this.onShieldUser,
  });

  final Function(String tag)? onShieldTag;
  final Function()? onShieldContent;
  final Function()? onShieldUser;
  final List<String> tags;

  @override
  ShieldBottomSheetState createState() => ShieldBottomSheetState();
}

class ShieldBottomSheetState extends State<ShieldBottomSheet> {
  late List<String> tags;

  @override
  void initState() {
    super.initState();
    tags = widget.tags;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 50),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.getBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              _buildButtons(),
              ItemBuilder.buildDivider(context, horizontal: 12, vertical: 0),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        "减少标签下内容推荐",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _buildButtons() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: tags.map((tag) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ItemBuilder.buildTagItem(
                  context,
                  tag,
                  TagType.normal,
                  fontWeightDelta: 2,
                  fontSizeDelta: 1,
                  jumpToTag: false,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  onTap: () {
                    widget.onShieldTag?.call(tag);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 45,
            child: ItemBuilder.buildRoundButton(
              context,
              text: "🙈 内容不感兴趣",
              onTap: widget.onShieldContent,
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 45,
            child: ItemBuilder.buildRoundButton(
              context,
              text: "💔 作者不感兴趣",
              onTap: widget.onShieldUser,
              fontSizeDelta: 2,
            ),
          ),
        ],
      ),
    );
  }
}
