import 'package:flutter/material.dart';
import 'package:loftify/Utils/lottie_util.dart';

class LoadingDialogWidget extends StatefulWidget {
  final bool dismissible;

  final String? title;

  final double size;

  const LoadingDialogWidget({
    super.key,
    this.dismissible = false,
    this.title,
    this.size = 40,
  });

  @override
  State<StatefulWidget> createState() => LoadingDialogWidgetState();
}

class LoadingDialogWidgetState extends State<LoadingDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PopScope(
          canPop: widget.dismissible,
          onPopInvoked: (_) => Future.value(widget.dismissible),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).canvasColor,
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LottieUtil.load(LottieUtil.getLoadingPath(context),
                    size: widget.size),
                if (widget.title != null) const SizedBox(height: 16),
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
