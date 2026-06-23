import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class WorkoutPlanService {
  static const _uuid = Uuid();

  static final WorkoutPlanService _instance = WorkoutPlanService._internal();
  factory WorkoutPlanService() => _instance;
  WorkoutPlanService._internal();

  Box get _healthBox => Hive.box('health_log');

  /// Tayyor mashq rejalar ro'yxati
  static final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Boshlovchi uy mashqi',
      'description': 'Uy sharoitida boshlang\'ich daraja mashqlari',
      'difficulty': 'oson',
      'durationMinutes': 20,
      'exercises': [
        {'name': 'Otjimaniya', 'reps': '10 marta', 'description': 'Klassik otjimaniya'},
        {'name': 'O\'tirish-turish', 'reps': '15 marta', 'description': 'Oyoq mashqi'},
        {'name': 'Planka', 'reps': '30 soniya', 'description': 'Qorin mushak mashqi'},
        {'name': 'Lanj', 'reps': '10 marta', 'description': 'Har bir oyoq uchun'},
        {'name': 'Sakrash', 'reps': '20 marta', 'description': 'Jumping jacks mashqi'},
      ],
    },
    {
      'name': 'Kardio mashq',
      'description': 'Yurak-qon tomir tizimini mustahkamlash uchun kardio mashqlar',
      'difficulty': 'o\'rtacha',
      'durationMinutes': 30,
      'exercises': [
        {'name': 'Sakrash', 'reps': '50 marta', 'description': 'Jumping jacks'},
        {'name': 'Yuqori tizza ko\'tarish', 'reps': '30 soniya', 'description': 'Tez sur\'atda'},
        {'name': 'Burpi', 'reps': '10 marta', 'description': 'To\'liq burpi mashqi'},
        {'name': 'Tog\'chi', 'reps': '20 marta', 'description': 'Mountain climbers'},
        {'name': 'Arqon sakrash', 'reps': '2 daqiqa', 'description': 'Arqon bilan yoki arqonsiz'},
      ],
    },
    {
      'name': 'Kuch mashqi',
      'description': 'Mushak kuchini oshirish uchun og\'ir mashqlar',
      'difficulty': 'qiyin',
      'durationMinutes': 40,
      'exercises': [
        {'name': 'Otjimaniya', 'reps': '20 marta', 'description': 'Keng ushlash bilan'},
        {'name': 'O\'tirish-turish', 'reps': '25 marta', 'description': 'Chuqur o\'tirish'},
        {'name': 'Lanj', 'reps': '15 marta', 'description': 'Har bir oyoq uchun'},
        {'name': 'Planka', 'reps': '60 soniya', 'description': 'To\'g\'ri planka'},
        {'name': 'Dips', 'reps': '15 marta', 'description': 'Stul yordamida'},
        {'name': 'Devor o\'tirish', 'reps': '45 soniya', 'description': 'Devorga suyanib o\'tirish'},
      ],
    },
    {
      'name': 'Ertalabki zaryadka',
      'description': 'Ertalab tanani uyg\'otish uchun yengil cho\'zish mashqlari',
      'difficulty': 'oson',
      'durationMinutes': 15,
      'exercises': [
        {'name': 'Bo\'yin aylanishi', 'reps': '10 marta', 'description': 'Sekin aylantiriladi'},
        {'name': 'Qo\'l aylanishi', 'reps': '10 marta', 'description': 'Katta doira chizib'},
        {'name': 'Oyoq uchiga tegish', 'reps': '10 marta', 'description': 'Engashib oyoq uchiga tegish'},
        {'name': 'Yon engashish', 'reps': '10 marta', 'description': 'Har bir tomonga'},
        {'name': 'Mushuk-sigir cho\'zishi', 'reps': '10 marta', 'description': 'Orqa cho\'zish mashqi'},
      ],
    },
    {
      'name': 'HIIT mashq',
      'description': 'Yuqori intensivlikdagi interval mashq — 30 soniya ish / 10 soniya dam x 8 raund',
      'difficulty': 'qiyin',
      'durationMinutes': 25,
      'exercises': [
        {'name': 'Burpi', 'reps': '30 soniya', 'description': '1-2 raund'},
        {'name': 'Sakrab o\'tirish-turish', 'reps': '30 soniya', 'description': '3-4 raund'},
        {'name': 'Otjimaniya', 'reps': '30 soniya', 'description': '5-6 raund'},
        {'name': 'Tog\'chi', 'reps': '30 soniya', 'description': '7-8 raund'},
      ],
    },
    {
      'name': 'Yoga',
      'description': 'Moslashuvchanlik va xotirjamlikni oshirish uchun yoga mashqlari',
      'difficulty': 'o\'rtacha',
      'durationMinutes': 30,
      'exercises': [
        {'name': 'Quyosh salomi', 'reps': '5 marta', 'description': 'Surya namaskar'},
        {'name': 'Jangchi pozasi', 'reps': '30 soniya', 'description': 'Har bir tomonga'},
        {'name': 'Daraxt pozasi', 'reps': '30 soniya', 'description': 'Har bir oyoqda'},
        {'name': 'Pastga qaragan it', 'reps': '30 soniya', 'description': 'Adho mukha svanasana'},
        {'name': 'Bola pozasi', 'reps': '30 soniya', 'description': 'Dam olish pozasi'},
        {'name': 'Shavasana', 'reps': '3 daqiqa', 'description': 'Yakuniy dam olish'},
      ],
    },
  ];

  /// Mavjud mashq rejalar ro'yxatini ko'rsatish
  Future<ActionResult> getPlans() async {
    try {
      final lines = _plans.map((p) {
        final difficulty = p['difficulty'] ?? '';
        final diffIcon = _difficultyIcon(difficulty);
        final minutes = p['durationMinutes'] ?? 0;
        return '$diffIcon ${p['name']} — $minutes daqiqa ($difficulty)';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F4CB} Mashq rejalari (${_plans.length} ta):\n$lines',
        data: _plans.map((p) => {
              'name': p['name'],
              'difficulty': p['difficulty'],
              'durationMinutes': p['durationMinutes'],
            }).toList(),
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Rejalarni olishda xato: $e');
    }
  }

  /// Bitta mashq rejasini batafsil ko'rsatish
  Future<ActionResult> getPlan(String name) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Reja nomini kiriting',
      );
    }
    try {
      final plan = _findPlan(name);
      if (plan == null) {
        return ActionResult(
          success: false,
          message: '\'$name\' nomli mashq rejasi topilmadi',
        );
      }

      final exercises = (plan['exercises'] as List<Map<String, dynamic>>?) ?? [];
      final exerciseLines = exercises.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final ex = entry.value;
        return '  $i. ${ex['name']} — ${ex['reps']}\n     ${ex['description']}';
      }).join('\n');

      final difficulty = plan['difficulty'] ?? '';
      final diffIcon = _difficultyIcon(difficulty);

      return ActionResult(
        success: true,
        message: '$diffIcon ${plan['name']}\n'
            '\u{1F4DD} ${plan['description']}\n'
            '\u{23F1}\u{FE0F} Davomiyligi: ${plan['durationMinutes']} daqiqa\n'
            '\u{1F4AA} Daraja: $difficulty\n\n'
            'Mashqlar:\n$exerciseLines',
        data: plan,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Rejani olishda xato: $e');
    }
  }

  /// Mashqni boshlash — mashq ro'yxatini qaytaradi
  Future<ActionResult> startWorkout(String planName) async {
    if (planName.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Mashq rejasi nomini kiriting',
      );
    }
    try {
      final plan = _findPlan(planName);
      if (plan == null) {
        return ActionResult(
          success: false,
          message: '\'$planName\' nomli mashq rejasi topilmadi',
        );
      }

      final exercises = (plan['exercises'] as List<Map<String, dynamic>>?) ?? [];
      final exerciseLines = exercises.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final ex = entry.value;
        return '  $i. ${ex['name']} — ${ex['reps']}';
      }).join('\n');

      // Mashq boshlanganini health_log ga yozish
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'exercise',
        'exercise_type': plan['name'],
        'value': plan['durationMinutes'],
        'calories': 0,
        'status': 'started',
        'date': DateTime.now().toIso8601String(),
      };
      await _healthBox.put(id, entry);

      return ActionResult(
        success: true,
        message: '\u{1F3CB}\u{FE0F} \'${plan['name']}\' mashqi boshlandi!\n'
            '\u{23F1}\u{FE0F} Davomiyligi: ${plan['durationMinutes']} daqiqa\n\n'
            'Mashqlar:\n$exerciseLines\n\n'
            'Omad tilaymiz! \u{1F4AA}',
        data: {
          'plan': plan['name'],
          'exercises': exercises,
          'logId': id,
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Mashqni boshlashda xato: $e');
    }
  }

  /// Mashqni yakunlab health_log ga yozish
  Future<ActionResult> logWorkout({
    required String planName,
    required int minutes,
    int? caloriesBurned,
  }) async {
    if (planName.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Mashq rejasi nomini kiriting',
      );
    }
    try {
      final plan = _findPlan(planName);
      final exerciseName = plan != null ? plan['name'] : planName;

      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'exercise',
        'exercise_type': exerciseName,
        'value': minutes,
        'calories': caloriesBurned ?? 0,
        'date': DateTime.now().toIso8601String(),
      };
      await _healthBox.put(id, entry);

      final caloriesText = (caloriesBurned != null && caloriesBurned > 0)
          ? ' \u{1F525} $caloriesBurned kkal yoqildi'
          : '';
      return ActionResult(
        success: true,
        message: '\u{2705} \'$exerciseName\' mashqi yozildi — $minutes daqiqa$caloriesText',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Mashqni yozishda xato: $e');
    }
  }

  // -- Yordamchi metodlar ---------------------------------------------------

  /// Reja nomini qidirish (case-insensitive)
  Map<String, dynamic>? _findPlan(String name) {
    final lower = name.toLowerCase();
    for (final plan in _plans) {
      final planName = (plan['name']?.toString() ?? '').toLowerCase();
      if (planName == lower || planName.contains(lower)) {
        return plan;
      }
    }
    return null;
  }

  /// Qiyinlik darajasi belgisi
  String _difficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'oson':
        return '\u{1F7E2}';
      case 'o\'rtacha':
        return '\u{1F7E1}';
      case 'qiyin':
        return '\u{1F534}';
      default:
        return '\u{26AA}';
    }
  }
}
