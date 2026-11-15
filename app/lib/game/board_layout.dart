import 'dart:math' as math;
import 'dart:ui';

import 'package:flow_core/flow_core.dart';

/// Screen positions for every part of a level, computed from the tree and
/// the available size. Pure geometry: no Flame, easy to test.
class BoardLayout {
  BoardLayout(this.level, this.size) {
    _compute();
  }

  final LevelDef level;
  final Size size;

  /// Centre of each switch and gate; top-centre (entry point) of each bin.
  final Map<String, Offset> nodes = {};

  /// Parent → child pipes.
  final List<(String, String)> edges = [];

  late double tokenRadius;
  late double beltY;
  late double slot;
  late Offset drop;
  late Size binSize;
  late double switchRadius;
  late double tapDiameter;

  Rect binRect(String binId) {
    final top = nodes[binId]!;
    return Rect.fromLTWH(
      top.dx - binSize.width / 2,
      top.dy,
      binSize.width,
      binSize.height,
    );
  }

  /// Polyline an item follows for a delivery path (node ids, root first).
  List<Offset> pathPoints(List<String> path) => [
    drop,
    for (final id in path.take(path.length - 1)) nodes[id]!,
    binRect(path.last).center.translate(0, -binSize.height * 0.12),
  ];

  void _compute() {
    final w = size.width;
    final h = size.height;
    const pad = 8.0;
    final leaves = level.bins.length;

    tokenRadius = (w / 18).clamp(13.0, 22.0);
    slot = tokenRadius * 2.5;
    beltY = tokenRadius + 16;
    drop = Offset(w / 2, beltY);

    final spacing = (w - pad * 2) / leaves;
    final binW = math.min(spacing - 6, 76.0);
    final binH = (binW * 1.05).clamp(46.0, 72.0);
    binSize = Size(binW, binH);
    final binTop = h - binH - 10;
    final rootY = beltY + tokenRadius + math.min(60.0, h * 0.09);

    var maxDepth = 1;
    void depthOf(Node n, int d) {
      switch (n) {
        case SwitchNode():
          depthOf(n.left, d + 1);
          depthOf(n.right, d + 1);
        case GateNode():
          depthOf(n.next, d + 1);
        case BinNode():
          if (d > maxDepth) maxDepth = d;
      }
    }

    depthOf(level.root, 0);
    final lowestInternalY = binTop - math.max(54.0, binH * 0.9);
    final step =
        maxDepth <= 1
            ? 0.0
            : math.min(130.0, (lowestInternalY - rootY) / (maxDepth - 1));

    var leaf = 0;
    (double, double) place(Node n, int depth) {
      switch (n) {
        case BinNode():
          final x = pad + (leaf++ + 0.5) * spacing;
          nodes[n.id] = Offset(x, binTop);
          return (x, x);
        case GateNode():
          final (lo, hi) = place(n.next, depth + 1);
          nodes[n.id] = Offset((lo + hi) / 2, rootY + depth * step);
          edges.add((n.id, n.next.id));
          return (lo, hi);
        case SwitchNode():
          final (lo, _) = place(n.left, depth + 1);
          final (_, hi) = place(n.right, depth + 1);
          nodes[n.id] = Offset((lo + hi) / 2, rootY + depth * step);
          edges
            ..add((n.id, n.left.id))
            ..add((n.id, n.right.id));
          return (lo, hi);
      }
    }

    place(level.root, 0);

    // A gate sits directly above its bin: put it midway down the pipe so it
    // never collides with the switch row.
    for (final g in level.gates) {
      final next = g.next;
      if (next is BinNode) {
        final at = nodes[g.id]!;
        final minY = at.dy;
        final wanted = binTop - math.max(40.0, binH * 0.7);
        nodes[g.id] = Offset(nodes[next.id]!.dx, math.max(minY, wanted));
      }
    }

    switchRadius = (tokenRadius * 1.15).clamp(17.0, 26.0);
    var nearest = double.infinity;
    final ids = [for (final s in level.switches) s.id];
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final d = (nodes[ids[i]]! - nodes[ids[j]]!).distance;
        if (d < nearest) nearest = d;
      }
    }
    tapDiameter = math.max(
      switchRadius * 2,
      math.min(72.0, nearest.isFinite ? nearest * 0.96 : 72.0),
    );
  }
}
