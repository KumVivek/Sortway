import 'item.dart';

enum SwitchDir {
  left,
  right;

  SwitchDir get flipped => this == left ? right : left;

  static SwitchDir parse(String name) => switch (name) {
    'left' => left,
    'right' => right,
    _ => throw FormatException('Unknown switch direction "$name"'),
  };
}

/// A node of the routing tree. The belt feeds the root.
sealed class Node {
  const Node(this.id);

  factory Node.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw FormatException('Node is missing "id": $json');
    }
    switch (type) {
      case 'switch':
        return SwitchNode(
          id,
          left: Node.fromJson(_child(json, 'left')),
          right: Node.fromJson(_child(json, 'right')),
        );
      case 'gate':
        return GateNode(
          id,
          toColour: ItemColour.parse(_string(json, 'toColour')),
          next: Node.fromJson(_child(json, 'next')),
        );
      case 'bin':
        final capacity = json['capacity'];
        final unlockAfter = json['unlockAfter'];
        if (capacity is! int || capacity < 1) {
          throw FormatException('Bin "$id" needs a capacity >= 1');
        }
        if (unlockAfter != null && (unlockAfter is! int || unlockAfter < 1)) {
          throw FormatException('Bin "$id" has an invalid unlockAfter');
        }
        return BinNode(
          id,
          colour: ItemColour.parse(_string(json, 'colour')),
          capacity: capacity,
          unlockAfter: unlockAfter as int?,
        );
      default:
        throw FormatException('Unknown node type "$type"');
    }
  }

  final String id;

  Map<String, Object?> toJson();

  static Map<String, Object?> _child(Map<String, Object?> json, String key) {
    final v = json[key];
    if (v is Map<String, Object?>) return v;
    throw FormatException('Node "${json['id']}" is missing "$key"');
  }

  static String _string(Map<String, Object?> json, String key) {
    final v = json[key];
    if (v is String) return v;
    throw FormatException('Node "${json['id']}" is missing "$key"');
  }
}

/// A junction. Its direction lives in `GameState.switches`.
final class SwitchNode extends Node {
  const SwitchNode(super.id, {required this.left, required this.right});

  final Node left;
  final Node right;

  Node child(SwitchDir dir) => dir == SwitchDir.left ? left : right;

  @override
  Map<String, Object?> toJson() => {
    'type': 'switch',
    'id': id,
    'left': left.toJson(),
    'right': right.toJson(),
  };
}

/// Recolours every item that passes through it (mechanic M3).
final class GateNode extends Node {
  const GateNode(super.id, {required this.toColour, required this.next});

  final ItemColour toColour;
  final Node next;

  @override
  Map<String, Object?> toJson() => {
    'type': 'gate',
    'id': id,
    'toColour': toColour.name,
    'next': next.toJson(),
  };
}

/// A leaf. Accepts items of [colour] up to [capacity]. When [unlockAfter] is
/// set the bin stays locked until that many items were delivered correctly
/// elsewhere (mechanic M2).
final class BinNode extends Node {
  const BinNode(
    super.id, {
    required this.colour,
    required this.capacity,
    this.unlockAfter,
  });

  final ItemColour colour;
  final int capacity;
  final int? unlockAfter;

  @override
  Map<String, Object?> toJson() => {
    'type': 'bin',
    'id': id,
    'colour': colour.name,
    'capacity': capacity,
    if (unlockAfter != null) 'unlockAfter': unlockAfter,
  };
}

/// Depth-first, left-to-right walk of the tree.
Iterable<Node> walkTree(Node root) sync* {
  yield root;
  switch (root) {
    case SwitchNode(:final left, :final right):
      yield* walkTree(left);
      yield* walkTree(right);
    case GateNode(:final next):
      yield* walkTree(next);
    case BinNode():
      break;
  }
}
