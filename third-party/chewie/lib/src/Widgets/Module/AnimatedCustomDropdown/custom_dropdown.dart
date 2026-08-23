library animated_custom_dropdown;

import 'dart:async';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

export 'custom_dropdown.dart';

part 'models/controllers.dart';
// models
part 'models/custom_dropdown_decoration.dart';
part 'models/custom_dropdown_list_filter.dart';
part 'models/disabled_decoration.dart';
part 'models/list_item_decoration.dart';
part 'models/search_field_decoration.dart';
part 'models/selection_item_model.dart';
part 'models/dropdown_mixin.dart';
// utils
part 'utils/signatures.dart';
// widgets
part 'widgets/animated_section.dart';
part 'widgets/dropdown_field.dart';
part 'widgets/dropdown_overlay/dropdown_overlay.dart';
part 'widgets/dropdown_overlay/widgets/items_list.dart';
part 'widgets/dropdown_overlay/widgets/search_field.dart';
part 'widgets/overlay_builder.dart';

enum _DropdownType { singleSelect, multipleSelect }

enum _SearchType { onListData, onRequestData }

const _defaultErrorColor = Colors.red;

const _defaultMaxLines = 3;

const _defaultBorderRadius = BorderRadius.all(
  Radius.circular(12),
);

final Border _defaultErrorBorder = Border.all(
  color: _defaultErrorColor,
  width: 1.5,
);

class CustomDropdown<T extends DropdownMixin> extends StatefulWidget {
  /// The list of items user can select.
  final List<T>? items;

  /// Initial selected item from the list of [items].
  final T? initialItem;

  /// Initial selected items from the list of [items].
  final List<T>? initialItems;

  /// Scroll controller to access items list scroll behavior.
  final ScrollController? itemsScrollController;

  /// Text that suggests what sort of data the dropdown represents.
  ///
  /// Default to "Select value".
  final String? hintText;

  /// Text that suggests what to search in the search field.
  ///
  /// Default to "Search".
  final String? searchHintText;

  /// A method that validates the selected item.
  /// Returns an error string to display as per the validation, or null otherwise.
  final String? Function(T?)? validator;

  /// A method that validates the selected items.
  /// Returns an error string to display as per the validation, or null otherwise.
  final String? Function(List<T>)? listValidator;

  /// Enable the validation listener on item change.
  /// This implies to [validator] everytime when the item change.
  final bool validateOnChange;

  /// Called when the item of the [CustomDropdown] should change.
  final Function(T?)? onChanged;

  /// Called when the list of items of the [CustomDropdown] should change.
  final Function(List<T>)? onListChanged;

  /// Hide the selected item from the [items] list.
  final bool excludeSelected;

  /// Can close [CustomDropdown] overlay by tapping outside.
  /// Here "outside" covers the entire screen.
  final bool canCloseOutsideBounds;

  /// Hide the header field when [CustomDropdown] overlay opened/expanded.
  final bool hideSelectedFieldWhenExpanded;

  /// The asynchronous computation from which the items list returns.
  final Future<List<T>> Function(String)? futureRequest;

  /// Text that notify there's no search results match.
  ///
  /// Default to "No result found.".
  final String? noResultFoundText;

  final String? noItemText;

  /// Duration after which the [futureRequest] is to be executed.
  final Duration? futureRequestDelay;

  /// Text maxlines for header and list item text.
  final int maxlines;

  final int listMaxlines;

  /// Padding for [CustomDropdown] header (closed state).
  final EdgeInsets? closedHeaderPadding;

  /// Padding for [CustomDropdown] header (opened/expanded state).
  final EdgeInsets? expandedHeaderPadding;

  /// Padding for [CustomDropdown] items list.
  final EdgeInsets? itemsListPadding;

  /// Padding for [CustomDropdown] each list item.
  final EdgeInsets? listItemPadding;

  /// Widget to display while search request loading.
  final Widget? searchRequestLoadingIndicator;

  /// [CustomDropdown] opened/expanded area height.
  /// Only applicable if items are greater than 4 otherwise adjust automatically.
  final double? overlayHeight;

  /// The [listItemBuilder] that will be used to build item on demand.
  final _ListItemBuilder<T>? listItemBuilder;

  /// The [headerBuilder] that will be used to build [CustomDropdown] header field.
  final _HeaderBuilder<T>? headerBuilder;

  /// The [selectedBuilder] that will be used to build [CustomDropdown] selected field.
  final _SelectedBuilder<T>? selectedBuilder;

  /// The [selectedListBuilder] that will be used to build [CustomDropdown] header field.
  final _SelectedListBuilder<T>? selectedListBuilder;

  /// The [hintBuilder] that will be used to build [CustomDropdown] hint of header field.
  final _HintBuilder? hintBuilder;

  /// The [noResultFoundBuilder] that will be used to build area when there's no search results match.
  final _NoResultFoundBuilder? noResultFoundBuilder;

  final _NoResultFoundBuilder? noItemBuilder;

  /// [CustomDropdown] decoration.
  /// Contain sub-decorations [SearchFieldDecoration], [ListItemDecoration] and [ScrollbarThemeData].
  final CustomDropdownDecoration? decoration;

  /// [CustomDropdown] enabled/disabled state.
  /// If disabled, you can not open the dropdown.
  final bool enabled;

  /// [CustomDropdown] disabled decoration.
  ///
  /// Note: Only applicable if dropdown is disabled.
  final CustomDropdownDisabledDecoration? disabledDecoration;

  /// [CustomDropdown] will close on tap Clear filter for all search
  /// and searchRequest constructors
  final bool closeDropDownOnClearFilterSearch;

  /// The [overlayController] allows you to explicitly handle the [CustomDropdown] overlay states (show/hide).
  final OverlayPortalController? overlayController;

  /// The [controller] that can be used to control [CustomDropdown] selected item.
  final SingleSelectController<T?>? controller;

  /// The [multiSelectController] that can be used to control [CustomDropdown.multiSelect] selected items.
  final MultiSelectController<T>? multiSelectController;

  /// Callback for dropdown [visibility].
  ///
  /// If both [visibility] and [overlayController] are provided, this callback never listens the changes of [overlayController].
  /// You have to explicitly check for [overlayController] visibility states using [overlayController.isShowing] property.
  final Function(bool)? visibility;

  final _SearchType? _searchType;

  final _DropdownType _dropdownType;

  CustomDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.controller,
    this.itemsScrollController,
    this.initialItem,
    this.hintText,
    this.decoration,
    this.validator,
    this.validateOnChange = true,
    this.visibility,
    this.overlayController,
    this.listItemBuilder,
    this.headerBuilder,
    this.selectedBuilder,
    this.hintBuilder,
    this.maxlines = _defaultMaxLines,
    this.listMaxlines = _defaultMaxLines,
    this.overlayHeight,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.itemsListPadding,
    this.listItemPadding,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.excludeSelected = false,
    this.enabled = true,
    this.disabledDecoration,
    this.noItemBuilder,
    this.noItemText,
  })  : assert(
          initialItem == null || controller == null,
          'Only one of initialItem or controller can be specified at a time',
        ),
        assert(
          initialItem == null || items!.contains(initialItem),
          'Initial item must match with one of the item in items list.',
        ),
        assert(
          controller == null ||
              controller.value == null ||
              items!.contains(controller.value),
          'Controller value must match with one of the item in items list.',
        ),
        _searchType = null,
        _dropdownType = _DropdownType.singleSelect,
        futureRequest = null,
        futureRequestDelay = null,
        noResultFoundBuilder = null,
        noResultFoundText = null,
        searchHintText = null,
        initialItems = null,
        onListChanged = null,
        listValidator = null,
        selectedListBuilder = null,
        searchRequestLoadingIndicator = null,
        closeDropDownOnClearFilterSearch = false,
        multiSelectController = null;

  CustomDropdown.search({
    super.key,
    required this.items,
    required this.onChanged,
    this.controller,
    this.itemsScrollController,
    this.initialItem,
    this.hintText,
    this.decoration,
    this.visibility,
    this.overlayController,
    this.searchHintText,
    this.noResultFoundText,
    this.listItemBuilder,
    this.headerBuilder,
    this.selectedBuilder,
    this.hintBuilder,
    this.noResultFoundBuilder,
    this.noItemBuilder,
    this.noItemText,
    this.validator,
    this.validateOnChange = true,
    this.maxlines = _defaultMaxLines,
    this.listMaxlines = _defaultMaxLines,
    this.overlayHeight,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.itemsListPadding,
    this.listItemPadding,
    this.excludeSelected = false,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.enabled = true,
    this.disabledDecoration,
    this.closeDropDownOnClearFilterSearch = false,
  })  : assert(
          initialItem == null || controller == null,
          'Only one of initialItem or controller can be specified at a time',
        ),
        assert(
          initialItem == null || items!.contains(initialItem),
          'Initial item must match with one of the item in items list.',
        ),
        assert(
          controller == null ||
              controller.value == null ||
              items!.contains(controller.value),
          'Controller value must match with one of the item in items list.',
        ),
        _searchType = _SearchType.onListData,
        _dropdownType = _DropdownType.singleSelect,
        futureRequest = null,
        futureRequestDelay = null,
        initialItems = null,
        onListChanged = null,
        listValidator = null,
        selectedListBuilder = null,
        searchRequestLoadingIndicator = null,
        multiSelectController = null;

  const CustomDropdown.searchRequest({
    super.key,
    required this.futureRequest,
    required this.onChanged,
    this.futureRequestDelay,
    this.initialItem,
    this.items,
    this.controller,
    this.itemsScrollController,
    this.hintText,
    this.decoration,
    this.visibility,
    this.overlayController,
    this.searchHintText,
    this.noResultFoundText,
    this.listItemBuilder,
    this.selectedBuilder,
    this.headerBuilder,
    this.hintBuilder,
    this.listMaxlines = _defaultMaxLines,
    this.noResultFoundBuilder,
    this.validator,
    this.validateOnChange = true,
    this.maxlines = _defaultMaxLines,
    this.overlayHeight,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.itemsListPadding,
    this.listItemPadding,
    this.searchRequestLoadingIndicator,
    this.excludeSelected = false,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.enabled = true,
    this.disabledDecoration,
    this.closeDropDownOnClearFilterSearch = false,
    this.noItemBuilder,
    this.noItemText,
  })  : assert(
          initialItem == null || controller == null,
          'Only one of initialItem or controller can be specified at a time',
        ),
        _searchType = _SearchType.onRequestData,
        _dropdownType = _DropdownType.singleSelect,
        initialItems = null,
        onListChanged = null,
        listValidator = null,
        selectedListBuilder = null,
        multiSelectController = null;

  CustomDropdown.multiSelect({
    super.key,
    required this.items,
    required this.onListChanged,
    this.multiSelectController,
    this.controller,
    this.initialItems,
    this.overlayController,
    this.itemsScrollController,
    this.listValidator,
    this.visibility,
    this.selectedListBuilder,
    this.hintText,
    this.decoration,
    this.listMaxlines = _defaultMaxLines,
    this.validateOnChange = true,
    this.listItemBuilder,
    this.selectedBuilder,
    this.hintBuilder,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.maxlines = _defaultMaxLines,
    this.overlayHeight,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.itemsListPadding,
    this.listItemPadding,
    this.enabled = true,
    this.disabledDecoration,
  })  : assert(
          initialItems == null || multiSelectController == null,
          'Only one of initialItems or controller can be specified at a time',
        ),
        assert(
          initialItems == null ||
              initialItems.isEmpty ||
              initialItems.every((e) => items!.contains(e)),
          'Initial items must match with the items in the items list.',
        ),
        assert(
          multiSelectController == null ||
              multiSelectController.value.isEmpty ||
              multiSelectController.value.every((e) => items!.contains(e)),
          'Controller value must match with one of the item in items list.',
        ),
        _searchType = null,
        _dropdownType = _DropdownType.multipleSelect,
        initialItem = null,
        noResultFoundText = null,
        noItemBuilder = null,
        noItemText = null,
        validator = null,
        headerBuilder = null,
        onChanged = null,
        excludeSelected = false,
        futureRequest = null,
        futureRequestDelay = null,
        noResultFoundBuilder = null,
        searchHintText = null,
        searchRequestLoadingIndicator = null,
        closeDropDownOnClearFilterSearch = false;

  CustomDropdown.multiSelectSearch({
    super.key,
    required this.items,
    required this.onListChanged,
    this.multiSelectController,
    this.initialItems,
    this.controller,
    this.visibility,
    this.itemsScrollController,
    this.overlayController,
    this.listValidator,
    this.listItemBuilder,
    this.selectedBuilder,
    this.hintBuilder,
    this.decoration,
    this.selectedListBuilder,
    this.noResultFoundText,
    this.noResultFoundBuilder,
    this.hintText,
    this.listMaxlines = _defaultMaxLines,
    this.searchHintText,
    this.validateOnChange = true,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.maxlines = _defaultMaxLines,
    this.overlayHeight,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.itemsListPadding,
    this.listItemPadding,
    this.enabled = true,
    this.disabledDecoration,
    this.closeDropDownOnClearFilterSearch = false,
    this.noItemBuilder,
    this.noItemText,
  })  : assert(
          initialItems == null || multiSelectController == null,
          'Only one of initialItems or controller can be specified at a time',
        ),
        assert(
          initialItems == null ||
              initialItems.isEmpty ||
              initialItems.every((e) => items!.contains(e)),
          'Initial items must match with the items in the items list.',
        ),
        assert(
          multiSelectController == null ||
              multiSelectController.value.isEmpty ||
              multiSelectController.value.every((e) => items!.contains(e)),
          'Controller value must match with one of the item in items list.',
        ),
        _searchType = _SearchType.onListData,
        _dropdownType = _DropdownType.multipleSelect,
        initialItem = null,
        onChanged = null,
        validator = null,
        excludeSelected = false,
        headerBuilder = null,
        futureRequest = null,
        futureRequestDelay = null,
        searchRequestLoadingIndicator = null;

  const CustomDropdown.multiSelectSearchRequest({
    super.key,
    required this.futureRequest,
    required this.onListChanged,
    this.multiSelectController,
    this.futureRequestDelay,
    this.initialItems,
    this.items,
    this.controller,
    this.itemsScrollController,
    this.overlayController,
    this.visibility,
    this.hintText,
    this.listMaxlines = _defaultMaxLines,
    this.decoration,
    this.searchHintText,
    this.noResultFoundText,
    this.selectedListBuilder,
    this.selectedBuilder,
    this.listItemBuilder,
    this.hintBuilder,
    this.noResultFoundBuilder,
    this.listValidator,
    this.validateOnChange = true,
    this.maxlines = _defaultMaxLines,
    this.overlayHeight,
    this.searchRequestLoadingIndicator,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.itemsListPadding,
    this.listItemPadding,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.enabled = true,
    this.disabledDecoration,
    this.closeDropDownOnClearFilterSearch = false,
    this.noItemBuilder,
    this.noItemText,
  })  : assert(
          initialItems == null || multiSelectController == null,
          'Only one of initialItems or controller can be specified at a time',
        ),
        _searchType = _SearchType.onRequestData,
        _dropdownType = _DropdownType.multipleSelect,
        initialItem = null,
        onChanged = null,
        headerBuilder = null,
        excludeSelected = false,
        validator = null;

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T extends DropdownMixin>
    extends State<CustomDropdown<T>> {
  final layerLink = LayerLink();
  late SingleSelectController<T?> selectedItemNotifier;
  late MultiSelectController<T> selectedItemsNotifier;
  FormFieldState<(T?, List<T>)>? _formFieldState;
  bool _refreshingEquivalentCandidate = false;

  T? _canonicalItem(T? candidate) {
    if (candidate == null || widget.items == null) return candidate;
    for (final item in widget.items!) {
      if (item == candidate) return item;
    }
    return candidate;
  }

  List<T> _canonicalItems(List<T> candidates) {
    return candidates.map((candidate) => _canonicalItem(candidate)!).toList();
  }

  bool _sameValues(List<T>? first, List<T>? second) {
    if (identical(first, second)) return true;
    if (first == null || second == null || first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  bool _sameInstances(List<T> first, List<T> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (!identical(first[index], second[index])) return false;
    }
    return true;
  }

  void _handleSelectedItemChanged() {
    if (!_refreshingEquivalentCandidate) {
      widget.onChanged?.call(selectedItemNotifier.value);
    }
    _formFieldState?.didChange((selectedItemNotifier.value, []));
    if (widget.validateOnChange) {
      _formFieldState?.validate();
    }
  }

  void _handleSelectedItemsChanged() {
    if (!_refreshingEquivalentCandidate) {
      widget.onListChanged?.call(selectedItemsNotifier.value);
    }
    _formFieldState?.didChange((null, selectedItemsNotifier.value));
    if (widget.validateOnChange) {
      _formFieldState?.validate();
    }
  }

  void _refreshSelectedItem(T? nextItem) {
    _refreshingEquivalentCandidate = true;
    try {
      selectedItemNotifier.replaceEquivalent(nextItem);
    } finally {
      _refreshingEquivalentCandidate = false;
    }
  }

  void _refreshSelectedItems(List<T> nextItems) {
    _refreshingEquivalentCandidate = true;
    try {
      selectedItemsNotifier.value = nextItems;
    } finally {
      _refreshingEquivalentCandidate = false;
    }
  }

  @override
  void initState() {
    super.initState();

    selectedItemNotifier = widget.controller ??
        SingleSelectController(_canonicalItem(widget.initialItem));

    selectedItemsNotifier = widget.multiSelectController ??
        MultiSelectController(_canonicalItems(widget.initialItems ?? []));

    selectedItemNotifier.addListener(_handleSelectedItemChanged);
    selectedItemsNotifier.addListener(_handleSelectedItemsChanged);
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final singleControllerChanged = widget.controller != oldWidget.controller;
    if (singleControllerChanged) {
      selectedItemNotifier.removeListener(_handleSelectedItemChanged);
      if (oldWidget.controller == null) selectedItemNotifier.dispose();
      selectedItemNotifier = widget.controller ??
          SingleSelectController(_canonicalItem(widget.initialItem));
      selectedItemNotifier.addListener(_handleSelectedItemChanged);
    }

    final multiControllerChanged =
        widget.multiSelectController != oldWidget.multiSelectController;
    if (multiControllerChanged) {
      selectedItemsNotifier.removeListener(_handleSelectedItemsChanged);
      if (oldWidget.multiSelectController == null) {
        selectedItemsNotifier.dispose();
      }
      selectedItemsNotifier = widget.multiSelectController ??
          MultiSelectController(_canonicalItems(widget.initialItems ?? []));
      selectedItemsNotifier.addListener(_handleSelectedItemsChanged);
    }

    final nextInitialItem = _canonicalItem(widget.initialItem);
    final initialValueChanged = widget.initialItem != oldWidget.initialItem;
    final equivalentCandidateChanged = widget.initialItem != null &&
        selectedItemNotifier.value == nextInitialItem &&
        !identical(selectedItemNotifier.value, nextInitialItem) &&
        !identical(widget.initialItem, oldWidget.initialItem);
    if (!singleControllerChanged &&
        widget.controller == null &&
        (initialValueChanged || equivalentCandidateChanged)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.controller != null) return;
        final currentInitialItem = _canonicalItem(widget.initialItem);
        if (!identical(selectedItemNotifier.value, currentInitialItem)) {
          if (selectedItemNotifier.value == currentInitialItem) {
            _refreshSelectedItem(currentInitialItem);
          } else {
            selectedItemNotifier.value = currentInitialItem;
          }
        }
      });
    }

    final nextInitialItems = _canonicalItems(widget.initialItems ?? []);
    final initialValuesChanged =
        !_sameValues(widget.initialItems, oldWidget.initialItems);
    final equivalentCandidatesChanged = widget.initialItems != null &&
        _sameValues(selectedItemsNotifier.value, nextInitialItems) &&
        !_sameInstances(selectedItemsNotifier.value, nextInitialItems) &&
        !identical(widget.initialItems, oldWidget.initialItems);
    if (!multiControllerChanged &&
        widget.multiSelectController == null &&
        (initialValuesChanged || equivalentCandidatesChanged)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.multiSelectController != null) return;
        final currentInitialItems = _canonicalItems(widget.initialItems ?? []);
        if (!_sameInstances(selectedItemsNotifier.value, currentInitialItems)) {
          if (_sameValues(selectedItemsNotifier.value, currentInitialItems)) {
            _refreshSelectedItems(currentInitialItems);
          } else {
            selectedItemsNotifier.value = currentInitialItems;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    selectedItemNotifier.removeListener(_handleSelectedItemChanged);
    selectedItemsNotifier.removeListener(_handleSelectedItemsChanged);
    if (widget.controller == null) {
      selectedItemNotifier.dispose();
    }

    if (widget.multiSelectController == null) {
      selectedItemsNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final decoration = widget.decoration;
    final disabledDecoration = widget.disabledDecoration;
    final safeHintText = widget.hintText ?? 'Select value';

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: FormField<(T?, List<T>)>(
          initialValue: (
            selectedItemNotifier.value,
            selectedItemsNotifier.value
          ),
          validator: (val) {
            if (widget._dropdownType == _DropdownType.singleSelect &&
                widget.validator != null) {
              return widget.validator!(val?.$1);
            }
            if (widget._dropdownType == _DropdownType.multipleSelect &&
                widget.listValidator != null) {
              return widget.listValidator!(val?.$2 ?? []);
            }
            return null;
          },
          builder: (formFieldState) {
            _formFieldState = formFieldState;
            return Container(
              decoration: const BoxDecoration(
                // errorText: formFieldState.errorText,
                border: null,
                // contentPadding: EdgeInsets.zero,
              ),
              child: _OverlayBuilder(
                overlayPortalController: widget.overlayController,
                visibility: widget.visibility,
                overlay: (size, hideCallback) {
                  return _DropdownOverlay<T>(
                    onItemSelect: (T value) {
                      switch (widget._dropdownType) {
                        case _DropdownType.singleSelect:
                          selectedItemNotifier.value = value;
                        case _DropdownType.multipleSelect:
                          final currentVal =
                              selectedItemsNotifier.value.toList();
                          if (currentVal.contains(value)) {
                            currentVal.remove(value);
                          } else {
                            currentVal.add(value);
                          }
                          selectedItemsNotifier.value = currentVal;
                      }
                    },
                    noResultFoundText:
                        widget.noResultFoundText ?? 'No result found.',
                    noResultFoundBuilder: widget.noResultFoundBuilder,
                    noItemText: widget.noItemText ?? 'Empty.',
                    noItemBuilder: widget.noItemBuilder,
                    items: widget.items ?? [],
                    itemsScrollCtrl: widget.itemsScrollController,
                    selectedItemNotifier: selectedItemNotifier,
                    selectedItemsNotifier: selectedItemsNotifier,
                    size: size,
                    listItemBuilder: widget.listItemBuilder,
                    layerLink: layerLink,
                    hideOverlay: hideCallback,
                    hintStyle: decoration?.hintStyle,
                    noResultFoundStyle: decoration?.noResultFoundStyle,
                    noItemStyle: decoration?.noItemStyle,
                    listItemStyle: decoration?.listItemStyle,
                    headerBuilder: widget.headerBuilder,
                    multiSelectHeaderBuilder: widget.selectedListBuilder,
                    hintText: safeHintText,
                    searchHintText: widget.searchHintText ?? 'Search',
                    hintBuilder: widget.hintBuilder,
                    decoration: decoration,
                    overlayHeight: widget.overlayHeight,
                    excludeSelected: widget.excludeSelected,
                    canCloseOutsideBounds: widget.canCloseOutsideBounds,
                    searchType: widget._searchType,
                    futureRequest: widget.futureRequest,
                    futureRequestDelay: widget.futureRequestDelay,
                    hideSelectedFieldWhenOpen:
                        widget.hideSelectedFieldWhenExpanded,
                    maxLines: widget.listMaxlines,
                    headerPadding: widget.expandedHeaderPadding,
                    itemsListPadding: widget.itemsListPadding,
                    listItemPadding: widget.listItemPadding,
                    searchRequestLoadingIndicator:
                        widget.searchRequestLoadingIndicator,
                    dropdownType: widget._dropdownType,
                  );
                },
                child: (showCallback) {
                  return CompositedTransformTarget(
                    link: layerLink,
                    child: _DropDownField<T>(
                      onTap: showCallback,
                      selectedItemNotifier: selectedItemNotifier,
                      border: formFieldState.hasError
                          ? (decoration?.closedErrorBorder ??
                              _defaultErrorBorder)
                          : enabled
                              ? decoration?.closedBorder
                              : disabledDecoration?.border ??
                                  decoration?.closedBorder,
                      borderRadius: formFieldState.hasError
                          ? decoration?.closedErrorBorderRadius
                          : enabled
                              ? decoration?.closedBorderRadius
                              : disabledDecoration?.borderRadius ??
                                  decoration?.closedBorderRadius,
                      shadow: enabled
                          ? decoration?.closedShadow
                          : disabledDecoration?.shadow ??
                              decoration?.closedShadow,
                      hintStyle: enabled
                          ? decoration?.hintStyle
                          : disabledDecoration?.hintStyle ??
                              decoration?.hintStyle,
                      showSelectedStyle: enabled
                          ? decoration?.showSelectStyle
                          : disabledDecoration?.showSelectStyle ??
                              decoration?.showSelectStyle,
                      hintText: safeHintText,
                      hintBuilder: widget.hintBuilder,
                      showSelectedBuilder: widget.selectedBuilder,
                      headerBuilder: widget.headerBuilder,
                      multiSelectShowSelectedBuilder:
                          widget.selectedListBuilder,
                      prefixIcon: enabled
                          ? decoration?.prefixIcon
                          : disabledDecoration?.prefixIcon ??
                              decoration?.prefixIcon,
                      suffixIcon: enabled
                          ? decoration?.closedSuffixIcon
                          : disabledDecoration?.suffixIcon,
                      fillColor: enabled
                          ? decoration?.closedFillColor
                          : disabledDecoration?.fillColor ??
                              decoration?.closedFillColor,
                      maxLines: widget.maxlines,
                      headerPadding: widget.closedHeaderPadding,
                      dropdownType: widget._dropdownType,
                      selectedItemsNotifier: selectedItemsNotifier,
                      enabled: widget.enabled,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
