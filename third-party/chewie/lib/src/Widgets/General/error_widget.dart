import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/cupertino.dart';

class CustomErrorWidget extends StatefulWidget {
  final String? text;
  final String? buttonText;
  final Function()? onTap;

  const CustomErrorWidget({
    super.key,
    this.text,
    this.buttonText,
    this.onTap,
  });

  @override
  CustomErrorWidgetState createState() => CustomErrorWidgetState();
}

class CustomErrorWidgetState extends State<CustomErrorWidget> {
  @override
  Widget build(BuildContext context) {
    final stateBuilder = chewieProvider.stateWidgetBuilder;
    if (stateBuilder != null) {
      return stateBuilder(
        context,
        ChewieStateViewConfig(
          type: ChewieStateViewType.error,
          text: widget.text ?? chewieLocalizations.loadFailed,
          actionLabel: widget.buttonText ?? chewieLocalizations.retry,
          onAction: widget.onTap,
          icon: ChewieIcons.error,
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.text ?? chewieLocalizations.loadFailed,
            style: ChewieTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          RoundIconTextButton(
            text: widget.buttonText ?? chewieLocalizations.retry,
            onPressed: widget.onTap,
          ),
        ],
      ),
    );
  }
}
