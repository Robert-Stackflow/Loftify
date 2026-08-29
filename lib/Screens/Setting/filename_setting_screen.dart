import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class FilenameSettingScreen extends BaseSettingScreen {
  const FilenameSettingScreen({
    super.key,
    this.onSaved,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  final Function(String)? onSaved;

  static const String routeName = "/setting/filename";

  @override
  State<FilenameSettingScreen> createState() => _FilenameSettingScreenState();
}

class _FilenameSettingScreenState
    extends BaseDynamicState<FilenameSettingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String filenameFormat = ChewieHiveUtil.getString(HiveUtil.filenameFormatKey,
          defaultValue: defaultFilenameFormat) ??
      defaultFilenameFormat;

  @override
  void initState() {
    super.initState();
    _controller.text = filenameFormat;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    ChewieHiveUtil.put(
      HiveUtil.filenameFormatKey,
      _controller.text,
    );
    widget.onSaved?.call(_controller.text);
    IToast.showTop(appLocalizations.saveSuccess);
  }

  void _reset() {
    _controller.text = defaultFilenameFormat;
    ChewieHiveUtil.put(
      HiveUtil.filenameFormatKey,
      defaultFilenameFormat,
    );
    widget.onSaved?.call(defaultFilenameFormat);
    IToast.showTop(appLocalizations.resetSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.35;
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.filenameFormat,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          title: appLocalizations.filenameFormat,
          children: [
            InputItem(
              focusNode: _focusNode,
              hint: appLocalizations.inputFilenameFormat,
              textInputAction: TextInputAction.done,
              controller: _controller,
              onSubmit: (text) {
                _save();
              },
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.widget,
                widget: Row(
                  children: [
                    const SizedBox(width: 5),
                    CircleIconButton(
                      context: context,
                      icon: const ChewieIcon(LoftifyIcons.refresh),
                      onTap: _reset,
                    ),
                    CircleIconButton(
                      context: context,
                      icon: const ChewieIcon(LoftifyIcons.save),
                      onTap: _save,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: [
                  RoundIconTextButton(
                    text: appLocalizations.availableFields,
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.apply(fontWeightDelta: 2),
                    radius: 10,
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                    background: Colors.transparent,
                  ),
                  ...FilenameField.values.map((field) {
                    return RoundIconTextButton(
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
                            TextPosition(offset: cursor + field.format.length));
                      },
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).canvasColor,
                ),
                child: compact
                    ? Column(
                        children: List.generate(
                          FilenameField.values.length,
                          (index) => _buildCompactField(
                            FilenameField.values[index],
                            useBorder: index != FilenameField.values.length - 1,
                          ),
                        ),
                      )
                    : Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          _buildRow([
                            appLocalizations.field,
                            appLocalizations.description,
                            appLocalizations.example,
                          ], fontWeightDelta: 2),
                          ...List.generate(
                            FilenameField.values.length,
                            (index) {
                              return _buildRow([
                                FilenameField.values[index].label,
                                FilenameField.values[index].description,
                                FilenameField.values[index].example,
                              ],
                                  useBorder:
                                      index != FilenameField.values.length - 1);
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactField(
    FilenameField field, {
    required bool useBorder,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('filename-field-${field.name}'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            field.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${appLocalizations.example}: ${field.example}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  height: 1.35,
                ),
          ),
        ],
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
