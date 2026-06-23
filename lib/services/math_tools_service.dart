import 'dart:math';
import 'action_executor.dart';

class MathToolsService {
  static final _random = Random();

  // Random number between min and max inclusive
  ActionResult randomNumber({int min = 1, int max = 100}) {
    final result = min + _random.nextInt(max - min + 1);
    return ActionResult(success: true, message: 'Tasodifiy son ($min-$max): $result');
  }

  // Roll a die with N sides (default 6)
  ActionResult diceRoll({int sides = 6}) {
    final result = 1 + _random.nextInt(sides);
    return ActionResult(success: true, message: '🎲 Zar tashlandi ($sides tomonli): $result');
  }

  // Flip a coin
  ActionResult coinFlip() {
    final result = _random.nextBool() ? 'Bosh (Heads)' : 'Teskari (Tails)';
    return ActionResult(success: true, message: '🪙 Tanga: $result');
  }

  // Fibonacci nth number
  ActionResult fibonacci(int n) {
    if (n < 0 || n > 1000) return ActionResult(success: false, message: 'N 0 dan 1000 gacha bo\'lishi kerak');
    BigInt a = BigInt.zero, b = BigInt.one;
    for (var i = 0; i < n; i++) { final t = b; b = a + b; a = t; }
    return ActionResult(success: true, message: 'Fibonachchi($n) = $a');
  }

  // Factorial
  ActionResult factorial(int n) {
    if (n < 0 || n > 170) return ActionResult(success: false, message: 'N 0 dan 170 gacha bo\'lishi kerak');
    double result = 1;
    for (var i = 2; i <= n; i++) result *= i;
    final formatted = result == result.roundToDouble() && result < 1e15 ? result.toStringAsFixed(0) : result.toStringAsExponential(4);
    return ActionResult(success: true, message: '$n! = $formatted');
  }

  // Is prime
  ActionResult isPrime(int n) {
    if (n < 2) return ActionResult(success: true, message: '$n tub son emas');
    if (n < 4) return ActionResult(success: true, message: '$n tub son ✓');
    if (n % 2 == 0 || n % 3 == 0) return ActionResult(success: true, message: '$n tub son emas');
    for (var i = 5; i * i <= n; i += 6) {
      if (n % i == 0 || n % (i + 2) == 0) return ActionResult(success: true, message: '$n tub son emas');
    }
    return ActionResult(success: true, message: '$n tub son ✓');
  }

  // Convert between number bases (2, 8, 10, 16)
  ActionResult convertBase({required String value, required int fromBase, required int toBase}) {
    try {
      final decimal = int.parse(value, radix: fromBase);
      final result = decimal.toRadixString(toBase).toUpperCase();
      return ActionResult(success: true, message: '$value (base $fromBase) = $result (base $toBase)');
    } catch (e) {
      return ActionResult(success: false, message: 'Sanoq sistemasi aylantirishda xato');
    }
  }

  // BMI Calculator
  ActionResult calculateBMI({required double weightKg, required double heightCm}) {
    if (weightKg <= 0 || heightCm <= 0) return ActionResult(success: false, message: 'Vazn va bo\'y musbat bo\'lishi kerak');
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    String category;
    if (bmi < 18.5) { category = 'Kam vazn'; }
    else if (bmi < 25) { category = 'Normal vazn ✓'; }
    else if (bmi < 30) { category = 'Ortiqcha vazn'; }
    else { category = 'Semizlik'; }
    return ActionResult(success: true, message: '📊 BMI: ${bmi.toStringAsFixed(1)} — $category\n(${weightKg.toStringAsFixed(1)} kg, ${heightCm.toStringAsFixed(0)} sm)');
  }

  // Daily calorie needs (Mifflin-St Jeor formula)
  ActionResult calculateCalories({required double weightKg, required double heightCm, required int age, required String gender, String activity = 'moderate'}) {
    double bmr;
    if (gender.toLowerCase().startsWith('e') || gender.toLowerCase().startsWith('m')) {
      // erkak / male
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      // ayol / female
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
    final multipliers = {'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55, 'active': 1.725, 'very_active': 1.9};
    final mult = multipliers[activity] ?? 1.55;
    final calories = (bmr * mult).round();
    return ActionResult(success: true, message: '🔥 Kunlik kaloriya ehtiyoji: $calories kkal\n(BMR: ${bmr.round()} × $activity)');
  }

  // Area of shapes
  ActionResult calculateArea({required String shape, required Map<String, double> dimensions}) {
    double area;
    String formula;
    switch (shape.toLowerCase()) {
      case 'circle': case 'doira': case 'aylana':
        final r = dimensions['radius'] ?? dimensions['r'] ?? 0;
        area = pi * r * r;
        formula = 'π × ${r}² ';
        break;
      case 'rectangle': case 'to\'g\'ri to\'rtburchak': case 'togri':
        final l = dimensions['length'] ?? dimensions['l'] ?? 0;
        final w = dimensions['width'] ?? dimensions['w'] ?? 0;
        area = l * w;
        formula = '$l × $w';
        break;
      case 'triangle': case 'uchburchak':
        final b = dimensions['base'] ?? dimensions['b'] ?? 0;
        final h = dimensions['height'] ?? dimensions['h'] ?? 0;
        area = 0.5 * b * h;
        formula = '½ × $b × $h';
        break;
      case 'square': case 'kvadrat':
        final s = dimensions['side'] ?? dimensions['s'] ?? 0;
        area = s * s;
        formula = '${s}²';
        break;
      case 'trapezoid': case 'trapetsiya':
        final a = dimensions['a'] ?? 0;
        final b = dimensions['b'] ?? 0;
        final h = dimensions['height'] ?? dimensions['h'] ?? 0;
        area = 0.5 * (a + b) * h;
        formula = '½ × ($a + $b) × $h';
        break;
      default:
        return ActionResult(success: false, message: 'Noma\'lum shakl: $shape. doira, to\'g\'ri to\'rtburchak, uchburchak, kvadrat, trapetsiya');
    }
    return ActionResult(success: true, message: '📐 $shape yuzasi: ${_fmt(area)} ($formula)');
  }

  // Volume of shapes
  ActionResult calculateVolume({required String shape, required Map<String, double> dimensions}) {
    double volume;
    switch (shape.toLowerCase()) {
      case 'sphere': case 'shar':
        final r = dimensions['radius'] ?? dimensions['r'] ?? 0;
        volume = (4 / 3) * pi * r * r * r;
        break;
      case 'cube': case 'kub':
        final s = dimensions['side'] ?? dimensions['s'] ?? 0;
        volume = s * s * s;
        break;
      case 'cylinder': case 'silindr':
        final r = dimensions['radius'] ?? dimensions['r'] ?? 0;
        final h = dimensions['height'] ?? dimensions['h'] ?? 0;
        volume = pi * r * r * h;
        break;
      case 'cone': case 'konus':
        final r = dimensions['radius'] ?? dimensions['r'] ?? 0;
        final h = dimensions['height'] ?? dimensions['h'] ?? 0;
        volume = (1 / 3) * pi * r * r * h;
        break;
      case 'box': case 'parallelepiped': case 'quti':
        final l = dimensions['length'] ?? dimensions['l'] ?? 0;
        final w = dimensions['width'] ?? dimensions['w'] ?? 0;
        final h = dimensions['height'] ?? dimensions['h'] ?? 0;
        volume = l * w * h;
        break;
      default:
        return ActionResult(success: false, message: 'Noma\'lum shakl: $shape. shar, kub, silindr, konus, quti');
    }
    return ActionResult(success: true, message: '📦 $shape hajmi: ${_fmt(volume)}');
  }

  // GCD
  ActionResult gcd(int a, int b) {
    int gcdVal = _gcd(a.abs(), b.abs());
    return ActionResult(success: true, message: 'EKUB($a, $b) = $gcdVal');
  }

  // LCM
  ActionResult lcm(int a, int b) {
    final g = _gcd(a.abs(), b.abs());
    final l = g == 0 ? 0 : (a.abs() * b.abs()) ~/ g;
    return ActionResult(success: true, message: 'EKUK($a, $b) = $l');
  }

  // Power
  ActionResult power(double base, double exponent) {
    final result = pow(base, exponent);
    return ActionResult(success: true, message: '${_fmt(base)}^${_fmt(exponent)} = ${_fmt(result.toDouble())}');
  }

  // Square root
  ActionResult squareRoot(double value) {
    if (value < 0) return ActionResult(success: false, message: 'Manfiy sondan ildiz chiqarib bo\'lmaydi');
    final result = sqrt(value);
    return ActionResult(success: true, message: '√${_fmt(value)} = ${_fmt(result)}');
  }

  // Percentage: what is X% of Y
  ActionResult percentage({required double value, required double total}) {
    if (total == 0) return ActionResult(success: false, message: 'Nolga bo\'lish mumkin emas');
    final pct = (value / total) * 100;
    return ActionResult(success: true, message: '${_fmt(value)} / ${_fmt(total)} = ${_fmt(pct)}%');
  }

  // What is X% of Y
  ActionResult percentOf({required double percent, required double of}) {
    final result = (percent / 100) * of;
    return ActionResult(success: true, message: '${_fmt(of)} ning ${_fmt(percent)}% = ${_fmt(result)}');
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
  String _fmt(double v) => v == v.roundToDouble() && v.abs() < 1e15 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
