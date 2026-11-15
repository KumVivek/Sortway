import 'item.dart';
import 'level.dart';
import 'node.dart';

enum GameStatus { playing, won, lost }

enum DeliveryOutcome {
  correct,
  wrongBin,
  overflow,
  locked;

  bool get isCorrect => this == correct;
}

/// What happened to the item that left the belt on a tick.
class Delivery {
  const Delivery({
    required this.itemIndex,
    required this.item,
    required this.arrivedColour,
    required this.binId,
    required this.outcome,
    required this.path,
  });

  factory Delivery.fromJson(Map<String, Object?> json) => Delivery(
    itemIndex: json['itemIndex']! as int,
    item: Item.fromJson(json['item']),
    arrivedColour: ItemColour.parse(json['arrivedColour']! as String),
    binId: json['binId']! as String,
    outcome: DeliveryOutcome.values.byName(json['outcome']! as String),
    path: (json['path']! as List<Object?>).cast<String>(),
  );

  final int itemIndex;
  final Item item;

  /// Colour after passing any gates.
  final ItemColour arrivedColour;
  final String binId;
  final DeliveryOutcome outcome;

  /// Node ids visited, root first, bin last.
  final List<String> path;

  Map<String, Object?> toJson() => {
    'itemIndex': itemIndex,
    'item': item.toJson(),
    'arrivedColour': arrivedColour.name,
    'binId': binId,
    'outcome': outcome.name,
    'path': path,
  };
}

/// Immutable snapshot of a level in progress. Produced by `step`/`flip`.
class GameState {
  GameState({
    required this.tick,
    required this.lives,
    required this.livesLost,
    required Map<String, SwitchDir> switches,
    required Map<String, int> binFill,
    required this.nextItemIndex,
    required this.delivered,
    required this.status,
    this.slowTicksLeft = 0,
    this.lastDelivery,
  }) : switches = Map.unmodifiable(switches),
       binFill = Map.unmodifiable(binFill);

  factory GameState.initial(LevelDef level) => GameState(
    tick: 0,
    lives: level.lives,
    livesLost: 0,
    switches: level.initialSwitches,
    binFill: {for (final b in level.bins) b.id: 0},
    nextItemIndex: 0,
    delivered: 0,
    status: level.belt.isEmpty ? GameStatus.won : GameStatus.playing,
  );

  factory GameState.fromJson(Map<String, Object?> json) => GameState(
    tick: json['tick']! as int,
    lives: json['lives']! as int,
    livesLost: json['livesLost']! as int,
    switches: {
      for (final e in (json['switches']! as Map<String, Object?>).entries)
        e.key: SwitchDir.parse(e.value! as String),
    },
    binFill: (json['binFill']! as Map<String, Object?>).cast<String, int>(),
    nextItemIndex: json['nextItemIndex']! as int,
    delivered: json['delivered']! as int,
    status: GameStatus.values.byName(json['status']! as String),
    slowTicksLeft: json['slowTicksLeft'] as int? ?? 0,
  );

  final int tick;
  final int lives;

  /// Lives lost so far (net of undo). Drives the star rating.
  final int livesLost;
  final Map<String, SwitchDir> switches;
  final Map<String, int> binFill;
  final int nextItemIndex;

  /// Items delivered to a correct bin.
  final int delivered;
  final GameStatus status;

  /// Remaining ticks of the "slow belt" booster.
  final int slowTicksLeft;

  /// Result of the most recent `step`, if it delivered an item.
  final Delivery? lastDelivery;

  GameState copyWith({
    int? tick,
    int? lives,
    int? livesLost,
    Map<String, SwitchDir>? switches,
    Map<String, int>? binFill,
    int? nextItemIndex,
    int? delivered,
    GameStatus? status,
    int? slowTicksLeft,
    Delivery? lastDelivery,
    bool clearLastDelivery = false,
  }) => GameState(
    tick: tick ?? this.tick,
    lives: lives ?? this.lives,
    livesLost: livesLost ?? this.livesLost,
    switches: switches ?? this.switches,
    binFill: binFill ?? this.binFill,
    nextItemIndex: nextItemIndex ?? this.nextItemIndex,
    delivered: delivered ?? this.delivered,
    status: status ?? this.status,
    slowTicksLeft: slowTicksLeft ?? this.slowTicksLeft,
    lastDelivery: clearLastDelivery ? null : (lastDelivery ?? this.lastDelivery),
  );

  Map<String, Object?> toJson() => {
    'tick': tick,
    'lives': lives,
    'livesLost': livesLost,
    'switches': {for (final e in switches.entries) e.key: e.value.name},
    'binFill': binFill,
    'nextItemIndex': nextItemIndex,
    'delivered': delivered,
    'status': status.name,
    'slowTicksLeft': slowTicksLeft,
  };
}
