import 'package:flutter/material.dart';
import 'package:loftify/Models/nav_entry.dart';
import 'package:loftify/Providers/global_provider.dart';
import 'package:loftify/Providers/provider_manager.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:provider/provider.dart';

import '../../Widgets/Custom/no_shadow_scroll_behavior.dart';
import '../../Widgets/General/Draggable/drag_and_drop_lists.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class NavItemSettingScreen extends StatefulWidget {
  const NavItemSettingScreen({super.key});

  static const String routeName = "/setting/navItem";

  @override
  State<NavItemSettingScreen> createState() => _NavItemSettingScreenState();
}

class _NavItemSettingScreenState extends State<NavItemSettingScreen>
    with TickerProviderStateMixin {
  List<DragAndDropList> _contents = [];
  bool _allShown = false;
  bool _allHidden = false;
  final ScrollController _scrollController = ScrollController();

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initList();
      updateNavBar();
    });
  }

  @override
  void didChangeDependencies() {
    initList();
    updateNavBar();
    super.didChangeDependencies();
  }

  void initList() {
    SortableItemList navItemList = SortableItemList(
        items: ProviderManager.globalProvider.navItems,
        defaultItems: SortableItemList.defaultNavItems);
    List<SortableItem> shownNavItems = navItemList.getShownItems();
    List<SortableItem> hiddenNavItems = navItemList.getHiddenItems();
    _contents = <DragAndDropList>[
      DragAndDropList(
        canDrag: false,
        header: ItemBuilder.buildCaptionItem(
            context: context,
            title: _allHidden
                ? S.current.allNavItemsHiddenTip
                : S.current.shownNavItems),
        lastTarget: ItemBuilder.buildCaptionItem(
            context: context,
            title: S.current.dragTip,
            topRadius: false,
            bottomRadius: true),
        contentsWhenEmpty: Container(),
        children: List.generate(
          shownNavItems.length,
          (index) => DragAndDropItem(
            child: ItemBuilder.buildEntryItem(
              context: context,
              title: SortableItemList.getNavItemLabel(shownNavItems[index].id),
              showTrailing: false,
            ),
            data: shownNavItems[index],
          ),
        ),
      ),
      DragAndDropList(
        canDrag: false,
        header: ItemBuilder.buildCaptionItem(
            context: context,
            title: _allShown
                ? S.current.allNavItemsShownTip
                : S.current.hiddenNavItems),
        lastTarget: ItemBuilder.buildCaptionItem(
            context: context,
            title: S.current.dragTip,
            topRadius: false,
            bottomRadius: true),
        contentsWhenEmpty: Container(),
        children: List.generate(
          hiddenNavItems.length,
          (index) => DragAndDropItem(
            child: ItemBuilder.buildEntryItem(
              context: context,
              title: SortableItemList.getNavItemLabel(hiddenNavItems[index].id),
              showTrailing: false,
            ),
            data: hiddenNavItems[index],
          ),
        ),
      ),
    ];
  }

  void updateNavBar() {
    _allShown = _contents[1].children.isEmpty;
    _allHidden = _contents[0].children.isEmpty;
    _contents[0].header = ItemBuilder.buildCaptionItem(
        context: context,
        title: _allHidden
            ? S.current.allNavItemsHiddenTip
            : S.current.shownNavItems);
    _contents[1].header = ItemBuilder.buildCaptionItem(
        context: context,
        title: _allShown
            ? S.current.allNavItemsShownTip
            : S.current.hiddenNavItems);
  }

  void persist() {
    List<SortableItem> navs = [];
    int cur = 0;
    for (DragAndDropItem item in _contents[0].children) {
      SortableItem data = item.data;
      data.hidden = false;
      data.index = cur;
      cur += 1;
      navs.add(data);
    }
    for (DragAndDropItem item in _contents[1].children) {
      SortableItem data = item.data;
      data.hidden = true;
      data.index = cur;
      cur += 1;
      navs.add(data);
    }
    ProviderManager.globalProvider.navItems = navs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalProvider>(builder: (context, globalProvider, child) {
      return Scaffold(
        appBar: ItemBuilder.buildSimpleAppBar(
          title: S.current.navItemSetting,
          context: context,
        ),
        body: Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: ScrollConfiguration(
            behavior: NoShadowScrollBehavior(),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),
                _contents.isNotEmpty
                    ? DragAndDropLists(
                        children: _contents,
                        onItemReorder: _onItemReorder,
                        listPadding: const EdgeInsets.only(bottom: 10),
                        onListReorder: (_, __) {},
                        lastItemTargetHeight: 0,
                        lastListTargetSize: 60,
                        sliverList: true,
                        scrollController: _scrollController,
                        itemDragOnLongPress: false,
                        itemGhostOpacity: 0.3,
                        itemOpacityWhileDragging: 0.7,
                        itemDragHandle: DragHandle(
                            child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ItemBuilder.buildIconButton(
                              context: context,
                              icon: Icon(
                                Icons.dehaze_rounded,
                                size: 20,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.color,
                              ),
                              onTap: () {}),
                        )),
                      )
                    : SliverToBoxAdapter(child: Container()),
              ],
            ),
          ),
        ),
      );
    });
  }

  _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      SortableItem data = _contents[oldListIndex].children[oldItemIndex].data;
      if (!data.canBeHidden && newListIndex == 1) {
        IToast.show(context, text: "不可隐藏");
      } else {
        var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
        _contents[newListIndex].children.insert(newItemIndex, movedItem);
      }
    });
    persist();
    updateNavBar();
  }
}
