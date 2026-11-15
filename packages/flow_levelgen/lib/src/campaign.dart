import 'package:flow_core/flow_core.dart';

import 'generator.dart';
import 'handmade.dart';
import 'templates.dart';

/// Campaign layout constants.
const int handmadeCount = 30;
const int campaignLength = 240;
const int lockedBinFirstLevel = 31;
const int colourGateFirstLevel = 46;
const int levelsPerSet = 12;

/// Difficulty band for campaign level [number] (31 and up): a slow overall
/// rise with a sawtooth — five rising levels then a breather — and a "Hard"
/// level every tenth (plan §7.3).
int campaignBand(int number) {
  if (_tutorialFor(number) != null) {
    return number == lockedBinFirstLevel || number == colourGateFirstLevel
        ? 1
        : 2;
  }
  final progress =
      (number - handmadeCount - 1) / (campaignLength - handmadeCount - 1);
  final base = 2.0 + progress * 5.0;
  const saw = [-0.6, -0.3, 0.0, 0.3, 0.6, -1.3];
  var band = base + saw[(number - handmadeCount - 1) % saw.length];
  if (isHardLevel(number)) band += 1;
  return band.round().clamp(minBand, maxBand);
}

bool isHardLevel(int number) => number % 10 == 0;

/// The first three levels of a new mechanic are its tutorial levels.
String? _tutorialFor(int number) {
  if (number >= lockedBinFirstLevel && number < lockedBinFirstLevel + 3) {
    return Mechanics.lockedBin;
  }
  if (number >= colourGateFirstLevel && number < colourGateFirstLevel + 3) {
    return Mechanics.colourGate;
  }
  return null;
}

/// Generated campaign levels [from]..[to] (inclusive), reproducible from
/// [seed].
List<LevelDef> generateCampaign({
  int from = handmadeCount + 1,
  int to = campaignLength,
  int seed = 2026,
  Set<String>? seen,
}) {
  final hashes = seen ?? <String>{};
  final out = <LevelDef>[];
  for (var n = from; n <= to; n++) {
    final tutorial = _tutorialFor(n);
    final hard = isHardLevel(n) && tutorial == null;
    final breather = (n - handmadeCount - 1) % 6 == 5;
    final picks = generateCandidates(
      GenRequest(
        id: levelId(n),
        seed: seed * 1000 + n,
        band: campaignBand(n),
        allowLocked: n >= lockedBinFirstLevel,
        allowGates: n >= colourGateFirstLevel,
        require: tutorial,
      ),
      candidates: 7,
      seen: hashes,
    );
    if (picks.isEmpty) {
      throw StateError('No valid candidate for level $n');
    }
    final pick =
        hard
            ? picks.last
            : breather || tutorial != null
            ? picks.first
            : picks[picks.length ~/ 2];
    hashes.add(levelHash(pick));
    out.add(
      pick.copyWith(
        meta: pick.meta.copyWith(
          hard: hard,
          tutorial:
              n == lockedBinFirstLevel || n == colourGateFirstLevel
                  ? tutorial
                  : null,
        ),
      ),
    );
  }
  return out;
}

/// The two bundled packs: hand-made tutorial levels and the generated rest.
List<LevelPack> buildCampaignPacks({int seed = 2026, int version = 1}) {
  final handmade = handmadeLevels();
  final seen = {for (final l in handmade) levelHash(l)};
  return [
    LevelPack(packId: 'core_001', version: version, levels: handmade),
    LevelPack(
      packId: 'core_002',
      version: version,
      levels: generateCampaign(seed: seed, seen: seen),
    ),
  ];
}
