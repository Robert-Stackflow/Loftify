import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Utils/crypt_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Resources/theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class SlideCaptchaBottomSheet extends StatefulWidget {
  const SlideCaptchaBottomSheet({
    super.key,
  });

  @override
  SlideCaptchaBottomSheetState createState() => SlideCaptchaBottomSheetState();
}

class SlideCaptchaBottomSheetState extends State<SlideCaptchaBottomSheet> {
  String? bg;
  String? front;
  String? id;
  double frontLeftOffset = 0;
  double scale = 1.1;
  Uint8List? bg64;
  Uint8List? front64;
  String secret =
      "KrHL6WUUlI9mKt+4JApPjwjhn+2UNa8tbe+NzFF31msY94ZXTYjj2trGN3MQMv6yXON9fgpGkesyKgCQ1lBf0hzviueHHjQYNEtEE9tvK8PkrXBOgmChlgFF/khdqpVvPxuEUc9wFu+nx8CX/M9V9RkLG7/x6jO4tuZMs3gscXyFEOSy8htUclnY8Msu6GipKGrAJZGU/Qc18HeHBKRj3cbPvzhBD/p1HOG8d51faoEYHri98dsl/30aXd3BkAIlnNDvlJ8cqKncXP1LDFwZ8VrEZtSaLV8IShZy25/ncHVBQjRxOvojUqY/DQzti/rrQmWSPNLmNDkiR2QiEVZfCQ==";
  String status = "";
  Color statusBackground = Colors.green;
  bool showStatus = false;
  ImageInfo? bgInfo;

  @override
  void initState() {
    super.initState();
    _fetchCaptcha();
  }

  _fetchCaptcha() async {
    await LoginApi.getSlideCaptcha().then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          frontLeftOffset = 0;
          bg = value['data']['bg'];
          front = value['data']['front'];
          id = value['data']['id'];
          bg64 = base64Decode(bg!);
          front64 = base64Decode(front!);
          getImageInfo(Image.memory(bg64!));
        }
      } catch (e, t) {
        ILogger.error("Failed to load captcha", e, t);
        IToast.showTop(S.current.getSlideCaptchaFailed);
      } finally {
        if (mounted) setState(() {});
      }
    });
  }

  double get preferWidth =>
      bgInfo != null ? bgInfo!.image.width.toDouble() : 320;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: preferWidth,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            ItemBuilder.buildDivider(context, horizontal: 12, vertical: 0),
            Stack(
              children: [
                ItemBuilder.buildLoadingDialog(
                  context,
                  text: S.current.loading,
                  background: Colors.transparent,
                  size: 40,
                  topPadding: 77,
                  bottomPadding: 77,
                ),
                Column(
                  children: [
                    if (bg64 != null && front64 != null) _buildCaptcha(),
                    if (bg64 != null && front64 != null) _buildDragHandle(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              S.current.pleaseFinishSlideCaptcha,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(
              Icons.close_rounded,
              color: Theme.of(context).textTheme.labelSmall?.color,
              size: 20,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  updateState(bool success) {
    if (success) {
      statusBackground = Colors.green;
      status = S.current.validSuccess;
      showStatus = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context);
      });
    } else {
      statusBackground = Colors.redAccent;
      status = S.current.validFailed;
      showStatus = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 1000), () {
        showStatus = false;
        if (mounted) setState(() {});
      });
    }
  }

  getImageInfo(Image image) async {
    var completer = Completer<ImageInfo>();
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, _) {
      completer.complete(imageInfo);
    }));
    bgInfo = await completer.future;
    setState(() {});
  }

  _buildCaptcha() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bg64!),
          ),
          Positioned(
            left: frontLeftOffset,
            top: 0,
            child: Image.memory(front64!, scale: scale),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: GestureDetector(
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              onTap: () {
                _fetchCaptcha();
              },
            ),
          ),
          Positioned(
            bottom: 0,
            child: Visibility(
              visible: showStatus,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                width: preferWidth - 32,
                decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8))),
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
        ],
      ),
    );
  }

  _buildDragHandle() {
    return Container(
      width: preferWidth,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 6),
      child: Stack(
        children: [
          Container(
            height: 40,
            width: preferWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).dividerColor,
            ),
            alignment: Alignment.center,
            child: Text(
              S.current.slideToComplete,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Container(
            height: 40,
            width: frontLeftOffset > 30 ? frontLeftOffset : 0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).dividerColor,
            ),
            alignment: Alignment.center,
          ),
          Positioned(
            left: frontLeftOffset,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  double newOffset = frontLeftOffset + details.delta.dx;
                  double maxOffset = preferWidth - 72;
                  if (newOffset >= 0 && newOffset <= maxOffset) {
                    frontLeftOffset = newOffset;
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                String rawKey = Utils.getRandomString(length: 16);
                String rawIv = Utils.getRandomString(length: 16);
                LoginApi.verifySlideCaptcha(
                  id: id!,
                  offset: frontLeftOffset * scale,
                  rawKey: rawKey,
                  rawIv: rawIv,
                ).then((value) {
                  if (value == null) {
                    IToast.showTop(S.current.sendValidationFailed);
                  } else {
                    var res = CryptUtil.decryptDataByAES(value, rawKey, rawIv);
                    res = json.decode(res);
                    if (res['code'] != 0) {
                      updateState(false);
                      IToast.showTop(res['msg']);
                      _fetchCaptcha();
                    } else if (!res['data']['success']) {
                      updateState(false);
                      _fetchCaptcha();
                    } else if (res['data']['success']) {
                      appProvider.captchaToken = res['data']['token'];
                      updateState(true);
                    }
                  }
                });
              },
              child: ItemBuilder.buildClickItem(
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MyTheme.getBackground(context),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.keyboard_double_arrow_right_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
