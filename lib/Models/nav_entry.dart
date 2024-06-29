import 'package:flutter/material.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/home_screen.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';

import '../Utils/asset_util.dart';
import '../generated/l10n.dart';

class SortableItem {
  String id;
  int index;
  bool hidden;
  bool canBeHidden;
  String lightIcon;
  String lightSelectedIcon;
  String darkIcon;
  String darkSelectedIcon;
  String? label;

  SortableItem({
    required this.id,
    required this.index,
    required this.hidden,
    required this.lightIcon,
    required this.lightSelectedIcon,
    required this.darkIcon,
    required this.darkSelectedIcon,
    this.canBeHidden = true,
  });

  @override
  String toString() {
    return 'SortableItem{id: $id, index: $index, hidden: $hidden, canBeHidden: $canBeHidden, lightIcon: $lightIcon, lightSelectedIcon: $lightSelectedIcon, darkIcon: $darkIcon, darkSelectedIcon: $darkSelectedIcon}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'hidden': hidden,
      'canBeHidden': canBeHidden,
      'lightIcon': lightIcon,
      'lightSelectedIcon': lightSelectedIcon,
      'darkIcon': darkIcon,
      'darkSelectedIcon': darkSelectedIcon,
    };
  }

  factory SortableItem.fromJson(Map<String, dynamic> json) {
    return SortableItem(
      id: json['id'],
      index: json['index'],
      hidden: json['hidden'],
      canBeHidden: json['canBeHidden'],
      lightIcon: json['lightIcon'],
      lightSelectedIcon: json['lightSelectedIcon'],
      darkIcon: json['darkIcon'],
      darkSelectedIcon: json['darkSelectedIcon'],
    );
  }
}

class SortableItemList {
  static List<SortableItem> defaultNavItems = <SortableItem>[
    SortableItem(
      id: "home",
      index: 1,
      lightIcon: AssetUtil.homeLightIcon,
      lightSelectedIcon: AssetUtil.homeLightSelectedIcon,
      darkIcon: AssetUtil.homeDarkIcon,
      darkSelectedIcon: AssetUtil.homeDarkSelectedIcon,
      hidden: false,
      canBeHidden: false,
    ),
    SortableItem(
      id: "dynamic",
      lightIcon: AssetUtil.dynamicLightIcon,
      lightSelectedIcon: AssetUtil.dynamicLightSelectedIcon,
      darkIcon: AssetUtil.dynamicDarkIcon,
      darkSelectedIcon: AssetUtil.dynamicDarkSelectedIcon,
      index: 2,
      hidden: false,
      canBeHidden: false,
    ),
    SortableItem(
      id: "mine",
      index: 4,
      lightIcon: AssetUtil.mineLightIcon,
      lightSelectedIcon: AssetUtil.mineLightSelectedIcon,
      darkIcon: AssetUtil.mineDarkIcon,
      darkSelectedIcon: AssetUtil.mineDarkSelectedIcon,
      hidden: false,
      canBeHidden: false,
    ),
  ];

  static Map<String, GlobalKey> navItemKeyMap = {
    "home": GlobalKey(),
    'dynamic': GlobalKey(),
    'mine': GlobalKey(),
  };

  static Map<String, Widget> navItemPageMap = {
    "home": HomeScreen(key: navItemKeyMap['home']),
    'mine': MineScreen(key: navItemKeyMap['mine']),
    'dynamic': DynamicScreen(key: navItemKeyMap['dynamic']),
  };

  static Widget getNavItemPage(String id) {
    return navItemPageMap[id]!;
  }

  static GlobalKey getNavItemKey(String id) {
    return navItemKeyMap[id]!;
  }

  static String getNavItemLabel(String id) {
    Map<String, String> idToLabelMap = {
      "home": S.current.home,
      'dynamic': S.current.dynamic,
      "mine": S.current.mine,
    };
    return idToLabelMap[id] ?? "";
  }

  List<SortableItem> items;
  List<SortableItem> defaultItems;

  SortableItemList({
    required this.items,
    required this.defaultItems,
  });

  static int compare(SortableItem a, SortableItem b) {
    return a.index - b.index;
  }

  List<SortableItem> getList() {
    items.sort(compare);
    return items;
  }

  List<SortableItem> mergeMeta(List<SortableItem> list) {
    for (SortableItem updateItem in defaultItems) {
      for (SortableItem item in list) {
        if (updateItem.id == item.id) {
          item.canBeHidden = updateItem.canBeHidden;
          item.lightIcon = updateItem.lightIcon;
          item.lightSelectedIcon = updateItem.lightSelectedIcon;
          item.darkIcon = updateItem.darkIcon;
          item.darkSelectedIcon = updateItem.darkSelectedIcon;
          break;
        }
      }
    }
    return list;
  }

  List<SortableItem> getHiddenItems() {
    items.sort(compare);
    List<SortableItem> hiddenItems = [];
    for (SortableItem entry in items) {
      if (entry.canBeHidden && entry.hidden) hiddenItems.add(entry);
    }
    return mergeMeta(hiddenItems);
  }

  List<SortableItem> getShownItems() {
    items.sort(compare);
    List<SortableItem> showItems = [];
    List<String> ids = List.generate(items.length, (index) => items[index].id);
    for (SortableItem entry in items) {
      if (!(entry.canBeHidden && entry.hidden)) showItems.add(entry);
    }
    for (SortableItem updateItem in defaultItems) {
      if (!ids.contains(updateItem.id)) showItems.add(updateItem);
    }
    return mergeMeta(showItems);
  }
}
