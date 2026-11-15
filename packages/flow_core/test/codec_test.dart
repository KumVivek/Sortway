import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

const planExample = '''
{
  "packId": "core_002",
  "version": 3,
  "levels": [
    {
      "id": "L031",
      "seed": 918273,
      "tickMs": 600,
      "lives": 3,
      "tree": {
        "type": "switch", "id": "s1",
        "left":  { "type": "bin", "id": "b1", "colour": "red",  "capacity": 4 },
        "right": { "type": "switch", "id": "s2",
                   "left":  { "type": "bin", "id": "b2", "colour": "blue", "capacity": 3, "unlockAfter": 4 },
                   "right": { "type": "bin", "id": "b3", "colour": "green", "capacity": 3 } }
      },
      "initialSwitches": { "s1": "left", "s2": "right" },
      "belt": ["red","green","red","blue","green","red","blue","red","green","blue"],
      "meta": { "difficulty": 0.42, "parFlips": 7, "mechanics": ["locked_bin"] }
    }
  ]
}
''';

void main() {
  test('decodes the example from the plan', () {
    final pack = decodeLevelPack(planExample);
    expect(pack.packId, 'core_002');
    expect(pack.version, 3);
    final level = pack.levels.single;
    expect(level.id, 'L031');
    expect(level.seed, 918273);
    expect(level.belt, hasLength(10));
    expect(level.switches.map((s) => s.id), ['s1', 's2']);
    expect(level.bins.map((b) => b.id), ['b1', 'b2', 'b3']);
    expect(level.bins[1].unlockAfter, 4);
    expect(level.initialSwitches['s2'], SwitchDir.right);
    expect(level.meta.parFlips, 7);
    expect(level.meta.mechanics, [Mechanics.lockedBin]);
    expect(level.meta.difficulty, closeTo(0.42, 1e-9));
  });

  test('round trips through JSON', () {
    final pack = decodeLevelPack(planExample);
    final again = decodeLevelPack(encodeLevelPack(pack, pretty: true));
    expect(again.toJson(), pack.toJson());
    expect(decodeLevelPack(encodeLevelPack(pack)).toJson(), pack.toJson());
  });

  test('gates and item modifiers round trip', () {
    final level = LevelDef(
      id: 'X',
      seed: 0,
      root: const GateNode(
        'g',
        toColour: ItemColour.pink,
        next: BinNode('b', colour: ItemColour.pink, capacity: 2),
      ),
      belt: const [
        Item(ItemColour.orange, modifier: ItemModifier.mystery),
        Item(ItemColour.purple),
      ],
      meta: const LevelMeta(hard: true, tutorial: 'gate', band: 4),
    );
    final back = LevelDef.fromJson(level.toJson());
    expect(back.gates.single.toColour, ItemColour.pink);
    expect(back.belt.first.modifier, ItemModifier.mystery);
    expect(back.belt.first, level.belt.first);
    expect(back.belt.first.hashCode, level.belt.first.hashCode);
    expect(back.belt.first.toString(), 'orange(mystery)');
    expect(back.belt.last.toString(), 'purple');
    expect(back.meta.hard, isTrue);
    expect(back.meta.tutorial, 'gate');
    expect(back.meta.band, 4);
    expect(back.copyWith(tickMs: 900).tickMs, 900);
    expect(back.meta.copyWith(parFlips: 3).parFlips, 3);
  });

  group('rejects malformed input', () {
    Map<String, Object?> bin(String id, {Object? capacity = 1}) => {
      'type': 'bin',
      'id': id,
      'colour': 'red',
      'capacity': capacity,
    };
    Map<String, Object?> level(Map<String, Object?> tree) => {
      'id': 'L',
      'tree': tree,
      'belt': ['red'],
    };

    test('pack shape', () {
      expect(() => decodeLevelPack('[]'), throwsFormatException);
      expect(() => decodeLevelPack('{}'), throwsFormatException);
      expect(() => decodeLevelPack('{"packId":"p"}'), throwsFormatException);
    });

    test('level shape', () {
      expect(() => LevelDef.fromJson({}), throwsFormatException);
      expect(() => LevelDef.fromJson({'id': 'L'}), throwsFormatException);
      expect(
        () => LevelDef.fromJson({'id': 'L', 'tree': bin('b')}),
        throwsFormatException,
      );
    });

    test('nodes', () {
      expect(
        () => LevelDef.fromJson(level({'type': 'bin'})),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson(level({'type': 'pipe', 'id': 'x'})),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson(level(bin('b', capacity: 0))),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson(level({...bin('b'), 'unlockAfter': 0})),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson(level({...bin('b'), 'colour': 'teal'})),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson(
          level({'type': 'switch', 'id': 's', 'left': bin('b')}),
        ),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson(level({'type': 'gate', 'id': 'g'})),
        throwsFormatException,
      );
    });

    test('duplicate ids, unknown switches, bad numbers', () {
      expect(
        () => LevelDef.fromJson(
          level({
            'type': 'switch',
            'id': 's',
            'left': bin('b'),
            'right': bin('b'),
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson({
          ...level(bin('b')),
          'initialSwitches': {'zz': 'left'},
        }),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson({...level(bin('b')), 'lives': 0}),
        throwsFormatException,
      );
      expect(
        () => LevelDef.fromJson({...level(bin('b')), 'tickMs': 0}),
        throwsFormatException,
      );
    });

    test('items and enums', () {
      expect(() => Item.fromJson(3), throwsFormatException);
      expect(() => Item.fromJson(<String, Object?>{}), throwsFormatException);
      expect(() => ItemModifier.parse('x'), throwsFormatException);
      expect(() => SwitchDir.parse('up'), throwsFormatException);
      expect(SwitchDir.left.flipped, SwitchDir.right);
      expect(SwitchDir.right.flipped, SwitchDir.left);
    });
  });
}
