// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveTransactionAdapter extends TypeAdapter<HiveTransaction> {
  @override
  final int typeId = 0;

  @override
  HiveTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    try {
      return HiveTransaction(
        id: fields[0] as String,
        username: fields[1] as String,
        description: fields[2] as String,
        amount: fields[3] as double,
        date: fields[4] as DateTime,
        type: fields[5] as String,
        userId: fields[6] as String,
        mainCategory: fields[8] as String,
        subCategory: fields[9] as String,
        isSynced: fields[7] as bool,
      );
    } catch (e) {
      throw HiveError('Error reading HiveTransaction: $e');
    }
  }

  @override
  void write(BinaryWriter writer, HiveTransaction obj) {
    try {
      writer
        ..writeByte(10)
        ..writeByte(0)
        ..write(obj.id)
        ..writeByte(1)
        ..write(obj.username)
        ..writeByte(2)
        ..write(obj.description)
        ..writeByte(3)
        ..write(obj.amount)
        ..writeByte(4)
        ..write(obj.date)
        ..writeByte(5)
        ..write(obj.type)
        ..writeByte(6)
        ..write(obj.userId)
        ..writeByte(7)
        ..write(obj.isSynced)
        ..writeByte(8)
        ..write(obj.mainCategory)
        ..writeByte(9)
        ..write(obj.subCategory);
    } catch (e) {
      throw HiveError('Error writing HiveTransaction: $e');
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
