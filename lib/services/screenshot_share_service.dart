import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// RepaintBoundary で囲ったウィジェットを PNG にレンダリングしてシェアシートに渡す。
class ScreenshotShareService {
  /// [boundaryKey] が指す RepaintBoundary の現在状態を画像化し、
  /// 一時ファイルに書き出して share_plus でシェアする。
  ///
  /// 失敗時は false を返す（呼び出し側で必要なら SnackBar 等を出す）。
  static Future<bool> shareWidget({
    required GlobalKey boundaryKey,
    required String text,
    String filenamePrefix = 'loud',
    double pixelRatio = 3.0,
  }) async {
    try {
      final bytes = await _capturePng(boundaryKey, pixelRatio);
      if (bytes == null) return false;
      final file = await _writeTempPng(bytes, filenamePrefix);
      await SharePlus.instance.share(
        ShareParams(text: text, files: [XFile(file.path)]),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> _capturePng(
    GlobalKey key,
    double pixelRatio,
  ) async {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  static Future<File> _writeTempPng(Uint8List bytes, String prefix) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${Directory.systemTemp.path}/${prefix}_$ts.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
