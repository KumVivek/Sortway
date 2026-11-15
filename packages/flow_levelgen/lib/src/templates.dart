/// Shape of the levels generated for one difficulty band (1 = easiest).
class BandTemplate {
  const BandTemplate({
    required this.band,
    required this.minColours,
    required this.maxColours,
    required this.minBins,
    required this.maxBins,
    required this.minBelt,
    required this.maxBelt,
    required this.tickMs,
    required this.reactionBudget,
    required this.gateChance,
    required this.lockChance,
  });

  final int band;
  final int minColours;
  final int maxColours;
  final int minBins;
  final int maxBins;
  final int minBelt;
  final int maxBelt;
  final int tickMs;

  /// Flips per tick the solver grants the player.
  final int reactionBudget;
  final double gateChance;
  final double lockChance;
}

const int minBand = 1;
const int maxBand = 8;

const List<BandTemplate> _templates = [
  BandTemplate(
    band: 1,
    minColours: 2,
    maxColours: 3,
    minBins: 2,
    maxBins: 3,
    minBelt: 8,
    maxBelt: 10,
    tickMs: 1500,
    reactionBudget: 2,
    gateChance: 0.2,
    lockChance: 0.2,
  ),
  BandTemplate(
    band: 2,
    minColours: 3,
    maxColours: 3,
    minBins: 3,
    maxBins: 4,
    minBelt: 10,
    maxBelt: 13,
    tickMs: 1400,
    reactionBudget: 2,
    gateChance: 0.3,
    lockChance: 0.3,
  ),
  BandTemplate(
    band: 3,
    minColours: 3,
    maxColours: 4,
    minBins: 4,
    maxBins: 4,
    minBelt: 12,
    maxBelt: 16,
    tickMs: 1300,
    reactionBudget: 2,
    gateChance: 0.35,
    lockChance: 0.35,
  ),
  BandTemplate(
    band: 4,
    minColours: 4,
    maxColours: 5,
    minBins: 4,
    maxBins: 5,
    minBelt: 14,
    maxBelt: 19,
    tickMs: 1200,
    reactionBudget: 2,
    gateChance: 0.4,
    lockChance: 0.4,
  ),
  BandTemplate(
    band: 5,
    minColours: 4,
    maxColours: 5,
    minBins: 5,
    maxBins: 6,
    minBelt: 17,
    maxBelt: 23,
    tickMs: 1100,
    reactionBudget: 2,
    gateChance: 0.45,
    lockChance: 0.4,
  ),
  BandTemplate(
    band: 6,
    minColours: 5,
    maxColours: 6,
    minBins: 6,
    maxBins: 7,
    minBelt: 21,
    maxBelt: 28,
    tickMs: 1000,
    reactionBudget: 2,
    gateChance: 0.5,
    lockChance: 0.45,
  ),
  BandTemplate(
    band: 7,
    minColours: 6,
    maxColours: 7,
    minBins: 7,
    maxBins: 8,
    minBelt: 25,
    maxBelt: 34,
    tickMs: 900,
    reactionBudget: 2,
    gateChance: 0.5,
    lockChance: 0.45,
  ),
  BandTemplate(
    band: 8,
    minColours: 7,
    maxColours: 7,
    minBins: 8,
    maxBins: 8,
    minBelt: 30,
    maxBelt: 40,
    tickMs: 800,
    reactionBudget: 1,
    gateChance: 0.55,
    lockChance: 0.5,
  ),
];

BandTemplate templateFor(int band) =>
    _templates[band.clamp(minBand, maxBand) - 1];
