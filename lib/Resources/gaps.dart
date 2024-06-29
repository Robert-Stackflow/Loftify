import 'package:flutter/material.dart';

import 'dimens.dart';

class MyGaps {
  /// 水平间隔
  static const Widget hGap4 = SizedBox(width: MyDimens.gap_dp4);
  static const Widget hGap5 = SizedBox(width: MyDimens.gap_dp5);
  static const Widget hGap8 = SizedBox(width: MyDimens.gap_dp8);
  static const Widget hGap10 = SizedBox(width: MyDimens.gap_dp10);
  static const Widget hGap12 = SizedBox(width: MyDimens.gap_dp12);
  static const Widget hGap15 = SizedBox(width: MyDimens.gap_dp15);
  static const Widget hGap16 = SizedBox(width: MyDimens.gap_dp16);
  static const Widget hGap32 = SizedBox(width: MyDimens.gap_dp32);

  /// 垂直间隔
  static const Widget vGap4 = SizedBox(height: MyDimens.gap_dp4);
  static const Widget vGap5 = SizedBox(height: MyDimens.gap_dp5);
  static const Widget vGap8 = SizedBox(height: MyDimens.gap_dp8);
  static const Widget vGap10 = SizedBox(height: MyDimens.gap_dp10);
  static const Widget vGap12 = SizedBox(height: MyDimens.gap_dp12);
  static const Widget vGap15 = SizedBox(height: MyDimens.gap_dp15);
  static const Widget vGap16 = SizedBox(height: MyDimens.gap_dp16);
  static const Widget vGap24 = SizedBox(height: MyDimens.gap_dp24);
  static const Widget vGap32 = SizedBox(height: MyDimens.gap_dp32);
  static const Widget vGap50 = SizedBox(height: MyDimens.gap_dp50);

  static const Widget line = Divider();

  static const Widget vLine = SizedBox(
    width: 0.6,
    height: 24.0,
    child: VerticalDivider(),
  );

  static Widget verticleDivider(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
            style: BorderStyle.solid,
          ),
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  static const Widget empty = SizedBox.shrink();
}
