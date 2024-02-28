// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RuleAdapter extends TypeAdapter<Rule> {
  @override
  final int typeId = 1;

  @override
  Rule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rule(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Rule obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScoreAdapter extends TypeAdapter<Score> {
  @override
  final int typeId = 2;

  @override
  Score read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Score(
      fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Score obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScoreRecordAdapter extends TypeAdapter<ScoreRecord> {
  @override
  final int typeId = 3;

  @override
  ScoreRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreRecord(
      (fields[0] as List).cast<Score>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScoreRecord obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj._records);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordsAdapter extends TypeAdapter<Records> {
  @override
  final int typeId = 4;

  @override
  Records read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Records(
      (fields[0] as List).cast<ScoreRecord>(),
    );
  }

  @override
  void write(BinaryWriter writer, Records obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj._records);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TeamAdapter extends TypeAdapter<Team> {
  @override
  final int typeId = 5;

  @override
  Team read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Team(
      fields[0] as String,
      (fields[1] as List).cast<String>(),
      (fields[2] as List).cast<Records>(),
    );
  }

  @override
  void write(BinaryWriter writer, Team obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj._members)
      ..writeByte(2)
      ..write(obj._games);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DataManagerAdapter extends TypeAdapter<DataManager> {
  @override
  final int typeId = 0;

  @override
  DataManager read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DataManager(
      (fields[0] as List).cast<Rule>(),
      (fields[1] as List).cast<Team>(),
    );
  }

  @override
  void write(BinaryWriter writer, DataManager obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj._ruleList)
      ..writeByte(1)
      ..write(obj._teamList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataManagerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 6;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      fields[0] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.scaleFactor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
