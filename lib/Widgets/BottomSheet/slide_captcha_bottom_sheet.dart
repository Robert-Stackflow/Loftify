import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';

import '../../Utils/app_provider.dart';
import '../../l10n/l10n.dart';
import '../loftify_icons.dart';

typedef SlideCaptchaChallengeLoader = Future<dynamic> Function();
typedef SlideCaptchaChallengeVerifier = Future<dynamic> Function({
  required String id,
  required double offset,
  required String rawKey,
  required String rawIv,
});

@immutable
class SlideCaptchaGeometry {
  const SlideCaptchaGeometry._({
    required this.panelWidth,
    required this.contentWidth,
    required this.imageHeight,
    required this.sourceScale,
    required this.sourceTravel,
    required this.puzzleTravel,
    required this.handleTravel,
    required this.puzzleWidth,
  });

  static const double outerPadding = 16;
  static const double contentPadding = 16;
  static const double handleWidth = 40;

  factory SlideCaptchaGeometry.calculate({
    required double availableWidth,
    required Size sourceSize,
    required double puzzleSourceWidth,
  }) {
    final safeSourceWidth = math.max(1.0, sourceSize.width);
    final safeSourceHeight = math.max(1.0, sourceSize.height);
    final safeAvailableWidth = availableWidth.isFinite
        ? math.max(1.0, availableWidth)
        : safeSourceWidth + outerPadding * 2;
    final panelWidth = math.min(
      safeSourceWidth,
      math.max(1.0, safeAvailableWidth - outerPadding * 2),
    );
    final contentWidth = math.max(
      1.0,
      panelWidth - contentPadding * 2,
    );
    final sourceScale = safeSourceWidth / contentWidth;
    final safePuzzleSourceWidth =
        puzzleSourceWidth.clamp(1.0, safeSourceWidth).toDouble();
    final puzzleWidth = safePuzzleSourceWidth / sourceScale;

    return SlideCaptchaGeometry._(
      panelWidth: panelWidth,
      contentWidth: contentWidth,
      imageHeight: safeSourceHeight / sourceScale,
      sourceScale: sourceScale,
      sourceTravel: math.max(0.0, safeSourceWidth - safePuzzleSourceWidth),
      puzzleTravel: math.max(0.0, contentWidth - puzzleWidth),
      handleTravel: math.max(0.0, contentWidth - handleWidth),
      puzzleWidth: puzzleWidth,
    );
  }

  final double panelWidth;
  final double contentWidth;
  final double imageHeight;
  final double sourceScale;
  final double sourceTravel;
  final double puzzleTravel;
  final double handleTravel;
  final double puzzleWidth;

  double clampProgress(double progress) => progress.clamp(0.0, 1.0);

  double progressAfterDelta(double progress, double logicalDelta) {
    if (handleTravel <= 0) return 0;
    return clampProgress(progress + logicalDelta / handleTravel);
  }

  double handleOffset(double progress) =>
      handleTravel * clampProgress(progress);

  double puzzleOffset(double progress) =>
      puzzleTravel * clampProgress(progress);

  double sourceOffset(double progress) =>
      sourceTravel * clampProgress(progress);
}

class SlideCaptchaBottomSheet extends StatefulWidget {
  const SlideCaptchaBottomSheet({
    super.key,
    this.challengeLoader,
    this.challengeVerifier,
  });

  final SlideCaptchaChallengeLoader? challengeLoader;
  final SlideCaptchaChallengeVerifier? challengeVerifier;

  @override
  SlideCaptchaBottomSheetState createState() => SlideCaptchaBottomSheetState();
}

class SlideCaptchaBottomSheetState extends State<SlideCaptchaBottomSheet> {
  String? id;
  double _dragProgress = 0;
  Uint8List? bg64;
  Uint8List? front64;
  String status = "";
  Color statusBackground = Colors.green;
  bool showStatus = false;
  bool _isLoading = true;
  bool _isVerifying = false;
  Size? _backgroundSize;
  Size? _puzzleSize;
  int _requestGeneration = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _fetchCaptcha();
  }

  @override
  void dispose() {
    _requestGeneration++;
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCaptcha() async {
    final generation = ++_requestGeneration;
    _statusTimer?.cancel();
    if (mounted) {
      setState(() {
        _dragProgress = 0;
        _isLoading = true;
        _isVerifying = false;
        showStatus = false;
        id = null;
        bg64 = null;
        front64 = null;
        _backgroundSize = null;
        _puzzleSize = null;
      });
    }

    try {
      final value =
          await (widget.challengeLoader?.call() ?? LoginApi.getSlideCaptcha());
      if (!mounted || generation != _requestGeneration) return;
      if (value['code'] != 0) {
        IToast.showTop(
            value['msg']?.toString() ?? appLocalizations.getSlideCaptchaFailed);
        setState(() => _isLoading = false);
        return;
      }

      final data = value['data'];
      final backgroundBytes = base64Decode(data['bg'] as String);
      final puzzleBytes = base64Decode(data['front'] as String);
      final sizes = await Future.wait([
        _decodeImageSize(backgroundBytes),
        _decodeImageSize(puzzleBytes),
      ]);
      if (!mounted || generation != _requestGeneration) return;

      setState(() {
        id = data['id']?.toString();
        bg64 = backgroundBytes;
        front64 = puzzleBytes;
        _backgroundSize = sizes[0];
        _puzzleSize = sizes[1];
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      ILogger.error("Failed to load captcha", error, stackTrace);
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _isLoading = false);
      IToast.showTop(appLocalizations.getSlideCaptchaFailed);
    }
  }

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final backgroundSize = _backgroundSize ?? const Size(352, 160);
          final puzzleSourceWidth = _puzzleSize?.width ?? 44;
          final geometry = SlideCaptchaGeometry.calculate(
            availableWidth: constraints.maxWidth,
            sourceSize: backgroundSize,
            puzzleSourceWidth: puzzleSourceWidth,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SlideCaptchaGeometry.outerPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(
                  0,
                  constraints.maxHeight - SlideCaptchaGeometry.outerPadding * 2,
                ),
              ),
              child: Center(
                child: Container(
                  key: const ValueKey('slideCaptchaPanel'),
                  width: geometry.panelWidth,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const MyDivider(horizontal: 12, vertical: 0),
                      if (_isLoading)
                        SizedBox(
                          height: math.max(180, geometry.imageHeight + 64),
                          child: LoadingWidget(
                            text: appLocalizations.loading,
                            background: Colors.transparent,
                            size: 40,
                          ),
                        )
                      else if (bg64 != null && front64 != null)
                        Column(
                          children: [
                            _buildCaptcha(geometry),
                            _buildDragHandle(geometry),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton.icon(
                            onPressed: _fetchCaptcha,
                            icon: const ChewieIcon(LoftifyIcons.retry),
                            label: Text(appLocalizations.retry),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              appLocalizations.pleaseFinishSlideCaptcha,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ChewieIconButton(
            icon: LoftifyIcons.close,
            iconSize: 20,
            tooltip: appLocalizations.cancel,
            foregroundColor: Theme.of(context).textTheme.labelSmall?.color,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showVerificationStatus(bool success) {
    if (!mounted) return;
    _statusTimer?.cancel();
    setState(() {
      _isVerifying = false;
      statusBackground = success ? Colors.green : Colors.redAccent;
      status = success
          ? appLocalizations.validSuccess
          : appLocalizations.validFailed;
      showStatus = true;
    });
    _statusTimer = Timer(
      Duration(milliseconds: success ? 500 : 900),
      () {
        if (!mounted) return;
        if (success) {
          Navigator.maybePop(context);
        } else {
          _fetchCaptcha();
        }
      },
    );
  }

  Future<void> _verifyCaptcha(SlideCaptchaGeometry geometry) async {
    final captchaId = id;
    if (captchaId == null || _isVerifying) return;
    setState(() => _isVerifying = true);

    final rawKey = StringUtil.getRandomString(length: 16);
    final rawIv = StringUtil.getRandomString(length: 16);
    try {
      final sourceOffset = geometry.sourceOffset(_dragProgress);
      final value = await (widget.challengeVerifier?.call(
            id: captchaId,
            offset: sourceOffset,
            rawKey: rawKey,
            rawIv: rawIv,
          ) ??
          LoginApi.verifySlideCaptcha(
            id: captchaId,
            offset: sourceOffset,
            rawKey: rawKey,
            rawIv: rawIv,
          ));
      if (!mounted) return;
      if (value == null) {
        IToast.showTop(appLocalizations.sendValidationFailed);
        _showVerificationStatus(false);
        return;
      }

      final decrypted = CryptUtil.decryptDataByAES(value, rawKey, rawIv);
      final response = json.decode(decrypted);
      if (response['code'] != 0) {
        IToast.showTop(
            response['msg']?.toString() ?? appLocalizations.validFailed);
        _showVerificationStatus(false);
      } else if (response['data']['success'] == true) {
        appProvider.captchaToken = response['data']['token'];
        _showVerificationStatus(true);
      } else {
        _showVerificationStatus(false);
      }
    } catch (error, stackTrace) {
      ILogger.error("Failed to verify captcha", error, stackTrace);
      if (!mounted) return;
      IToast.showTop(appLocalizations.sendValidationFailed);
      _showVerificationStatus(false);
    }
  }

  Widget _buildCaptcha(SlideCaptchaGeometry geometry) {
    final puzzleSize = _puzzleSize ?? const Size(44, 44);
    final puzzleHeight = puzzleSize.height / geometry.sourceScale;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SlideCaptchaGeometry.contentPadding,
        vertical: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: geometry.contentWidth,
          height: geometry.imageHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Image.memory(
                  bg64!,
                  key: const ValueKey('slideCaptchaBackground'),
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned(
                left: geometry.puzzleOffset(_dragProgress),
                top: 0,
                child: Image.memory(
                  front64!,
                  key: const ValueKey('slideCaptchaPuzzle'),
                  width: geometry.puzzleWidth,
                  height: puzzleHeight,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: ChewieIconButton(
                  icon: LoftifyIcons.refresh,
                  tooltip: appLocalizations.refresh,
                  iconSize: 20,
                  tapTargetSize: 44,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black45,
                  cornerRadius: 22,
                  onPressed: _isVerifying ? null : _fetchCaptcha,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: showStatus ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      color: statusBackground,
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.labelMedium?.apply(
                              color: Colors.white,
                              fontSizeDelta: 1,
                              fontWeightDelta: 2,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(SlideCaptchaGeometry geometry) {
    final colorScheme = Theme.of(context).colorScheme;
    final handleOffset = geometry.handleOffset(_dragProgress);
    final fillWidth = _dragProgress <= 0
        ? 0.0
        : handleOffset + SlideCaptchaGeometry.handleWidth;

    return Semantics(
      label: appLocalizations.slideToComplete,
      value: '${(_dragProgress * 100).round()}%',
      slider: true,
      child: Padding(
        padding: const EdgeInsets.only(
          left: SlideCaptchaGeometry.contentPadding,
          right: SlideCaptchaGeometry.contentPadding,
          top: 6,
          bottom: 6,
        ),
        child: SizedBox(
          key: const ValueKey('slideCaptchaTrack'),
          width: geometry.contentWidth,
          height: SlideCaptchaGeometry.handleWidth,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).dividerColor,
                  ),
                  child: Center(
                    child: Text(
                      appLocalizations.slideToComplete,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  key: const ValueKey('slideCaptchaProgress'),
                  width: fillWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                left: handleOffset,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onHorizontalDragUpdate: _isVerifying
                      ? null
                      : (details) {
                          setState(() {
                            _dragProgress = geometry.progressAfterDelta(
                              _dragProgress,
                              details.delta.dx,
                            );
                          });
                        },
                  onHorizontalDragEnd:
                      _isVerifying ? null : (_) => _verifyCaptcha(geometry),
                  child: Container(
                    key: const ValueKey('slideCaptchaHandle'),
                    width: SlideCaptchaGeometry.handleWidth,
                    height: SlideCaptchaGeometry.handleWidth,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ChewieIcon(
                      _isVerifying ? LoftifyIcons.more : LoftifyIcons.slide,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
