import 'action_executor.dart';

class DateToolsService {
  static const _uzbekDays = [
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba'
  ];
  static const _uzbekMonths = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'Iyun',
    'Iyul',
    'Avgust',
    'Sentabr',
    'Oktabr',
    'Noyabr',
    'Dekabr'
  ];

  // Days remaining until a target date
  ActionResult countdown({required String targetDate, String? eventName}) {
    final target = DateTime.tryParse(targetDate);
    if (target == null) {
      return ActionResult(
          success: false, message: 'Sanani YYYY-MM-DD formatida kiriting');
    }
    final diff = target.difference(DateTime.now()).inDays;
    final name = eventName ?? targetDate;
    if (diff < 0) {
      return ActionResult(
          success: true,
          message: '$name ${diff.abs()} kun oldin bo\'lib o\'tdi');
    }
    if (diff == 0) {
      return ActionResult(success: true, message: '$name bugun! \u{1F389}');
    }
    return ActionResult(
        success: true, message: '\u{23F3} $name gacha $diff kun qoldi');
  }

  // World clock — show time in different time zones
  // Use UTC offsets for major cities
  ActionResult worldClock(String city) {
    final offsets = {
      'toshkent': 5,
      'samarqand': 5,
      'buxoro': 5,
      'nukus': 5,
      'andijon': 5,
      'moskva': 3,
      'moscow': 3,
      'london': 0,
      'new york': -5,
      'nyu york': -5,
      'los angeles': -8,
      'tokyo': 9,
      'dubai': 4,
      'istanbul': 3,
      'stambul': 3,
      'berlin': 1,
      'paris': 1,
      'pekin': 8,
      'beijing': 8,
      'sydney': 10,
      'mumbai': 5,
      'singapore': 8,
      'singapur': 8,
      'seoul': 9,
      'seul': 9,
      'bangkok': 7,
      'cairo': 2,
      'qohira': 2,
      'nairobi': 3,
      'toronto': -5,
      'chicago': -6,
      'denver': -7,
      'hawaii': -10,
      'alaska': -9,
      'riyod': 3,
      'tehron': 3,
      'kabul': 4,
      'dushanbe': 5,
      'bishkek': 6,
      'almati': 6,
      'nursulton': 6,
      'ashxobod': 5,
      'boku': 4,
      'tbilisi': 4,
      'yerevan': 4,
      'minsk': 3,
      'kiyev': 2,
      'varshava': 1,
      'rim': 1,
      'madrid': 1,
      'lissabon': 0,
      'amsterdam': 1,
      'bryussel': 1,
      'vena': 1,
      'praga': 1,
      'budapest': 1,
      'buxarest': 2,
      'sofiya': 2,
      'athena': 2,
      'helsinki': 2,
      'stokgolm': 1,
      'oslo': 1,
      'kopengagen': 1,
      'dublin': 0,
      'lima': -5,
      'san-paulu': -3,
      'buenos-ayres': -3,
      'mexiko': -6,
      'bogota': -5,
      'hong kong': 8,
      'hongkong': 8,
      'taipei': 8,
      'jakarta': 7,
      'manila': 8,
      'kuala lumpur': 8,
      'karachi': 5,
      'dhaka': 6,
      'colombo': 5,
    };
    final key = city.toLowerCase().trim();
    final offset = offsets[key];
    if (offset == null) {
      return ActionResult(
          success: false,
          message:
              '"$city" shahri topilmadi. Masalan: Toshkent, Moskva, London, Tokyo');
    }
    final now = DateTime.now().toUtc().add(Duration(hours: offset));
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final day = _uzbekDays[now.weekday - 1];
    return ActionResult(
        success: true,
        message:
            '\u{1F550} $city: $h:$m, $day, ${now.day}-${_uzbekMonths[now.month - 1]}');
  }

  // Difference between two dates in days
  ActionResult dateDifference({required String date1, required String date2}) {
    final d1 = DateTime.tryParse(date1);
    final d2 = DateTime.tryParse(date2);
    if (d1 == null || d2 == null) {
      return ActionResult(
          success: false, message: 'Sanalarni YYYY-MM-DD formatida kiriting');
    }
    final diff = d2.difference(d1).inDays.abs();
    final years = diff ~/ 365;
    final months = (diff % 365) ~/ 30;
    final days = diff % 30;
    final parts = <String>[];
    if (years > 0) parts.add('$years yil');
    if (months > 0) parts.add('$months oy');
    if (days > 0) parts.add('$days kun');
    return ActionResult(
        success: true,
        message:
            '\u{1F4C5} Farq: ${parts.isEmpty ? "0 kun" : parts.join(", ")} ($diff kun)');
  }

  // Add days to a date
  ActionResult addDays({required String date, required int days}) {
    final d = DateTime.tryParse(date);
    if (d == null) {
      return ActionResult(
          success: false, message: 'Sanani YYYY-MM-DD formatida kiriting');
    }
    final result = d.add(Duration(days: days));
    final day = _uzbekDays[result.weekday - 1];
    return ActionResult(
        success: true,
        message:
            '\u{1F4C5} $date + $days kun = ${result.toIso8601String().substring(0, 10)} ($day)');
  }

  // Zodiac sign from birth date
  ActionResult getZodiac(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) {
      return ActionResult(
          success: false, message: 'Sanani YYYY-MM-DD formatida kiriting');
    }
    final m = d.month;
    final day = d.day;
    String sign, emoji;
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) {
      sign = 'Hamal (Aries)';
      emoji = '\u{2648}';
    } else if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) {
      sign = 'Savr (Taurus)';
      emoji = '\u{2649}';
    } else if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) {
      sign = 'Javzo (Gemini)';
      emoji = '\u{264A}';
    } else if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) {
      sign = 'Saraton (Cancer)';
      emoji = '\u{264B}';
    } else if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) {
      sign = 'Asad (Leo)';
      emoji = '\u{264C}';
    } else if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) {
      sign = 'Sunbula (Virgo)';
      emoji = '\u{264D}';
    } else if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) {
      sign = 'Mezon (Libra)';
      emoji = '\u{264E}';
    } else if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) {
      sign = 'Aqrab (Scorpio)';
      emoji = '\u{264F}';
    } else if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) {
      sign = 'Qavs (Sagittarius)';
      emoji = '\u{2650}';
    } else if ((m == 12 && day >= 22) || (m == 1 && day <= 19)) {
      sign = 'Jaddi (Capricorn)';
      emoji = '\u{2651}';
    } else if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) {
      sign = 'Dalv (Aquarius)';
      emoji = '\u{2652}';
    } else {
      sign = 'Hut (Pisces)';
      emoji = '\u{2653}';
    }
    return ActionResult(success: true, message: '$emoji $sign');
  }

  // Calendar week number
  ActionResult getCalendarWeek() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    final week = ((dayOfYear - now.weekday + 10) / 7).floor();
    return ActionResult(
        success: true,
        message:
            '\u{1F4C5} Hozir ${now.year}-yilning $week-haftasi, yilning ${dayOfYear}-kuni');
  }

  // Calculate age from birth date
  ActionResult calculateAge(String birthDate) {
    final birth = DateTime.tryParse(birthDate);
    if (birth == null) {
      return ActionResult(
          success: false, message: 'Sanani YYYY-MM-DD formatida kiriting');
    }
    final now = DateTime.now();
    var years = now.year - birth.year;
    var months = now.month - birth.month;
    var days = now.day - birth.day;
    if (days < 0) {
      months--;
      days += 30;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    return ActionResult(
        success: true,
        message: '\u{1F382} Yosh: $years yil, $months oy, $days kun');
  }

  // Is leap year
  ActionResult isLeapYear(int year) {
    final leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    return ActionResult(
        success: true,
        message:
            '$year-yil ${leap ? "kabisa yili \u{2713} (366 kun)" : "oddiy yil (365 kun)"}');
  }

  // Days in a month
  ActionResult daysInMonth(int month, {int? year}) {
    final y = year ?? DateTime.now().year;
    final days = DateTime(y, month + 1, 0).day;
    final monthName =
        month >= 1 && month <= 12 ? _uzbekMonths[month - 1] : '$month';
    return ActionResult(success: true, message: '$monthName $y: $days kun');
  }

  // Unix timestamp
  ActionResult getUnixTimestamp() {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ActionResult(
        success: true, message: '\u{23F1}\u{FE0F} Unix timestamp: $ts');
  }

  // Convert unix timestamp to readable date
  ActionResult fromUnixTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final day = _uzbekDays[dt.weekday - 1];
    return ActionResult(
        success: true,
        message:
            '\u{1F4C5} $timestamp = ${dt.toIso8601String().substring(0, 19)} ($day)');
  }

  // Approximate Hijri date (simplified)
  ActionResult getHijriDate() {
    final now = DateTime.now();
    // Julian Day Number
    final a = ((14 - now.month) ~/ 12);
    final y = now.year + 4800 - a;
    final m = now.month + 12 * a - 3;
    final jdn = now.day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
    // Hijri from JDN (Kuwaiti algorithm)
    final l = jdn - 1948440 + 10632;
    final n = ((l - 1) ~/ 10631);
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
        ((l2 ~/ 5670) * ((43 * l2) ~/ 15238));
    final l3 = l2 -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        ((j ~/ 16) * ((15238 * j + 29) ~/ 43)) +
        29;
    final hijriMonth = ((24 * l3) ~/ 709);
    final hijriDay = l3 - ((709 * hijriMonth) ~/ 24);
    final hijriYear = 30 * n + j - 30;
    const hijriMonths = [
      'Muharram',
      'Safar',
      'Rabi ul-Avval',
      'Rabi us-Soniy',
      'Jumad ul-Ula',
      'Jumad us-Soniya',
      'Rajab',
      'Sha\'bon',
      'Ramazon',
      'Shavvol',
      'Zulqa\'da',
      'Zulhijja'
    ];
    final monthName = hijriMonth >= 1 && hijriMonth <= 12
        ? hijriMonths[hijriMonth - 1]
        : '$hijriMonth';
    return ActionResult(
        success: true,
        message: '\u{1F54C} Hijriy sana: $hijriDay $monthName $hijriYear');
  }

  // Approximate prayer times for a city (basic solar calculation)
  ActionResult getPrayerTimes(String city) {
    // Use fixed offsets from Tashkent standard for simplicity
    // Real implementation would use proper astronomical calculation
    final offsets = {
      'toshkent': 0,
      'samarqand': 4,
      'buxoro': 8,
      'nukus': 12,
      'andijon': -4,
      'namangan': -4,
      'farg\'ona': -4,
      'jizzax': 2,
      'qarshi': 6,
      'termiz': 4,
      'navoiy': 6,
      'xorazm': 12,
      'urgench': 12,
      'guliston': 0,
    };
    final key = city.toLowerCase().trim();
    final extraMin = offsets[key];
    if (extraMin == null) {
      return ActionResult(
          success: false,
          message: '"$city" uchun namoz vaqtlari mavjud emas');
    }
    // Approximate times for Tashkent in June (adjusted by ~offset for other cities)
    final month = DateTime.now().month;
    // Seasonal adjustment (rough)
    final seasonal = [20, 15, 5, -5, -15, -20, -18, -10, 0, 10, 18, 22];
    final adj = seasonal[month - 1];
    String _t(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    final fajr = _t(4 + (adj + extraMin) ~/ 60, ((20 + adj + extraMin) % 60).abs());
    final sunrise = _t(5 + (adj + extraMin) ~/ 60, ((40 + adj + extraMin) % 60).abs());
    final dhuhr = _t(12, (25 + extraMin) % 60);
    final asr = _t(
        16 + (-adj ~/ 2 + extraMin) ~/ 60, ((30 - adj ~/ 2 + extraMin) % 60).abs());
    final maghrib = _t(
        19 + (-adj + extraMin) ~/ 60, ((20 - adj + extraMin) % 60).abs());
    final isha = _t(
        20 + (-adj + extraMin) ~/ 60, ((50 - adj + extraMin) % 60).abs());
    return ActionResult(
        success: true,
        message:
            '\u{1F54C} $city namoz vaqtlari (taxminiy):\n\u{1F319} Bomdod: $fajr\n\u{2600}\u{FE0F} Quyosh: $sunrise\n\u{1F550} Peshin: $dhuhr\n\u{1F551} Asr: $asr\n\u{1F305} Shom: $maghrib\n\u{1F319} Xufton: $isha');
  }
}
