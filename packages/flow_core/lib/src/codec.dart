import 'dart:convert';

import 'level.dart';

/// Parses a level pack from its JSON text (plan §6).
LevelPack decodeLevelPack(String source) {
  final json = jsonDecode(source);
  if (json is! Map<String, Object?>) {
    throw const FormatException('Level pack must be a JSON object');
  }
  return LevelPack.fromJson(json);
}

String encodeLevelPack(LevelPack pack, {bool pretty = false}) =>
    pretty
        ? const JsonEncoder.withIndent(' ').convert(pack.toJson())
        : jsonEncode(pack.toJson());
