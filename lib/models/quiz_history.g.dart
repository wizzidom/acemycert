// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizHistoryEntryAdapter extends TypeAdapter<QuizHistoryEntry> {
  @override
  final int typeId = 0;

  @override
  QuizHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizHistoryEntry(
      quizId: fields[0] as String,
      userId: fields[1] as String,
      certificationId: fields[2] as String,
      sectionId: fields[3] as String?,
      scorePercentage: fields[4] as double,
      correctAnswers: fields[5] as int,
      totalQuestions: fields[6] as int,
      timeTakenSeconds: fields[7] as int,
      completedAt: fields[8] as DateTime,
      certificationName: fields[9] as String,
      sectionName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuizHistoryEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.quizId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.certificationId)
      ..writeByte(3)
      ..write(obj.sectionId)
      ..writeByte(4)
      ..write(obj.scorePercentage)
      ..writeByte(5)
      ..write(obj.correctAnswers)
      ..writeByte(6)
      ..write(obj.totalQuestions)
      ..writeByte(7)
      ..write(obj.timeTakenSeconds)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.certificationName)
      ..writeByte(10)
      ..write(obj.sectionName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
