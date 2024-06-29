import 'package:flutter/material.dart';
import 'package:loftify/Utils/iprint.dart';

import '../../Utils/utils.dart';
import '../Item/item_builder.dart';

class InputBottomSheet extends StatefulWidget {
  const InputBottomSheet({
    super.key,
    this.maxLines = 5,
    this.minLines = 1,
    this.hint,
    this.controller,
    required this.buttonText,
    this.onConfirm,
    required this.text,
    this.onCancel,
    this.title = "",
  });

  final String? hint;
  final String text;
  final String title;
  final int maxLines;
  final int minLines;
  final Function()? onCancel;
  final Function(String)? onConfirm;
  final TextEditingController? controller;
  final String buttonText;

  @override
  InputBottomSheetState createState() => InputBottomSheetState();
}

class InputBottomSheetState extends State<InputBottomSheet> {
  TextEditingController controller = TextEditingController();
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller.value = TextEditingValue(text: widget.text);
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (Utils.isNotEmpty(widget.title)) _buildHeader(),
            TextField(
              focusNode: _focusNode,
              controller: controller,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              cursorColor: Theme.of(context).primaryColor,
              cursorHeight: 22,
              cursorRadius: const Radius.circular(3),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
              ),
            ),
            const SizedBox(width: 8.0),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        widget.title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SizedBox(
              height: 45,
              child: ItemBuilder.buildRoundButton(
                context,
                text: "取消",
                onTap: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 45,
              child: ItemBuilder.buildRoundButton(
                context,
                background: Theme.of(context).primaryColor,
                color: Colors.white,
                text: "确定",
                onTap: () {
                  widget.onConfirm?.call(controller.text);
                  Navigator.of(context).pop();
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
