/// The seven item colours. Order is stable and used by level packs.
enum ItemColour {
  red,
  blue,
  green,
  yellow,
  purple,
  orange,
  pink;

  static ItemColour parse(String name) {
    for (final c in values) {
      if (c.name == name) return c;
    }
    throw FormatException('Unknown colour "$name"');
  }
}

/// Optional per-item behaviour.
enum ItemModifier {
  /// Colour is hidden while the item is on the belt (presentation only; the
  /// rules treat it like any other item).
  mystery;

  static ItemModifier parse(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    throw FormatException('Unknown item modifier "$name"');
  }
}

class Item {
  const Item(this.colour, {this.modifier});

  factory Item.fromJson(Object? json) {
    if (json is String) return Item(ItemColour.parse(json));
    if (json is Map<String, Object?>) {
      final colour = json['colour'];
      if (colour is! String) {
        throw const FormatException('Item is missing "colour"');
      }
      final modifier = json['modifier'];
      return Item(
        ItemColour.parse(colour),
        modifier: modifier is String ? ItemModifier.parse(modifier) : null,
      );
    }
    throw FormatException('Invalid item: $json');
  }

  final ItemColour colour;
  final ItemModifier? modifier;

  Object toJson() =>
      modifier == null
          ? colour.name
          : <String, Object?>{'colour': colour.name, 'modifier': modifier!.name};

  @override
  bool operator ==(Object other) =>
      other is Item && other.colour == colour && other.modifier == modifier;

  @override
  int get hashCode => Object.hash(colour, modifier);

  @override
  String toString() =>
      modifier == null ? colour.name : '${colour.name}(${modifier!.name})';
}
