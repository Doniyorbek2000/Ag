// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookkeeping_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookkeepingEntryAdapter extends TypeAdapter<BookkeepingEntry> {
  @override
  final int typeId = 2;

  @override
  BookkeepingEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookkeepingEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      type: fields[3] as EntryType,
      category: fields[4] as String,
      date: fields[5] as DateTime,
      note: fields[6] as String?,
      receiptPath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BookkeepingEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.receiptPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookkeepingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntryTypeAdapter extends TypeAdapter<EntryType> {
  @override
  final int typeId = 3;

  @override
  EntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntryType.income;
      case 1:
        return EntryType.expense;
      default:
        return EntryType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, EntryType obj) {
    switch (obj) {
      case EntryType.income:
        writer.writeByte(0);
        break;
      case EntryType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
