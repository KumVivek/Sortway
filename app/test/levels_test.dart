import 'dart:io';

import 'package:flow_core/flow_core.dart';
import 'package:flow_sort/features/levels/level_repository.dart';
import 'package:flow_sort/game/board_layout.dart';
import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  late LevelRepository repo;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('flow_sort_levels');
    repo = LevelRepository(bundle: rootBundle, cacheDir: () async => cache);
  });
  tearDown(() => cache.deleteSync(recursive: true));

  test('bundled campaign has 230+ levels in order', () async {
    final c = await repo.loadCampaign();
    expect(c.length, greaterThanOrEqualTo(230));
    expect(c.byNumber(1)!.id, 'L001');
    expect(c.numberOf('L031'), 31);
    expect(c.packOf('L001'), 'core_001');
    expect(c.packOf('L031'), 'core_002');
    expect(c.byNumber(0), isNull);
    expect(c.byNumber(c.length + 1), isNull);
    expect(c.byId('nope'), isNull);
    expect(c.nextUnfinished((_) => false), 1);
    expect(c.nextUnfinished((id) => id == 'L001' || id == 'L002'), 3);
    expect(c.nextUnfinished((_) => true), c.length + 1);
  });

  test(
    'a cached pack with a higher version replaces the bundled one',
    () async {
      final bundled = decodeLevelPack(
        await rootBundle.loadString('assets/levels/core_001.json'),
      );
      final newer = LevelPack(
        packId: 'core_001',
        version: bundled.version + 1,
        levels: bundled.levels.take(5).toList(),
      );
      final extra = LevelPack(
        packId: 'core_003',
        version: 1,
        levels: [bundled.levels.first.copyWith(id: 'X001')],
      );
      final dir = Directory('${cache.path}/packs')..createSync();
      File(
        '${dir.path}/core_001.json',
      ).writeAsStringSync(encodeLevelPack(newer));
      File(
        '${dir.path}/core_003.json',
      ).writeAsStringSync(encodeLevelPack(extra));
      File('${dir.path}/broken.json').writeAsStringSync('{oops');

      final c = await repo.loadCampaign();
      expect(c.byNumber(6)!.id, 'L031', reason: 'core_001 now has 5 levels');
      expect(c.levels.last.id, 'X001', reason: 'new pack is appended');
      expect(File('${dir.path}/broken.json').existsSync(), isFalse);
    },
  );

  test('sync ignores empty, unsafe and already-current manifests', () async {
    expect(await repo.syncPacks(const []), 0);
    expect(
      await repo.syncPacks(const [
        PackManifestEntry(id: 'core_001', version: 1, url: 'https://x/a.json'),
        PackManifestEntry(id: '../evil', version: 9, url: 'https://x/a.json'),
      ]),
      0,
    );
  });

  test(
    'every campaign level lays out inside small and large screens',
    () async {
      final c = await repo.loadCampaign();
      for (final size in const [
        Size(320, 440),
        Size(390, 620),
        Size(560, 900),
      ]) {
        for (final level in c.levels) {
          final l = BoardLayout(level, size);
          final bounds = Offset.zero & size;
          for (final e in l.nodes.entries) {
            expect(
              bounds.inflate(1).contains(e.value),
              isTrue,
              reason: '${level.id} ${e.key} at ${e.value} in $size',
            );
          }
          // Bins never overlap and stay on screen.
          final rects = [for (final b in level.bins) l.binRect(b.id)];
          for (var i = 0; i < rects.length; i++) {
            expect(rects[i].bottom, lessThanOrEqualTo(size.height));
            expect(rects[i].left, greaterThanOrEqualTo(0));
            expect(rects[i].right, lessThanOrEqualTo(size.width));
            for (var j = i + 1; j < rects.length; j++) {
              expect(rects[i].overlaps(rects[j]), isFalse, reason: level.id);
            }
          }
          // Switches sit above the bins, are tappable and do not overlap.
          final switches = [for (final s in level.switches) l.nodes[s.id]!];
          for (var i = 0; i < switches.length; i++) {
            expect(switches[i].dy, lessThan(rects.first.top), reason: level.id);
            for (var j = i + 1; j < switches.length; j++) {
              expect(
                (switches[i] - switches[j]).distance,
                greaterThanOrEqualTo(l.switchRadius * 2),
                reason: '${level.id} switches $i/$j in $size',
              );
            }
          }
          expect(l.tapDiameter, greaterThanOrEqualTo(l.switchRadius * 2));
          final path =
              route(level, level.initialSwitches, level.belt.first).path;
          expect(l.pathPoints(path), hasLength(path.length + 1));
        }
      }
    },
  );
}
