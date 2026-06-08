import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/models/bookkeeping_entry.dart';

void main() {
  group('BookkeepingEntry.signedAmount', () {
    test('is positive for income entries', () {
      final entry = BookkeepingEntry(
        id: '1',
        title: 'Oylik maosh',
        amount: 5000000,
        type: EntryType.income,
        category: 'Ish haqi',
        date: DateTime(2026, 6, 1),
      );

      expect(entry.signedAmount, 5000000);
    });

    test('is negative for expense entries', () {
      final entry = BookkeepingEntry(
        id: '2',
        title: 'Kira haqi',
        amount: 1500000,
        type: EntryType.expense,
        category: 'Uy-joy',
        date: DateTime(2026, 6, 2),
      );

      expect(entry.signedAmount, -1500000);
    });
  });

  group('Bookkeeping categories', () {
    test('expense and income category lists are non-empty and disjoint apart from "Boshqa"', () {
      expect(expenseCategories, isNotEmpty);
      expect(incomeCategories, isNotEmpty);

      final shared = expenseCategories.toSet().intersection(incomeCategories.toSet());
      expect(shared, {'Boshqa'});
    });
  });
}
