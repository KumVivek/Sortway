import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flow_core/flow_core.dart';
import 'package:flow_levelgen/flow_levelgen.dart';
import 'package:flow_solver/flow_solver.dart';

Future<void> main(List<String> args) async {
  final runner =
      CommandRunner<void>(
          'flow_levelgen',
          'Generate, grade and export Flow Sort level packs.',
        )
        ..addCommand(_GenerateCommand())
        ..addCommand(_GradeCommand())
        ..addCommand(_CampaignCommand())
        ..addCommand(_DailyCommand());
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  } on FormatException catch (e) {
    stderr.writeln('Invalid level data: ${e.message}');
    exitCode = 65;
  }
}

void _write(String path, LevelPack pack) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync('${encodeLevelPack(pack)}\n');
  stdout.writeln('Wrote ${pack.levels.length} levels to $path');
}

String _row(LevelDef level, SolveResult r) {
  final m = level.meta;
  return '${level.id.padRight(10)} band ${m.band}  bins ${level.bins.length}  '
      'items ${level.belt.length.toString().padLeft(2)}  '
      'flips ${r.minFlips.toString().padLeft(2)}  gap ${r.minTightestGap}  '
      'traps ${r.trapCount}  peak ${r.peakFlips}  '
      'diff ${difficultyScore(level, r, reactionBudget: m.reactionBudget).toStringAsFixed(2)}  '
      '${r.perfect
          ? 'ok'
          : r.solvable
          ? 'NEEDS A LIFE'
          : 'UNSOLVABLE'}'
      '${m.mechanics.isEmpty ? '' : '  ${m.mechanics.join('+')}'}';
}

class _GenerateCommand extends Command<void> {
  _GenerateCommand() {
    argParser
      ..addOption('band', defaultsTo: '3', help: 'Difficulty band 1-8.')
      ..addOption('count', defaultsTo: '50')
      ..addOption('seed', defaultsTo: '1000')
      ..addOption('pack', help: 'Pack id (defaults to the file name).')
      ..addOption('out', mandatory: true, help: 'Output JSON file.');
  }

  @override
  String get name => 'generate';
  @override
  String get description => 'Generate a pack of levels for one band.';

  @override
  void run() {
    final a = argResults!;
    final out = a['out'] as String;
    final packId =
        a['pack'] as String? ??
        out.split(Platform.pathSeparator).last.replaceAll('.json', '');
    final levels = generateBatch(
      band: int.parse(a['band'] as String),
      count: int.parse(a['count'] as String),
      seed: int.parse(a['seed'] as String),
      idPrefix: '${packId}_',
    );
    _write(out, LevelPack(packId: packId, version: 1, levels: levels));
  }
}

class _GradeCommand extends Command<void> {
  @override
  String get name => 'grade';
  @override
  String get description => 'Solve every level in a pack and print metrics.';
  @override
  String get invocation => 'flow_levelgen grade <pack.json>';

  @override
  void run() {
    final rest = argResults!.rest;
    if (rest.isEmpty) usageException('Give the pack file to grade.');
    var failures = 0;
    for (final path in rest) {
      final pack = decodeLevelPack(File(path).readAsStringSync());
      stdout.writeln('${pack.packId} v${pack.version}');
      var worstMs = 0;
      var worstId = '';
      for (final level in pack.levels) {
        final sw = Stopwatch()..start();
        final r = solve(level, reactionBudget: level.meta.reactionBudget);
        sw.stop();
        if (sw.elapsedMilliseconds > worstMs) {
          worstMs = sw.elapsedMilliseconds;
          worstId = level.id;
        }
        if (!r.perfect) failures++;
        stdout.writeln(_row(level, r));
      }
      stdout.writeln('Slowest solve: $worstMs ms ($worstId)');
    }
    if (failures > 0) {
      stderr.writeln('$failures level(s) have no mistake-free solution.');
      exitCode = 1;
    }
  }
}

class _CampaignCommand extends Command<void> {
  _CampaignCommand() {
    argParser
      ..addOption('seed', defaultsTo: '2026')
      ..addOption('version', defaultsTo: '1')
      ..addOption('out', defaultsTo: 'app/assets/levels');
  }

  @override
  String get name => 'campaign';
  @override
  String get description =>
      'Build the bundled campaign packs (hand-made + generated).';

  @override
  void run() {
    final a = argResults!;
    final packs = buildCampaignPacks(
      seed: int.parse(a['seed'] as String),
      version: int.parse(a['version'] as String),
    );
    for (final pack in packs) {
      _write('${a['out']}/${pack.packId}.json', pack);
    }
  }
}

class _DailyCommand extends Command<void> {
  _DailyCommand() {
    argParser.addOption('date', help: 'yyyy-mm-dd (defaults to today).');
  }

  @override
  String get name => 'daily';
  @override
  String get description => 'Print the daily challenge level for a date.';

  @override
  void run() {
    final raw = argResults!['date'] as String?;
    final date = raw == null ? DateTime.now() : DateTime.parse(raw);
    final level = generateDaily(date);
    stdout.writeln(
      _row(level, solve(level, reactionBudget: level.meta.reactionBudget)),
    );
    stdout.writeln(level.belt.join(' '));
  }
}
