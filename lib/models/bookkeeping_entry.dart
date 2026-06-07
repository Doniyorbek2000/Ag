import 'package:hive/hive.dart';

part 'bookkeeping_entry.g.dart';

@HiveType(typeId: 2)
class BookkeepingEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final EntryType type;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? note;

  @HiveField(7)
  final String? receiptPath;

  BookkeepingEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.receiptPath,
  });

  double get signedAmount => type == EntryType.income ? amount : -amount;
}

@HiveType(typeId: 3)
enum EntryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

const List<String> expenseCategories = [
  'Oziq-ovqat',
  'Transport',
  'Uy-joy',
  'Sog\'liq',
  'Ta\'lim',
  'Ko\'ngilochar',
  'Kiyim-kechak',
  'Kommunal',
  'Telefon',
  'Internet',
  'Boshqa',
];

const List<String> incomeCategories = [
  'Ish haqi',
  'Freelance',
  'Biznes',
  'Investitsiya',
  'Sovg\'a',
  'Boshqa',
];
