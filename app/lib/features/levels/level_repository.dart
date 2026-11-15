import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flow_core/flow_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../services/remote_config_service.dart';

/// Packs shipped inside the app, in campaign order.
const List<String> bundledPackIds = ['core_001', 'core_002'];

const int levelsPerSet = 12;

/// The whole campaign: every pack's levels in order, numbered from 1.
class Campaign {
  Campaign(List<LevelPack> packs)
    : levels = [for (final p in packs) ...p.levels],
      _packOf = {
        for (final p in packs)
          for (final l in p.levels) l.id: p.packId,
      } {
    for (var i = 0; i < levels.length; i++) {
      _numberOf[levels[i].id] = i + 1;
    }
  }

  final List<LevelDef> levels;
  final Map<String, String> _packOf;
  final Map<String, int> _numberOf = {};

  int get length => levels.length;

  LevelDef? byNumber(int number) =>
      number >= 1 && number <= levels.length ? levels[number - 1] : null;

  LevelDef? byId(String id) => byNumber(_numberOf[id] ?? 0);

  int numberOf(String id) => _numberOf[id] ?? 0;

  String packOf(String id) => _packOf[id] ?? '';

  /// 1-based number of the first level not completed yet, or `length + 1`
  /// when everything is done.
  int nextUnfinished(bool Function(String levelId) isDone) {
    for (var i = 0; i < levels.length; i++) {
      if (!isDone(levels[i].id)) return i + 1;
    }
    return levels.length + 1;
  }
}

/// Loads level packs: bundled assets plus packs downloaded from Cloud
/// Storage and cached on device. For each pack id the highest version wins.
class LevelRepository {
  LevelRepository({
    required AssetBundle bundle,
    required Future<Directory> Function() cacheDir,
    HttpClient Function()? httpClient,
  }) : _bundle = bundle,
       _cacheDir = cacheDir,
       _httpClient = httpClient ?? HttpClient.new;

  final AssetBundle _bundle;
  final Future<Directory> Function() _cacheDir;
  final HttpClient Function() _httpClient;

  static const int _maxPackBytes = 4 * 1024 * 1024;
  static final RegExp _safeId = RegExp(r'^[a-z0-9_]{1,40}$');

  Future<Directory> _packsDir() async {
    final dir = Directory('${(await _cacheDir()).path}/packs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Reads a bundled pack. Decoded here rather than with `loadString`, which
  /// hands large files to another isolate for no real gain at this size.
  Future<String> _asset(String id) async {
    final data = await _bundle.load('assets/levels/$id.json');
    return utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<Campaign> loadCampaign() async {
    final best = <String, LevelPack>{};
    for (final id in bundledPackIds) {
      final pack = decodeLevelPack(await _asset(id));
      best[pack.packId] = pack;
    }
    for (final pack in await _cachedPacks()) {
      final have = best[pack.packId];
      if (have == null || pack.version > have.version) {
        best[pack.packId] = pack;
      }
    }
    final ids = best.keys.toList()..sort();
    return Campaign([for (final id in ids) best[id]!]);
  }

  Future<List<LevelPack>> _cachedPacks() async {
    final out = <LevelPack>[];
    try {
      final dir = await _packsDir();
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.json')) continue;
        try {
          out.add(decodeLevelPack(await f.readAsString()));
        } on Object catch (e) {
          debugPrint('Dropping unreadable pack ${f.path}: $e');
          f.deleteSync();
        }
      }
    } on Object catch (e) {
      debugPrint('Pack cache unavailable: $e');
    }
    return out;
  }

  /// Downloads packs from [manifest] that are newer than what is on device.
  /// Returns how many were saved. Never throws: the game is offline-first.
  Future<int> syncPacks(List<PackManifestEntry> manifest) async {
    if (manifest.isEmpty) return 0;
    final have = <String, int>{};
    for (final id in bundledPackIds) {
      try {
        final json = jsonDecode(await _asset(id)) as Map<String, Object?>;
        have[id] = (json['version'] as num?)?.toInt() ?? 1;
      } on Object {
        have[id] = 1;
      }
    }
    for (final p in await _cachedPacks()) {
      if (p.version > (have[p.packId] ?? 0)) have[p.packId] = p.version;
    }

    var saved = 0;
    for (final entry in manifest) {
      if (!_safeId.hasMatch(entry.id)) continue;
      if (entry.version <= (have[entry.id] ?? 0)) continue;
      try {
        final body = await _download(Uri.parse(entry.url));
        final pack = decodeLevelPack(body);
        if (pack.packId != entry.id || pack.levels.isEmpty) continue;
        final dir = await _packsDir();
        final tmp = File('${dir.path}/${entry.id}.json.tmp');
        await tmp.writeAsString(body, flush: true);
        await tmp.rename('${dir.path}/${entry.id}.json');
        saved++;
      } on Object catch (e) {
        debugPrint('Pack ${entry.id} download failed: $e');
      }
    }
    return saved;
  }

  Future<String> _download(Uri uri) async {
    if (uri.scheme != 'https') throw const FormatException('https only');
    final client =
        _httpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        bytes.add(chunk);
        if (bytes.length > _maxPackBytes) {
          throw const FormatException('Pack too large');
        }
      }
      return utf8.decode(bytes.takeBytes());
    } finally {
      client.close(force: true);
    }
  }
}
