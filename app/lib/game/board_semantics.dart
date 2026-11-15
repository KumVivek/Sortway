import 'package:flow_core/flow_core.dart';
import 'package:flutter/material.dart';

import '../ui/widgets.dart';
import 'flow_game.dart';

/// What a screen reader (TalkBack, VoiceOver) finds on the game board, which
/// Flame draws on a canvas with no accessibility information of its own.
///
/// Laid over the board in the same places as the drawn parts, so exploring
/// by touch lands on them: a live summary over the belt (next item, lives,
/// items left), a button per switch that flips it, and each bin's fill.
/// It draws nothing and takes no pointer events, so touch play is unchanged.
class BoardSemantics extends StatelessWidget {
  const BoardSemantics({required this.game, super.key});

  final FlowGame game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = game.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final layout = game.layoutOrNull;
        if (layout == null) return const SizedBox.shrink();
        final s = c.state;
        final level = c.level;

        String colourName(Item item) =>
            l.a11yColour(item.modifier == ItemModifier.mystery ? 'hidden' : item.colour.name);

        final next =
            s.nextItemIndex < level.belt.length
                ? colourName(level.belt[s.nextItemIndex])
                : l.a11yNoItem;
        final boardTop = layout.beltY + layout.tokenRadius * 1.6;

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: boardTop,
              child: Semantics(
                container: true,
                liveRegion: true,
                label: l.a11yBoard(
                  next,
                  s.lives,
                  level.belt.length - s.nextItemIndex,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            for (final (i, sw) in level.switches.indexed)
              if (layout.nodes[sw.id] case final centre?)
                Positioned.fromRect(
                  rect: Rect.fromCircle(
                    center: centre,
                    radius: layout.tapDiameter / 2,
                  ),
                  child: Semantics(
                    container: true,
                    button: true,
                    label: l.a11ySwitch(i + 1, s.switches[sw.id]!.name),
                    onTapHint: l.a11ySwitchHint,
                    onTap: c.isOver ? null : () => c.flip(sw.id),
                    child: const SizedBox.expand(),
                  ),
                ),
            for (final bin in level.bins)
              Positioned.fromRect(
                rect: layout.binRect(bin.id),
                child: Semantics(
                  container: true,
                  label: l.a11yBin(
                    l.a11yColour(bin.colour.name),
                    s.binFill[bin.id] ?? 0,
                    bin.capacity,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}
