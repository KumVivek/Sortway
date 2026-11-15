import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a picture and a caption to the system share sheet, from where the
/// player picks WhatsApp, Instagram, or any other app. The game itself has
/// no social features and never learns where (or whether) it was posted.
abstract class ShareService {
  /// Returns false if the share sheet could not be opened.
  Future<bool> shareImage(Uint8List png, {required String text, Rect? origin});
}

class SystemShareService implements ShareService {
  @override
  Future<bool> shareImage(
    Uint8List png, {
    required String text,
    Rect? origin,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/flow_sort_share.png');
      await file.writeAsBytes(png, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(file.path, mimeType: 'image/png')],
          // Required on iPad, where the sheet is a popover.
          sharePositionOrigin: origin,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } on Object catch (e) {
      debugPrint('share failed: $e');
      return false;
    }
  }
}

/// Fake for tests: remembers what was shared.
class FakeShareService implements ShareService {
  bool available = true;
  final List<({Uint8List png, String text})> shared = [];

  @override
  Future<bool> shareImage(
    Uint8List png, {
    required String text,
    Rect? origin,
  }) async {
    if (!available) return false;
    shared.add((png: png, text: text));
    return true;
  }
}
