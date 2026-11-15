import 'package:flow_core/flow_core.dart';

const r = Item(ItemColour.red);
const b = Item(ItemColour.blue);
const g = Item(ItemColour.green);

/// s1 -> left: red bin b1, right: s2 -> left: blue bin b2, right: green b3.
LevelDef threeBin({
  required List<Item> belt,
  int redCap = 4,
  int blueCap = 3,
  int greenCap = 3,
  int? blueUnlockAfter,
  int lives = 3,
  Map<String, SwitchDir> initial = const {},
}) => LevelDef(
  id: 'T',
  seed: 1,
  lives: lives,
  root: SwitchNode(
    's1',
    left: BinNode('b1', colour: ItemColour.red, capacity: redCap),
    right: SwitchNode(
      's2',
      left: BinNode(
        'b2',
        colour: ItemColour.blue,
        capacity: blueCap,
        unlockAfter: blueUnlockAfter,
      ),
      right: BinNode('b3', colour: ItemColour.green, capacity: greenCap),
    ),
  ),
  belt: belt,
  initialSwitches: initial,
);

/// s1 -> left: red bin, right: gate(->red) -> second red bin.
LevelDef gated({required List<Item> belt}) => LevelDef(
  id: 'G',
  seed: 2,
  root: const SwitchNode(
    's1',
    left: BinNode('b1', colour: ItemColour.blue, capacity: 5),
    right: GateNode(
      'g1',
      toColour: ItemColour.red,
      next: BinNode('b2', colour: ItemColour.red, capacity: 5),
    ),
  ),
  belt: belt,
);
