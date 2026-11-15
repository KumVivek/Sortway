// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LevelProgressTable extends LevelProgress
    with TableInfo<$LevelProgressTable, LevelProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
    'level_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestFlipsMeta = const VerificationMeta(
    'bestFlips',
  );
  @override
  late final GeneratedColumn<int> bestFlips = GeneratedColumn<int>(
    'best_flips',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    levelId,
    stars,
    bestFlips,
    attempts,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('best_flips')) {
      context.handle(
        _bestFlipsMeta,
        bestFlips.isAcceptableOrUnknown(data['best_flips']!, _bestFlipsMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {levelId};
  @override
  LevelProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelProgressData(
      levelId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}level_id'],
          )!,
      stars:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}stars'],
          )!,
      bestFlips: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_flips'],
      ),
      attempts:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}attempts'],
          )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $LevelProgressTable createAlias(String alias) {
    return $LevelProgressTable(attachedDatabase, alias);
  }
}

class LevelProgressData extends DataClass
    implements Insertable<LevelProgressData> {
  final String levelId;
  final int stars;
  final int? bestFlips;
  final int attempts;
  final DateTime? completedAt;
  const LevelProgressData({
    required this.levelId,
    required this.stars,
    this.bestFlips,
    required this.attempts,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level_id'] = Variable<String>(levelId);
    map['stars'] = Variable<int>(stars);
    if (!nullToAbsent || bestFlips != null) {
      map['best_flips'] = Variable<int>(bestFlips);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  LevelProgressCompanion toCompanion(bool nullToAbsent) {
    return LevelProgressCompanion(
      levelId: Value(levelId),
      stars: Value(stars),
      bestFlips:
          bestFlips == null && nullToAbsent
              ? const Value.absent()
              : Value(bestFlips),
      attempts: Value(attempts),
      completedAt:
          completedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(completedAt),
    );
  }

  factory LevelProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelProgressData(
      levelId: serializer.fromJson<String>(json['levelId']),
      stars: serializer.fromJson<int>(json['stars']),
      bestFlips: serializer.fromJson<int?>(json['bestFlips']),
      attempts: serializer.fromJson<int>(json['attempts']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'levelId': serializer.toJson<String>(levelId),
      'stars': serializer.toJson<int>(stars),
      'bestFlips': serializer.toJson<int?>(bestFlips),
      'attempts': serializer.toJson<int>(attempts),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  LevelProgressData copyWith({
    String? levelId,
    int? stars,
    Value<int?> bestFlips = const Value.absent(),
    int? attempts,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => LevelProgressData(
    levelId: levelId ?? this.levelId,
    stars: stars ?? this.stars,
    bestFlips: bestFlips.present ? bestFlips.value : this.bestFlips,
    attempts: attempts ?? this.attempts,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  LevelProgressData copyWithCompanion(LevelProgressCompanion data) {
    return LevelProgressData(
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      stars: data.stars.present ? data.stars.value : this.stars,
      bestFlips: data.bestFlips.present ? data.bestFlips.value : this.bestFlips,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressData(')
          ..write('levelId: $levelId, ')
          ..write('stars: $stars, ')
          ..write('bestFlips: $bestFlips, ')
          ..write('attempts: $attempts, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(levelId, stars, bestFlips, attempts, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelProgressData &&
          other.levelId == this.levelId &&
          other.stars == this.stars &&
          other.bestFlips == this.bestFlips &&
          other.attempts == this.attempts &&
          other.completedAt == this.completedAt);
}

class LevelProgressCompanion extends UpdateCompanion<LevelProgressData> {
  final Value<String> levelId;
  final Value<int> stars;
  final Value<int?> bestFlips;
  final Value<int> attempts;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const LevelProgressCompanion({
    this.levelId = const Value.absent(),
    this.stars = const Value.absent(),
    this.bestFlips = const Value.absent(),
    this.attempts = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelProgressCompanion.insert({
    required String levelId,
    this.stars = const Value.absent(),
    this.bestFlips = const Value.absent(),
    this.attempts = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : levelId = Value(levelId);
  static Insertable<LevelProgressData> custom({
    Expression<String>? levelId,
    Expression<int>? stars,
    Expression<int>? bestFlips,
    Expression<int>? attempts,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (levelId != null) 'level_id': levelId,
      if (stars != null) 'stars': stars,
      if (bestFlips != null) 'best_flips': bestFlips,
      if (attempts != null) 'attempts': attempts,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelProgressCompanion copyWith({
    Value<String>? levelId,
    Value<int>? stars,
    Value<int?>? bestFlips,
    Value<int>? attempts,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return LevelProgressCompanion(
      levelId: levelId ?? this.levelId,
      stars: stars ?? this.stars,
      bestFlips: bestFlips ?? this.bestFlips,
      attempts: attempts ?? this.attempts,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (bestFlips.present) {
      map['best_flips'] = Variable<int>(bestFlips.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressCompanion(')
          ..write('levelId: $levelId, ')
          ..write('stars: $stars, ')
          ..write('bestFlips: $bestFlips, ')
          ..write('attempts: $attempts, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StickersTable extends Stickers with TableInfo<$StickersTable, Sticker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stickerIndexMeta = const VerificationMeta(
    'stickerIndex',
  );
  @override
  late final GeneratedColumn<int> stickerIndex = GeneratedColumn<int>(
    'sticker_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [setIndex, stickerIndex, earnedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stickers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sticker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('sticker_index')) {
      context.handle(
        _stickerIndexMeta,
        stickerIndex.isAcceptableOrUnknown(
          data['sticker_index']!,
          _stickerIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stickerIndexMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setIndex, stickerIndex};
  @override
  Sticker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sticker(
      setIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}set_index'],
          )!,
      stickerIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sticker_index'],
          )!,
      earnedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}earned_at'],
          )!,
    );
  }

  @override
  $StickersTable createAlias(String alias) {
    return $StickersTable(attachedDatabase, alias);
  }
}

class Sticker extends DataClass implements Insertable<Sticker> {
  final int setIndex;
  final int stickerIndex;
  final DateTime earnedAt;
  const Sticker({
    required this.setIndex,
    required this.stickerIndex,
    required this.earnedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['set_index'] = Variable<int>(setIndex);
    map['sticker_index'] = Variable<int>(stickerIndex);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    return map;
  }

  StickersCompanion toCompanion(bool nullToAbsent) {
    return StickersCompanion(
      setIndex: Value(setIndex),
      stickerIndex: Value(stickerIndex),
      earnedAt: Value(earnedAt),
    );
  }

  factory Sticker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sticker(
      setIndex: serializer.fromJson<int>(json['setIndex']),
      stickerIndex: serializer.fromJson<int>(json['stickerIndex']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setIndex': serializer.toJson<int>(setIndex),
      'stickerIndex': serializer.toJson<int>(stickerIndex),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
    };
  }

  Sticker copyWith({int? setIndex, int? stickerIndex, DateTime? earnedAt}) =>
      Sticker(
        setIndex: setIndex ?? this.setIndex,
        stickerIndex: stickerIndex ?? this.stickerIndex,
        earnedAt: earnedAt ?? this.earnedAt,
      );
  Sticker copyWithCompanion(StickersCompanion data) {
    return Sticker(
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      stickerIndex:
          data.stickerIndex.present
              ? data.stickerIndex.value
              : this.stickerIndex,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sticker(')
          ..write('setIndex: $setIndex, ')
          ..write('stickerIndex: $stickerIndex, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setIndex, stickerIndex, earnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sticker &&
          other.setIndex == this.setIndex &&
          other.stickerIndex == this.stickerIndex &&
          other.earnedAt == this.earnedAt);
}

class StickersCompanion extends UpdateCompanion<Sticker> {
  final Value<int> setIndex;
  final Value<int> stickerIndex;
  final Value<DateTime> earnedAt;
  final Value<int> rowid;
  const StickersCompanion({
    this.setIndex = const Value.absent(),
    this.stickerIndex = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickersCompanion.insert({
    required int setIndex,
    required int stickerIndex,
    required DateTime earnedAt,
    this.rowid = const Value.absent(),
  }) : setIndex = Value(setIndex),
       stickerIndex = Value(stickerIndex),
       earnedAt = Value(earnedAt);
  static Insertable<Sticker> custom({
    Expression<int>? setIndex,
    Expression<int>? stickerIndex,
    Expression<DateTime>? earnedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setIndex != null) 'set_index': setIndex,
      if (stickerIndex != null) 'sticker_index': stickerIndex,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickersCompanion copyWith({
    Value<int>? setIndex,
    Value<int>? stickerIndex,
    Value<DateTime>? earnedAt,
    Value<int>? rowid,
  }) {
    return StickersCompanion(
      setIndex: setIndex ?? this.setIndex,
      stickerIndex: stickerIndex ?? this.stickerIndex,
      earnedAt: earnedAt ?? this.earnedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (stickerIndex.present) {
      map['sticker_index'] = Variable<int>(stickerIndex.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickersCompanion(')
          ..write('setIndex: $setIndex, ')
          ..write('stickerIndex: $stickerIndex, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LevelProgressTable levelProgress = $LevelProgressTable(this);
  late final $StickersTable stickers = $StickersTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    levelProgress,
    stickers,
    keyValues,
  ];
}

typedef $$LevelProgressTableCreateCompanionBuilder =
    LevelProgressCompanion Function({
      required String levelId,
      Value<int> stars,
      Value<int?> bestFlips,
      Value<int> attempts,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$LevelProgressTableUpdateCompanionBuilder =
    LevelProgressCompanion Function({
      Value<String> levelId,
      Value<int> stars,
      Value<int?> bestFlips,
      Value<int> attempts,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$LevelProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestFlips => $composableBuilder(
    column: $table.bestFlips,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestFlips => $composableBuilder(
    column: $table.bestFlips,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<int> get bestFlips =>
      $composableBuilder(column: $table.bestFlips, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$LevelProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LevelProgressTable,
          LevelProgressData,
          $$LevelProgressTableFilterComposer,
          $$LevelProgressTableOrderingComposer,
          $$LevelProgressTableAnnotationComposer,
          $$LevelProgressTableCreateCompanionBuilder,
          $$LevelProgressTableUpdateCompanionBuilder,
          (
            LevelProgressData,
            BaseReferences<
              _$AppDatabase,
              $LevelProgressTable,
              LevelProgressData
            >,
          ),
          LevelProgressData,
          PrefetchHooks Function()
        > {
  $$LevelProgressTableTableManager(_$AppDatabase db, $LevelProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LevelProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$LevelProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LevelProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> levelId = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int?> bestFlips = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion(
                levelId: levelId,
                stars: stars,
                bestFlips: bestFlips,
                attempts: attempts,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String levelId,
                Value<int> stars = const Value.absent(),
                Value<int?> bestFlips = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion.insert(
                levelId: levelId,
                stars: stars,
                bestFlips: bestFlips,
                attempts: attempts,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LevelProgressTable,
      LevelProgressData,
      $$LevelProgressTableFilterComposer,
      $$LevelProgressTableOrderingComposer,
      $$LevelProgressTableAnnotationComposer,
      $$LevelProgressTableCreateCompanionBuilder,
      $$LevelProgressTableUpdateCompanionBuilder,
      (
        LevelProgressData,
        BaseReferences<_$AppDatabase, $LevelProgressTable, LevelProgressData>,
      ),
      LevelProgressData,
      PrefetchHooks Function()
    >;
typedef $$StickersTableCreateCompanionBuilder =
    StickersCompanion Function({
      required int setIndex,
      required int stickerIndex,
      required DateTime earnedAt,
      Value<int> rowid,
    });
typedef $$StickersTableUpdateCompanionBuilder =
    StickersCompanion Function({
      Value<int> setIndex,
      Value<int> stickerIndex,
      Value<DateTime> earnedAt,
      Value<int> rowid,
    });

class $$StickersTableFilterComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stickerIndex => $composableBuilder(
    column: $table.stickerIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StickersTableOrderingComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stickerIndex => $composableBuilder(
    column: $table.stickerIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StickersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get stickerIndex => $composableBuilder(
    column: $table.stickerIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);
}

class $$StickersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StickersTable,
          Sticker,
          $$StickersTableFilterComposer,
          $$StickersTableOrderingComposer,
          $$StickersTableAnnotationComposer,
          $$StickersTableCreateCompanionBuilder,
          $$StickersTableUpdateCompanionBuilder,
          (Sticker, BaseReferences<_$AppDatabase, $StickersTable, Sticker>),
          Sticker,
          PrefetchHooks Function()
        > {
  $$StickersTableTableManager(_$AppDatabase db, $StickersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StickersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$StickersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$StickersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> setIndex = const Value.absent(),
                Value<int> stickerIndex = const Value.absent(),
                Value<DateTime> earnedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickersCompanion(
                setIndex: setIndex,
                stickerIndex: stickerIndex,
                earnedAt: earnedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int setIndex,
                required int stickerIndex,
                required DateTime earnedAt,
                Value<int> rowid = const Value.absent(),
              }) => StickersCompanion.insert(
                setIndex: setIndex,
                stickerIndex: stickerIndex,
                earnedAt: earnedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StickersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StickersTable,
      Sticker,
      $$StickersTableFilterComposer,
      $$StickersTableOrderingComposer,
      $$StickersTableAnnotationComposer,
      $$StickersTableCreateCompanionBuilder,
      $$StickersTableUpdateCompanionBuilder,
      (Sticker, BaseReferences<_$AppDatabase, $StickersTable, Sticker>),
      Sticker,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder =
    KeyValuesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValuesTableUpdateCompanionBuilder =
    KeyValuesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LevelProgressTableTableManager get levelProgress =>
      $$LevelProgressTableTableManager(_db, _db.levelProgress);
  $$StickersTableTableManager get stickers =>
      $$StickersTableTableManager(_db, _db.stickers);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
}
