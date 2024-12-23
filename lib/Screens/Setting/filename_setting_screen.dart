import 'package:flutter/material.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/Custom/no_shadow_scroll_behavior.dart';

import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class FilenameSettingScreen extends StatefulWidget {
  const FilenameSettingScreen({super.key, this.onSaved});

  final Function(String)? onSaved;

  static const String routeName = "/setting/filename";

  @override
  State<FilenameSettingScreen> createState() => _FilenameSettingScreenState();
}

class _FilenameSettingScreenState extends State<FilenameSettingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String filenameFormat = HiveUtil.getString(HiveUtil.filenameFormatKey,
          defaultValue: defaultFilenameFormat) ??
      defaultFilenameFormat;

  @override
  void initState() {
    super.initState();
    _controller.text = filenameFormat;
    _focusNode.requestFocus();
  }

  _save() {
    HiveUtil.put(
      HiveUtil.filenameFormatKey,
      _controller.text,
    );
    widget.onSaved?.call(_controller.text);
    IToast.showTop(S.current.saveSuccess);
  }

  _reset() {
    _controller.text = defaultFilenameFormat;
    HiveUtil.put(
      HiveUtil.filenameFormatKey,
      defaultFilenameFormat,
    );
    widget.onSaved?.call(defaultFilenameFormat);
    IToast.showTop(S.current.resetSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ItemBuilder.buildResponsiveAppBar(
        showBack: true,
        title: S.current.filenameFormat,
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: EasyRefresh(
        child: ScrollConfiguration(
          behavior: NoShadowScrollBehavior(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ItemBuilder.buildInputItem(
                context: context,
                focusNode: _focusNode,
                hint: S.current.inputFilenameFormat,
                textInputAction: TextInputAction.done,
                controller: _controller,
                tailingType: TailingType.widget,
                onSubmitted: (text) {
                  _save();
                },
                tailingWidget: Row(
                  children: [
                    const SizedBox(width: 5),
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: const Icon(Icons.refresh_rounded),
                      onTap: _reset,
                    ),
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: const Icon(Icons.save_rounded),
                      onTap: _save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ItemBuilder.buildRoundButton(
                      context,
                      text: S.current.availableFields,
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.apply(fontWeightDelta: 2),
                      radius: 10,
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                      background: Colors.transparent,
                    ),
                    ...FilenameField.values.map((field) {
                      return ItemBuilder.buildRoundButton(
                        context,
                        text: field.label,
                        textStyle: Theme.of(context).textTheme.titleSmall,
                        radius: 10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        background: Theme.of(context).canvasColor,
                        onTap: () {
                          _focusNode.requestFocus();
                          final text = _controller.text;
                          int cursor = _controller.selection.baseOffset;
                          if (cursor < 0) cursor = text.length;
                          cursor = cursor.clamp(0, text.length);
                          final newText = text.substring(0, cursor) +
                              field.format +
                              text.substring(cursor);
                          _controller.text = newText;
                          _controller.selection = TextSelection.fromPosition(
                              TextPosition(
                                  offset: cursor + field.format.length));
                        },
                      );
                    }),
                  ]),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).canvasColor,
                ),
                child: Table(
                  // defaultColumnWidth: const IntrinsicColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _buildRow([
                      S.current.field,
                      S.current.description,
                      S.current.example,
                    ], fontWeightDelta: 2),
                    ...List.generate(
                      FilenameField.values.length,
                      (index) {
                        return _buildRow([
                          FilenameField.values[index].label,
                          FilenameField.values[index].description,
                          FilenameField.values[index].example,
                        ], useBorder: index != FilenameField.values.length - 1);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {int fontWeightDelta = 0}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.apply(fontWeightDelta: fontWeightDelta),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(List<String> cells,
      {int fontWeightDelta = 0, bool useBorder = true}) {
    return TableRow(
      decoration: BoxDecoration(
        border: useBorder
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              )
            : null,
      ),
      children: cells
          .map((e) => _buildCell(e, fontWeightDelta: fontWeightDelta))
          .toList(),
    );
  }
}
