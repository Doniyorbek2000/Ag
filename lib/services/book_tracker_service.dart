import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class BookTrackerService {
  static const _uuid = Uuid();
  static const boxName = 'books';

  static final BookTrackerService _instance = BookTrackerService._internal();
  factory BookTrackerService() => _instance;
  BookTrackerService._internal();

  Box get _box => Hive.box(boxName);

  /// Yangi kitob qo'shish
  Future<ActionResult> addBook({
    required String title,
    String? author,
    int? totalPages,
  }) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Kitob nomini kiriting',
      );
    }
    try {
      // Tekshirish: bu nomdagi kitob allaqachon bormi
      final existing = _findBook(title);
      if (existing != null) {
        return ActionResult(
          success: false,
          message: '\'$title\' nomli kitob allaqachon mavjud',
        );
      }

      final id = _uuid.v4();
      final book = {
        'id': id,
        'title': title,
        'author': author ?? '',
        'totalPages': totalPages ?? 0,
        'currentPage': 0,
        'status': 'reading',
        'rating': 0,
        'created_at': DateTime.now().toIso8601String(),
        'finished_at': '',
      };
      await _box.put(id, book);
      final authorText = (author?.isNotEmpty ?? false) ? ' ($author)' : '';
      return ActionResult(
        success: true,
        message: '\u{1F4D6} Kitob qo\'shildi: $title$authorText — holati: o\'qilmoqda',
        data: book,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kitob qo\'shishda xato: $e');
    }
  }

  /// Kitob o'qish jarayonini yangilash
  Future<ActionResult> updateProgress({
    required String title,
    required int currentPage,
  }) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Kitob nomini kiriting',
      );
    }
    try {
      final entry = _findBook(title);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$title\' nomli kitob topilmadi',
        );
      }

      final key = entry.key;
      final book = Map<String, dynamic>.from(entry.value as Map);
      book['currentPage'] = currentPage;

      final totalPages = (book['totalPages'] as int?) ?? 0;
      String percentText = '';
      if (totalPages > 0) {
        final percent = (currentPage / totalPages * 100).round();
        percentText = ' ($percent%)';
      }

      await _box.put(key, book);
      return ActionResult(
        success: true,
        message: '\u{1F4D6} \'${book['title']}\' — $currentPage-sahifa$percentText',
        data: book,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Jarayonni yangilashda xato: $e');
    }
  }

  /// Kitobni tugatilgan deb belgilash
  Future<ActionResult> finishBook(String title) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Kitob nomini kiriting',
      );
    }
    try {
      final entry = _findBook(title);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$title\' nomli kitob topilmadi',
        );
      }

      final key = entry.key;
      final book = Map<String, dynamic>.from(entry.value as Map);
      book['status'] = 'finished';
      book['finished_at'] = DateTime.now().toIso8601String();

      final totalPages = (book['totalPages'] as int?) ?? 0;
      if (totalPages > 0) {
        book['currentPage'] = totalPages;
      }

      await _box.put(key, book);
      return ActionResult(
        success: true,
        message: '\u{2705} \'${book['title']}\' tugatildi! Tabriklaymiz!',
        data: book,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kitobni tugatishda xato: $e');
    }
  }

  /// Kitoblar ro'yxatini ko'rish
  Future<ActionResult> getBooks({String? status}) async {
    try {
      var books = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (status != null && status.isNotEmpty) {
        books = books.where((b) => b['status'] == status).toList();
      }

      if (books.isEmpty) {
        final statusText = status != null ? ' ($status)' : '';
        return ActionResult(
          success: true,
          message: 'Kitoblar ro\'yxati bo\'sh$statusText',
        );
      }

      books.sort((a, b) => (b['created_at']?.toString() ?? '')
          .compareTo(a['created_at']?.toString() ?? ''));

      final lines = books.map((b) {
        final statusIcon = _statusIcon(b['status']?.toString() ?? '');
        final author = (b['author']?.toString() ?? '').isNotEmpty
            ? ' — ${b['author']}'
            : '';
        final totalPages = (b['totalPages'] as int?) ?? 0;
        final currentPage = (b['currentPage'] as int?) ?? 0;
        final progress = totalPages > 0
            ? ' [$currentPage/$totalPages sahifa]'
            : '';
        final rating = (b['rating'] as int?) ?? 0;
        final stars = rating > 0 ? ' ${'⭐' * rating}' : '';
        return '$statusIcon ${b['title']}$author$progress$stars';
      }).join('\n');

      final statusLabel = status != null ? ' ($status)' : '';
      return ActionResult(
        success: true,
        message: '\u{1F4DA} Kitoblar (${books.length} ta)$statusLabel:\n$lines',
        data: books,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kitoblarni o\'qishda xato: $e');
    }
  }

  /// Kitobni istaklar ro'yxatiga qo'shish
  Future<ActionResult> addToWishlist({
    required String title,
    String? author,
  }) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Kitob nomini kiriting',
      );
    }
    try {
      final existing = _findBook(title);
      if (existing != null) {
        return ActionResult(
          success: false,
          message: '\'$title\' nomli kitob allaqachon mavjud',
        );
      }

      final id = _uuid.v4();
      final book = {
        'id': id,
        'title': title,
        'author': author ?? '',
        'totalPages': 0,
        'currentPage': 0,
        'status': 'wishlist',
        'rating': 0,
        'created_at': DateTime.now().toIso8601String(),
        'finished_at': '',
      };
      await _box.put(id, book);
      final authorText = (author?.isNotEmpty ?? false) ? ' ($author)' : '';
      return ActionResult(
        success: true,
        message: '\u{1F4DD} Istaklar ro\'yxatiga qo\'shildi: $title$authorText',
        data: book,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Istaklar ro\'yxatiga qo\'shishda xato: $e');
    }
  }

  /// Kitobni o'chirish
  Future<ActionResult> deleteBook(String title) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'O\'chirish uchun kitob nomini kiriting',
      );
    }
    try {
      final entry = _findBook(title);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$title\' nomli kitob topilmadi',
        );
      }

      final bookTitle = (entry.value as Map)['title'] ?? title;
      await _box.delete(entry.key);
      return ActionResult(
        success: true,
        message: '\u{1F5D1}\u{FE0F} \'$bookTitle\' kitob o\'chirildi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kitobni o\'chirishda xato: $e');
    }
  }

  /// O'qish statistikasi
  Future<ActionResult> getReadingStats() async {
    try {
      final books = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (books.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Hozircha kitoblar yo\'q. Birinchi kitobingizni qo\'shing!',
        );
      }

      final totalBooks = books.length;
      final reading = books.where((b) => b['status'] == 'reading').length;
      final finished = books.where((b) => b['status'] == 'finished').length;
      final wishlist = books.where((b) => b['status'] == 'wishlist').length;

      final totalPagesRead = books.fold<int>(
          0, (sum, b) => sum + ((b['currentPage'] as int?) ?? 0));

      final ratedBooks = books.where((b) => ((b['rating'] as int?) ?? 0) > 0);
      final averageRating = ratedBooks.isNotEmpty
          ? (ratedBooks.fold<int>(0, (sum, b) => sum + ((b['rating'] as int?) ?? 0)) /
                  ratedBooks.length)
              .toStringAsFixed(1)
          : 'baholanmagan';

      return ActionResult(
        success: true,
        message: '\u{1F4CA} O\'qish statistikasi:\n'
            '\u{2022} Jami kitoblar: $totalBooks ta\n'
            '\u{2022} O\'qilmoqda: $reading ta\n'
            '\u{2022} Tugatilgan: $finished ta\n'
            '\u{2022} Istaklar: $wishlist ta\n'
            '\u{2022} Jami o\'qilgan sahifalar: $totalPagesRead\n'
            '\u{2022} O\'rtacha baho: $averageRating',
        data: {
          'totalBooks': totalBooks,
          'reading': reading,
          'finished': finished,
          'wishlist': wishlist,
          'totalPagesRead': totalPagesRead,
          'averageRating': averageRating,
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Statistikani olishda xato: $e');
    }
  }

  /// Kitobga baho berish (1-5 yulduz)
  Future<ActionResult> rateBook({
    required String title,
    required int rating,
  }) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Kitob nomini kiriting',
      );
    }
    if (rating < 1 || rating > 5) {
      return const ActionResult(
        success: false,
        message: 'Baho 1 dan 5 gacha bo\'lishi kerak',
      );
    }
    try {
      final entry = _findBook(title);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$title\' nomli kitob topilmadi',
        );
      }

      final key = entry.key;
      final book = Map<String, dynamic>.from(entry.value as Map);
      book['rating'] = rating;
      await _box.put(key, book);

      final stars = '\u{2B50}' * rating;
      return ActionResult(
        success: true,
        message: '$stars \'${book['title']}\' — $rating yulduz baho berildi',
        data: book,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Baho berishda xato: $e');
    }
  }

  // -- Yordamchi metodlar ---------------------------------------------------

  /// Kitob nomini qidirish (case-insensitive)
  MapEntry<dynamic, dynamic>? _findBook(String title) {
    final lower = title.toLowerCase();
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        final bookTitle = value['title']?.toString().toLowerCase() ?? '';
        if (bookTitle == lower || bookTitle.contains(lower)) {
          return MapEntry(key, value);
        }
      }
    }
    return null;
  }

  /// Holat belgisi
  String _statusIcon(String status) {
    switch (status) {
      case 'reading':
        return '\u{1F4D6}';
      case 'finished':
        return '\u{2705}';
      case 'wishlist':
        return '\u{1F4DD}';
      default:
        return '\u{1F4D3}';
    }
  }
}
