import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'action_executor.dart';

class FinanceToolsService {
  // ── LOAN CALCULATOR ──
  // Monthly payment for a loan using standard amortization formula
  ActionResult calculateLoan({
    required double amount,
    required double annualRate,
    required int months,
  }) {
    if (amount <= 0 || annualRate < 0 || months <= 0) {
      return ActionResult(
        success: false,
        message: 'Summa, foiz va muddat musbat bo\'lishi kerak',
      );
    }
    if (annualRate == 0) {
      final monthly = amount / months;
      return ActionResult(
        success: true,
        message: '🏦 Kredit kalkulyator:\n'
            '• Summa: ${_fmt(amount)} so\'m\n'
            '• Muddat: $months oy\n'
            '• Oylik to\'lov: ${_fmt(monthly)} so\'m\n'
            '• Jami: ${_fmt(amount)} so\'m',
      );
    }
    final r = annualRate / 100 / 12;
    final monthly = amount * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
    final total = monthly * months;
    final interest = total - amount;
    return ActionResult(
      success: true,
      message: '🏦 Kredit kalkulyator:\n'
          '• Summa: ${_fmt(amount)} so\'m\n'
          '• Foiz: ${annualRate}% yillik\n'
          '• Muddat: $months oy\n'
          '• Oylik to\'lov: ${_fmt(monthly)} so\'m\n'
          '• Jami to\'lov: ${_fmt(total)} so\'m\n'
          '• Foiz to\'lovi: ${_fmt(interest)} so\'m',
    );
  }

  // ── TIP CALCULATOR ──
  ActionResult calculateTip({
    required double amount,
    double tipPercent = 15,
    int splitCount = 1,
  }) {
    if (amount <= 0) {
      return ActionResult(
        success: false,
        message: 'Summa musbat bo\'lishi kerak',
      );
    }
    final tip = amount * tipPercent / 100;
    final total = amount + tip;
    final perPerson = splitCount > 1 ? total / splitCount : total;
    var msg = '💰 Choy puli kalkulyator:\n'
        '• Hisob: ${_fmt(amount)} so\'m\n'
        '• Choy puli (${tipPercent.toStringAsFixed(0)}%): ${_fmt(tip)} so\'m\n'
        '• Jami: ${_fmt(total)} so\'m';
    if (splitCount > 1) {
      msg += '\n• Har bir kishi ($splitCount): ${_fmt(perPerson)} so\'m';
    }
    return ActionResult(success: true, message: msg);
  }

  // ── DISCOUNT CALCULATOR ──
  ActionResult calculateDiscount({
    required double price,
    required double discount,
  }) {
    if (price <= 0) {
      return ActionResult(
        success: false,
        message: 'Narx musbat bo\'lishi kerak',
      );
    }
    final saving = price * discount / 100;
    final finalPrice = price - saving;
    return ActionResult(
      success: true,
      message: '🏷️ Chegirma:\n'
          '• Asl narx: ${_fmt(price)} so\'m\n'
          '• Chegirma: ${discount.toStringAsFixed(0)}% (${_fmt(saving)} so\'m)\n'
          '• Yakuniy narx: ${_fmt(finalPrice)} so\'m',
    );
  }

  // ── TAX CALCULATOR ──
  ActionResult calculateTax({
    required double amount,
    double taxRate = 12,
  }) {
    final tax = amount * taxRate / 100;
    final total = amount + tax;
    return ActionResult(
      success: true,
      message: '🧾 Soliq:\n'
          '• Summa: ${_fmt(amount)} so\'m\n'
          '• Soliq (${taxRate.toStringAsFixed(0)}%): ${_fmt(tax)} so\'m\n'
          '• Jami: ${_fmt(total)} so\'m',
    );
  }

  // ── COMPOUND INTEREST ──
  ActionResult calculateInterest({
    required double principal,
    required double annualRate,
    required int years,
    int compoundPerYear = 12,
  }) {
    if (principal <= 0 || annualRate < 0 || years <= 0) {
      return ActionResult(
        success: false,
        message: 'Parametrlar musbat bo\'lishi kerak',
      );
    }
    final r = annualRate / 100;
    final amount =
        principal * pow(1 + r / compoundPerYear, compoundPerYear * years);
    final interest = amount - principal;
    return ActionResult(
      success: true,
      message: '📈 Murakkab foiz:\n'
          '• Boshlang\'ich: ${_fmt(principal)} so\'m\n'
          '• Foiz: ${annualRate}% yillik\n'
          '• Muddat: $years yil\n'
          '• Yakuniy: ${_fmt(amount)} so\'m\n'
          '• Foyda: ${_fmt(interest)} so\'m',
    );
  }

  // ── SAVINGS GOAL ──
  ActionResult calculateSavings({
    required double monthlyAmount,
    required double annualRate,
    required int months,
  }) {
    if (monthlyAmount <= 0 || months <= 0) {
      return ActionResult(
        success: false,
        message: 'Parametrlar musbat bo\'lishi kerak',
      );
    }
    final r = annualRate / 100 / 12;
    double total;
    if (r == 0) {
      total = monthlyAmount * months;
    } else {
      total = monthlyAmount * ((pow(1 + r, months) - 1) / r);
    }
    final deposited = monthlyAmount * months;
    final interest = total - deposited;
    return ActionResult(
      success: true,
      message: '💰 Jamg\'arma:\n'
          '• Oylik: ${_fmt(monthlyAmount)} so\'m\n'
          '• Muddat: $months oy\n'
          '• Foiz: ${annualRate}% yillik\n'
          '• Jami sarflangan: ${_fmt(deposited)} so\'m\n'
          '• Foiz foydasi: ${_fmt(interest)} so\'m\n'
          '• Yakuniy summa: ${_fmt(total)} so\'m',
    );
  }

  // ── PROFIT/LOSS CALCULATOR ──
  ActionResult calculateProfit({
    required double cost,
    required double revenue,
  }) {
    final profit = revenue - cost;
    final margin = cost > 0 ? (profit / cost) * 100 : 0.0;
    final emoji = profit >= 0 ? '📈' : '📉';
    final label = profit >= 0 ? 'Foyda' : 'Zarar';
    return ActionResult(
      success: true,
      message: '$emoji $label:\n'
          '• Xarajat: ${_fmt(cost)} so\'m\n'
          '• Daromad: ${_fmt(revenue)} so\'m\n'
          '• $label: ${_fmt(profit.abs())} so\'m (${margin.toStringAsFixed(1)}%)',
    );
  }

  // ── INFLATION CALCULATOR ──
  ActionResult calculateInflation({
    required double amount,
    required double inflationRate,
    required int years,
  }) {
    final futureValue = amount * pow(1 + inflationRate / 100, years);
    final loss = futureValue - amount;
    return ActionResult(
      success: true,
      message: '📊 Inflyatsiya ta\'siri:\n'
          '• Hozirgi: ${_fmt(amount)} so\'m\n'
          '• $years yildan keyin ($inflationRate% inflyatsiya): ${_fmt(futureValue)} so\'m kerak\n'
          '• Qadrsizlanish: ${_fmt(loss)} so\'m',
    );
  }

  // ── CURRENCY CONVERSION (offline — approximate rates) ──
  ActionResult convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) {
    // Approximate rates relative to USD (updated periodically)
    const rates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'RUB': 89.5,
      'UZS': 12750.0,
      'KZT': 450.0,
      'TRY': 32.5,
      'CNY': 7.25,
      'JPY': 155.0,
      'KRW': 1380.0,
      'AED': 3.67,
      'SAR': 3.75,
      'INR': 83.5,
      'BRL': 5.0,
      'KGS': 89.0,
      'TJS': 10.9,
      'TMT': 3.5,
      'AZN': 1.7,
      'GEL': 2.7,
    };
    final fromRate = rates[from.toUpperCase()];
    final toRate = rates[to.toUpperCase()];
    if (fromRate == null) {
      return ActionResult(
        success: false,
        message: '"$from" valyutasi topilmadi',
      );
    }
    if (toRate == null) {
      return ActionResult(
        success: false,
        message: '"$to" valyutasi topilmadi',
      );
    }
    final usdAmount = amount / fromRate;
    final result = usdAmount * toRate;
    return ActionResult(
      success: true,
      message:
          '💱 ${_fmt(amount)} $from = ${_fmt(result)} $to\n(Taxminiy kurs, real vaqtdagi emas)',
    );
  }

  // ── BUDGET ──
  Future<ActionResult> setBudget({
    required double amount,
    String category = 'umumiy',
  }) async {
    final box = Hive.box('budget');
    await box.put(category.toLowerCase(), {
      'amount': amount,
      'category': category,
      'set_at': DateTime.now().toIso8601String(),
    });
    return ActionResult(
      success: true,
      message: '💰 $category uchun oylik byudjet: ${_fmt(amount)} so\'m',
    );
  }

  Future<ActionResult> getBudget() async {
    final box = Hive.box('budget');
    if (box.isEmpty) {
      return const ActionResult(
        success: true,
        message: 'Byudjet belgilanmagan',
      );
    }
    final lines = <String>[];
    for (final key in box.keys) {
      final b = box.get(key);
      if (b is Map) {
        lines.add(
          '• ${b['category']}: ${_fmt((b['amount'] as num).toDouble())} so\'m',
        );
      }
    }
    return ActionResult(
      success: true,
      message: '💰 Byudjetlar:\n${lines.join('\n')}',
    );
  }

  // ── MORTGAGE CALCULATOR (variant of loan with years) ──
  ActionResult calculateMortgage({
    required double price,
    required double downPayment,
    required double annualRate,
    required int years,
  }) {
    final loanAmount = price - downPayment;
    if (loanAmount <= 0) {
      return ActionResult(
        success: true,
        message: 'Boshlang\'ich to\'lov yetarli — kredit kerak emas!',
      );
    }
    return calculateLoan(
      amount: loanAmount,
      annualRate: annualRate,
      months: years * 12,
    );
  }

  // ── SALARY CALCULATOR (gross to net with UZ tax) ──
  ActionResult calculateNetSalary({
    required double grossSalary,
    double taxRate = 12,
    double pensionRate = 1,
  }) {
    final tax = grossSalary * taxRate / 100;
    final pension = grossSalary * pensionRate / 100;
    final net = grossSalary - tax - pension;
    return ActionResult(
      success: true,
      message: '💵 Ish haqi kalkulyator:\n'
          '• Yalpi: ${_fmt(grossSalary)} so\'m\n'
          '• JSHDS (${taxRate.toStringAsFixed(0)}%): ${_fmt(tax)} so\'m\n'
          '• Nafaqa ($pensionRate%): ${_fmt(pension)} so\'m\n'
          '• Qo\'lga tegadigan: ${_fmt(net)} so\'m',
    );
  }

  // ── NUMBER FORMATTER (Uzbek style: 1 000 000) ──
  String _fmt(double v) {
    final isNeg = v < 0;
    final abs = v.abs();
    final intPart = abs.truncate().toString();
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
      buf.write(intPart[i]);
    }
    return '${isNeg ? "-" : ""}$buf';
  }
}
