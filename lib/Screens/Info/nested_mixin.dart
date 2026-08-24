import 'package:flutter/cupertino.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:loftify/Utils/lottie_files.dart';

Header buildNestedRefreshHeader() => LottieCupertinoHeader(
      backgroundColor: const Color(0x00000000),
      indicator: LottieFiles.buildLoadingAnimation(28, false),
      hapticFeedback: true,
      triggerOffset: 44,
      maxOverOffset: 64,
      radius: 14,
    );

class NestedRefreshRequest {
  const NestedRefreshRequest(this.targetId);

  final String targetId;
}

abstract class StatefulWidgetForNested extends StatefulWidget {
  final bool nested;
  final ValueNotifier<NestedRefreshRequest?>? refreshListenable;
  final String? refreshId;

  const StatefulWidgetForNested({
    super.key,
    required this.nested,
    this.refreshListenable,
    this.refreshId,
  });
}

mixin NestedRefreshSignalMixin<T extends StatefulWidgetForNested> on State<T> {
  VoidCallback? _nestedRefreshCallback;
  VoidCallback? _nestedRefreshListener;

  void bindNestedRefreshSignal(VoidCallback callback) {
    _nestedRefreshCallback = callback;
    _nestedRefreshListener = () {
      final request = widget.refreshListenable?.value;
      if (request != null && request.targetId == widget.refreshId) {
        callback();
      }
    };
    widget.refreshListenable?.addListener(_nestedRefreshListener!);
  }

  void unbindNestedRefreshSignal() {
    final callback = _nestedRefreshCallback;
    if (callback != null) {
      widget.refreshListenable?.removeListener(_nestedRefreshListener!);
    }
    _nestedRefreshCallback = null;
    _nestedRefreshListener = null;
  }
}
