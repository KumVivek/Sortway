// Renders the app icon and launch logo (lib/ui/app_icon.dart) into every
// size Android, iOS and the Play Store need. Each size is drawn from vectors,
// so small icons stay sharp.
//
// Run from app/ after changing the icon:
//   flutter test tool/render_icons_test.dart
//
// It lives outside test/ so the normal `flutter test` run does not rewrite
// files.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flow_sort/ui/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('render icons', () async {
    // iOS: every file listed in the app icon set. Opaque: App Store Connect
    // rejects a marketing icon with an alpha channel.
    const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final pattern = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png');
    for (final f in Directory(iosDir).listSync().whereType<File>()) {
      final m = pattern.firstMatch(f.path);
      if (m == null) continue;
      final px = (double.parse(m[1]!) * int.parse(m[2]!)).round();
      await _write(f.path, px, opaque: true);
    }

    // Android.
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    const res = 'android/app/src/main/res';
    for (final MapEntry(key: d, value: k) in densities.entries) {
      // Legacy square icon for launchers before Android 8.
      await _write('$res/mipmap-$d/ic_launcher.png', (48 * k).round(), opaque: true);
      // Adaptive-icon foreground: 108dp canvas, art inside the 66dp safe zone.
      await _write(
        '$res/mipmap-$d/ic_launcher_foreground.png',
        (108 * k).round(),
        background: false,
        scale: 0.74,
      );
      // Logo on the launch screen before Android 12.
      await _write(
        '$res/drawable-$d/launch_logo.png',
        (120 * k).round(),
        background: false,
      );
    }

    // iOS launch screen logo (168pt, centred by LaunchScreen.storyboard).
    const launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    await _write('$launch/LaunchImage.png', 168, background: false);
    await _write('$launch/LaunchImage@2x.png', 336, background: false);
    await _write('$launch/LaunchImage@3x.png', 504, background: false);

    // Play Store listing icon.
    await _write('store/play_icon_512.png', 512, opaque: true);
  });
}

Future<void> _write(
  String path,
  int px, {
  bool background = true,
  bool opaque = false,
  double scale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final size = Size.square(px.toDouble());
  paintAppIcon(Canvas(recorder), size, background: background, scale: scale);
  final picture = recorder.endRecording();
  final image = await picture.toImage(px, px);
  final Uint8List bytes;
  if (opaque) {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    bytes = _encodeRgbPng(rgba!.buffer.asUint8List(), px, px);
  } else {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = png!.buffer.asUint8List();
  }
  image.dispose();
  picture.dispose();
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

/// Minimal PNG encoder for 8-bit RGB (no alpha channel).
Uint8List _encodeRgbPng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  final out = BytesBuilder()
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    out.add(_u32(data.length));
    out.add(typeBytes);
    out.add(data);
    out.add(_u32(_crc32([...typeBytes, ...data])));
  }

  chunk('IHDR', [..._u32(width), ..._u32(height), 8, 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes()));
  chunk('IEND', const []);
  return out.takeBytes();
}

List<int> _u32(int v) => [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255];

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}
