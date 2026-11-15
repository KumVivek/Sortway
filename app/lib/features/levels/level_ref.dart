import 'package:flow_core/flow_core.dart';

enum LevelKind { campaign, daily, event }

/// Points at a playable level. Encoded as a string in routes and in the
/// saved in-progress snapshot: `campaign:L012`, `daily:20261114`,
/// `event:<eventId>:<n>`.
class LevelRef {
  const LevelRef.campaign(this.id) : kind = LevelKind.campaign, index = 0;
  const LevelRef.daily(int day)
    : kind = LevelKind.daily,
      id = '$day',
      index = 0;
  const LevelRef.event(this.id, this.index) : kind = LevelKind.event;

  final LevelKind kind;

  /// Campaign level id, daily `yyyymmdd`, or event id.
  final String id;

  /// 1-based level number inside an event.
  final int index;

  static LevelRef? tryParse(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    switch (parts) {
      case ['campaign', final id] when id.isNotEmpty:
        return LevelRef.campaign(id);
      case ['daily', final day] when int.tryParse(day) != null:
        return LevelRef.daily(int.parse(day));
      case ['event', final id, final n]
          when id.isNotEmpty && int.tryParse(n) != null:
        return LevelRef.event(id, int.parse(n));
    }
    return null;
  }

  String encode() => switch (kind) {
    LevelKind.campaign => 'campaign:$id',
    LevelKind.daily => 'daily:$id',
    LevelKind.event => 'event:$id:$index',
  };

  @override
  String toString() => encode();
}

/// A level ready to play, with what the UI needs to know around it.
class ResolvedLevel {
  const ResolvedLevel({
    required this.ref,
    required this.level,
    required this.number,
    required this.pack,
    this.nextRef,
  });

  final LevelRef ref;
  final LevelDef level;

  /// Campaign number or event index; 0 for the daily challenge.
  final int number;
  final String pack;

  /// Where "Next" goes after a win, if anywhere.
  final LevelRef? nextRef;

  /// Key used in progress storage and analytics.
  String get progressId => level.id;
}
