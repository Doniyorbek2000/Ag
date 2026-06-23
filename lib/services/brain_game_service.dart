import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'action_executor.dart';

class BrainGameService {
  static const boxName = 'brain_games';
  static final _random = Random();

  static final BrainGameService _instance = BrainGameService._internal();
  factory BrainGameService() => _instance;
  BrainGameService._internal();

  Box get _box => Hive.box(boxName);

  // ── SO'ROVLAR ─────────────────────────────────────────────────────────────

  static const _words = [
    'kitob', 'maktab', 'daryo', 'quyosh', 'yulduz', 'bulut', 'shamol',
    'gulzor', 'bahor', 'qishloq', 'shahar', 'bozor', 'savdo', 'mehmon',
    'dastur', 'kompyuter', 'telefon', 'kutubxona', 'talaba', 'muallim',
    'tabiat', 'hayvon', 'parranda', 'deniz', 'tog\'lar', 'vodiy', 'chaman',
    'hovuz', 'ko\'prik', 'samolyot', 'poyezd', 'avtobos', 'velosiped',
    'bolalar', 'oila', 'do\'stlik', 'mehnat', 'bilim', 'ilm', 'fan',
    'tarix', 'madaniyat', 'musiqa', 'rasm', 'sport', 'futbol', 'shaxmat',
    'ovqat', 'meva', 'sabzavot', 'pishiriq', 'choy', 'non', 'palov',
  ];

  static const _triviaQuestions = [
    {'q': 'O\'zbekiston poytaxti qaysi shahar?', 'a': 'toshkent'},
    {'q': 'Algebra fanining asoschisi kim?', 'a': 'al-xorazmiy'},
    {'q': 'Yer quyoshdan nechanchi sayyora?', 'a': '3'},
    {'q': 'Suvning kimyoviy formulasi nima?', 'a': 'h2o'},
    {'q': 'Qaysi hayvon eng tez yuguradi?', 'a': 'gepard'},
    {'q': 'Quyosh sistemasidagi eng katta sayyora?', 'a': 'yupiter'},
    {'q': 'Inson tanasidagi eng katta organ qaysi?', 'a': 'teri'},
    {'q': 'Dunyodagi eng baland tog\' qaysi?', 'a': 'everest'},
    {'q': 'O\'zbekistonning milliy valyutasi nima?', 'a': 'so\'m'},
    {'q': 'Nechanchi yilda O\'zbekiston mustaqillikka erishdi?', 'a': '1991'},
    {'q': 'Orol dengizi qaysi ikki davlat orasida joylashgan?', 'a': 'o\'zbekiston va qozog\'iston'},
    {'q': 'Samarqand nechanchi asrda qurilgan?', 'a': '7'},
    {'q': 'Inson skeletida nechta suyak bor?', 'a': '206'},
    {'q': 'Eng kichik qit\'a qaysi?', 'a': 'avstraliya'},
    {'q': 'Fotosintez jarayonida o\'simliklar nimani chiqaradi?', 'a': 'kislorod'},
    {'q': 'Dunyodagi eng uzun daryo qaysi?', 'a': 'nil'},
    {'q': 'Ibn Sino qaysi asrda yashagan?', 'a': '10'},
    {'q': 'Oyda tortishish kuchi Yerdagidan necha marta kam?', 'a': '6'},
    {'q': 'Eng ko\'p aholi yashaydigan davlat qaysi?', 'a': 'xitoy'},
    {'q': 'O\'zbekistonning eng katta shahri qaysi?', 'a': 'toshkent'},
    {'q': 'Quyoshning asosiy tarkibi nimadan iborat?', 'a': 'vodorod'},
    {'q': 'Dunyodagi eng chuqur ko\'l qaysi?', 'a': 'baykal'},
  ];

  // ── MATEMATIK O'YIN ────────────────────────────────────────────────────────

  Future<ActionResult> getMathQuiz({String difficulty = 'normal'}) async {
    try {
      String question;
      int answer;
      final diff = difficulty.toLowerCase();

      if (diff == 'easy' || diff == 'oson') {
        // Qo'shish/ayirish 1-50
        final a = _random.nextInt(50) + 1;
        final b = _random.nextInt(50) + 1;
        if (_random.nextBool()) {
          question = '$a + $b = ?';
          answer = a + b;
        } else {
          final big = a > b ? a : b;
          final small = a > b ? b : a;
          question = '$big - $small = ?';
          answer = big - small;
        }
      } else if (diff == 'hard' || diff == 'qiyin') {
        // 2 bosqichli amallar, kvadratlar, foizlar
        final type = _random.nextInt(3);
        if (type == 0) {
          // 2 bosqichli amal
          final a = _random.nextInt(20) + 2;
          final b = _random.nextInt(10) + 1;
          final c = _random.nextInt(20) + 1;
          question = '$a * $b + $c = ?';
          answer = a * b + c;
        } else if (type == 1) {
          // Kvadrat
          final a = _random.nextInt(15) + 2;
          question = '$a ning kvadrati nechaga teng? ($a^2)';
          answer = a * a;
        } else {
          // Foiz
          final base = (_random.nextInt(10) + 1) * 100;
          final percent = [10, 20, 25, 50][_random.nextInt(4)];
          question = '$base ning $percent foizi nechaga teng?';
          answer = (base * percent) ~/ 100;
        }
      } else {
        // Normal: ko'paytirish/bo'lish 1-20, qo'shish/ayirish 1-200
        final type = _random.nextInt(4);
        if (type == 0) {
          final a = _random.nextInt(20) + 1;
          final b = _random.nextInt(20) + 1;
          question = '$a * $b = ?';
          answer = a * b;
        } else if (type == 1) {
          final b = _random.nextInt(12) + 2;
          final result = _random.nextInt(15) + 2;
          final a = b * result;
          question = '$a / $b = ?';
          answer = result;
        } else if (type == 2) {
          final a = _random.nextInt(200) + 1;
          final b = _random.nextInt(200) + 1;
          question = '$a + $b = ?';
          answer = a + b;
        } else {
          final a = _random.nextInt(200) + 1;
          final b = _random.nextInt(200) + 1;
          final big = a > b ? a : b;
          final small = a > b ? b : a;
          question = '$big - $small = ?';
          answer = big - small;
        }
      }

      // Savolni saqlash
      await _box.put('current_question', {
        'type': 'math',
        'question': question,
        'answer': answer.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return ActionResult(
        success: true,
        message: '🧮 Matematik savol ($diff):\n$question',
        data: {'question': question, 'difficulty': diff},
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Matematik savol yaratishda xato: $e');
    }
  }

  Future<ActionResult> checkAnswer({required String answer}) async {
    try {
      final raw = _box.get('current_question');
      if (raw == null || raw is! Map) {
        return const ActionResult(
          success: false,
          message: 'Hozirda faol savol yo\'q. Avval savol oling!',
        );
      }

      final question = Map<String, dynamic>.from(raw);
      final correctAnswer = question['answer']?.toString() ?? '';
      final questionType = question['type']?.toString() ?? '';
      final isCorrect = answer.trim().toLowerCase() == correctAnswer.toLowerCase();

      // Natijani yangilash
      final scoresRaw = _box.get('scores');
      final scores = scoresRaw is Map
          ? Map<String, dynamic>.from(scoresRaw)
          : {'total': 0, 'correct': 0, 'streak': 0, 'best_streak': 0};

      scores['total'] = (scores['total'] as int? ?? 0) + 1;

      if (isCorrect) {
        scores['correct'] = (scores['correct'] as int? ?? 0) + 1;
        scores['streak'] = (scores['streak'] as int? ?? 0) + 1;
        final bestStreak = scores['best_streak'] as int? ?? 0;
        if ((scores['streak'] as int) > bestStreak) {
          scores['best_streak'] = scores['streak'];
        }
      } else {
        scores['streak'] = 0;
      }

      await _box.put('scores', scores);
      await _box.delete('current_question');

      if (isCorrect) {
        return ActionResult(
          success: true,
          message: '✅ To\'g\'ri javob! Streak: ${scores['streak']} 🔥',
          data: {'correct': true, 'streak': scores['streak']},
        );
      } else {
        return ActionResult(
          success: true,
          message: '❌ Noto\'g\'ri! To\'g\'ri javob: $correctAnswer\n'
              'Savol turi: $questionType',
          data: {'correct': false, 'correct_answer': correctAnswer},
        );
      }
    } catch (e) {
      return ActionResult(success: false, message: 'Javobni tekshirishda xato: $e');
    }
  }

  // ── SO'Z O'YINI ───────────────────────────────────────────────────────────

  Future<ActionResult> getWordGame() async {
    try {
      final word = _words[_random.nextInt(_words.length)];
      final chars = word.split('');
      // Aralashtirish
      for (int i = chars.length - 1; i > 0; i--) {
        final j = _random.nextInt(i + 1);
        final temp = chars[i];
        chars[i] = chars[j];
        chars[j] = temp;
      }
      final scrambled = chars.join('');

      // Agar aralashgan so'z asl so'zga teng bo'lsa, qayta aralashtirish
      final displayScrambled = scrambled == word
          ? (chars..shuffle(_random)).join('')
          : scrambled;

      await _box.put('current_question', {
        'type': 'word',
        'question': displayScrambled,
        'answer': word,
        'created_at': DateTime.now().toIso8601String(),
      });

      return ActionResult(
        success: true,
        message: '🔤 So\'z o\'yini:\nAralashgan harflar: $displayScrambled\nBu qanday so\'z?',
        data: {'scrambled': displayScrambled},
      );
    } catch (e) {
      return ActionResult(success: false, message: 'So\'z o\'yinini yaratishda xato: $e');
    }
  }

  Future<ActionResult> checkWordAnswer({required String answer}) async {
    return checkAnswer(answer: answer);
  }

  // ── RAQAM KETMA-KETLIGI ───────────────────────────────────────────────────

  Future<ActionResult> getNumberSequence() async {
    try {
      final type = _random.nextInt(4);
      List<int> sequence;
      int missingValue;
      int missingIndex;

      if (type == 0) {
        // Arifmetik progressiya
        final start = _random.nextInt(10) + 1;
        final step = _random.nextInt(7) + 2;
        sequence = List.generate(6, (i) => start + step * i);
      } else if (type == 1) {
        // Geometrik progressiya
        final start = _random.nextInt(3) + 2;
        final ratio = _random.nextInt(2) + 2;
        sequence = List.generate(5, (i) => start * _pow(ratio, i));
      } else if (type == 2) {
        // Kvadratlar
        final start = _random.nextInt(3) + 1;
        sequence = List.generate(6, (i) => (start + i) * (start + i));
      } else {
        // Fibonachchi tipidagi
        final a = _random.nextInt(3) + 1;
        final b = _random.nextInt(5) + 2;
        sequence = [a, b];
        for (int i = 2; i < 6; i++) {
          sequence.add(sequence[i - 1] + sequence[i - 2]);
        }
      }

      // Tasodifiy indeksni yashirish (birinchi va oxirgisini emas)
      missingIndex = _random.nextInt(sequence.length - 2) + 1;
      missingValue = sequence[missingIndex];

      final display = List.generate(sequence.length, (i) {
        return i == missingIndex ? '?' : sequence[i].toString();
      }).join(', ');

      await _box.put('current_question', {
        'type': 'sequence',
        'question': display,
        'answer': missingValue.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return ActionResult(
        success: true,
        message: '🔢 Raqam ketma-ketligi:\n$display\n"?" o\'rniga qanday raqam keladi?',
        data: {'sequence': display},
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Ketma-ketlik yaratishda xato: $e');
    }
  }

  Future<ActionResult> checkSequenceAnswer({required String answer}) async {
    return checkAnswer(answer: answer);
  }

  // ── BILIMDON SAVOL ─────────────────────────────────────────────────────────

  Future<ActionResult> getTriviaQuestion() async {
    try {
      final trivia = _triviaQuestions[_random.nextInt(_triviaQuestions.length)];

      await _box.put('current_question', {
        'type': 'trivia',
        'question': trivia['q'],
        'answer': trivia['a'],
        'created_at': DateTime.now().toIso8601String(),
      });

      return ActionResult(
        success: true,
        message: '🧠 Bilimdon savol:\n${trivia['q']}',
        data: {'question': trivia['q']},
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Savol yaratishda xato: $e');
    }
  }

  Future<ActionResult> checkTriviaAnswer({required String answer}) async {
    return checkAnswer(answer: answer);
  }

  // ── NATIJALAR ──────────────────────────────────────────────────────────────

  Future<ActionResult> getScores() async {
    try {
      final scoresRaw = _box.get('scores');
      if (scoresRaw == null || scoresRaw is! Map) {
        return const ActionResult(
          success: true,
          message: '📊 Hali o\'yin o\'ynalmagani. Boshlang!',
        );
      }

      final scores = Map<String, dynamic>.from(scoresRaw);
      final total = scores['total'] as int? ?? 0;
      final correct = scores['correct'] as int? ?? 0;
      final streak = scores['streak'] as int? ?? 0;
      final bestStreak = scores['best_streak'] as int? ?? 0;
      final accuracy = total > 0 ? (correct / total * 100).round() : 0;

      return ActionResult(
        success: true,
        message: '📊 O\'yin natijalari:\n'
            '• Jami o\'ynalgan: $total\n'
            '• To\'g\'ri javoblar: $correct\n'
            '• Aniqlik: $accuracy%\n'
            '• Joriy streak: $streak 🔥\n'
            '• Eng yaxshi streak: $bestStreak ⭐',
        data: scores,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Natijalarni o\'qishda xato: $e');
    }
  }

  Future<ActionResult> resetScores() async {
    try {
      await _box.clear();
      return const ActionResult(
        success: true,
        message: '🗑️ Barcha o\'yin ma\'lumotlari tozalandi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Ma\'lumotlarni tozalashda xato: $e');
    }
  }

  // ── YORDAMCHI ──────────────────────────────────────────────────────────────

  static int _pow(int base, int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
