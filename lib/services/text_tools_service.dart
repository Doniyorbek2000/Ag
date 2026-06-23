import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class TextToolsService {
  static final _random = Random.secure();

  ActionResult countWords(String text) {
    if (text.isEmpty) return ActionResult(success: false, message: 'Matn bo\'sh');
    final count = text.trim().split(RegExp(r'\s+')).length;
    return ActionResult(success: true, message: '📝 So\'zlar soni: $count');
  }

  ActionResult countCharacters(String text) {
    return ActionResult(success: true, message: '📝 Belgilar soni: ${text.length} (bo\'shliksiz: ${text.replaceAll(' ', '').length})');
  }

  ActionResult toUpperCase(String text) {
    return ActionResult(success: true, message: text.toUpperCase());
  }

  ActionResult toLowerCase(String text) {
    return ActionResult(success: true, message: text.toLowerCase());
  }

  ActionResult reverseText(String text) {
    return ActionResult(success: true, message: '🔄 ${text.split('').reversed.join('')}');
  }

  ActionResult encodeBase64(String text) {
    final encoded = base64Encode(utf8.encode(text));
    return ActionResult(success: true, message: 'Base64: $encoded');
  }

  ActionResult decodeBase64(String text) {
    try {
      final decoded = utf8.decode(base64Decode(text));
      return ActionResult(success: true, message: 'Dekod: $decoded');
    } catch (e) {
      return ActionResult(success: false, message: 'Base64 dekodlashda xato');
    }
  }

  ActionResult generatePassword({int length = 16, bool includeSpecial = true}) {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const special = '!@#\$%^&*_-+=';
    final chars = includeSpecial ? '$letters$digits$special' : '$letters$digits';
    final password = List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
    return ActionResult(success: true, message: '🔐 Parol: $password');
  }

  ActionResult formatNumber(double number) {
    // Format with thousand separators
    final isNeg = number < 0;
    final abs = number.abs();
    final intPart = abs.truncate().toString();
    final decPart = abs != abs.truncate() ? '.${(abs - abs.truncate()).toStringAsFixed(2).substring(2)}' : '';
    final formatted = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) formatted.write(',');
      formatted.write(intPart[i]);
    }
    return ActionResult(success: true, message: '${isNeg ? "-" : ""}$formatted$decPart');
  }

  ActionResult generateUUID() {
    return ActionResult(success: true, message: '🆔 ${const Uuid().v4()}');
  }

  ActionResult capitalizeWords(String text) {
    final result = text.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
    return ActionResult(success: true, message: result);
  }

  ActionResult extractNumbers(String text) {
    final numbers = RegExp(r'-?\d+\.?\d*').allMatches(text).map((m) => m.group(0)!).toList();
    if (numbers.isEmpty) return ActionResult(success: true, message: 'Matndagi raqamlar topilmadi');
    return ActionResult(success: true, message: 'Topilgan raqamlar: ${numbers.join(', ')}');
  }

  ActionResult extractEmails(String text) {
    final emails = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+').allMatches(text).map((m) => m.group(0)!).toList();
    if (emails.isEmpty) return ActionResult(success: true, message: 'Email manzillar topilmadi');
    return ActionResult(success: true, message: 'Topilgan emaillar: ${emails.join(', ')}');
  }

  ActionResult extractPhones(String text) {
    final phones = RegExp(r'\+?\d[\d\s\-]{6,}\d').allMatches(text).map((m) => m.group(0)!).toList();
    if (phones.isEmpty) return ActionResult(success: true, message: 'Telefon raqamlar topilmadi');
    return ActionResult(success: true, message: 'Topilgan raqamlar: ${phones.join(', ')}');
  }

  ActionResult slugify(String text) {
    final slug = text.toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'[\s_]+'), '-').replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return ActionResult(success: true, message: slug);
  }

  ActionResult textToMorse(String text) {
    const morseMap = {'A':'.-','B':'-...','C':'-.-.','D':'-..','E':'.','F':'..-.','G':'--.','H':'....','I':'..','J':'.---','K':'-.-','L':'.-..','M':'--','N':'-.','O':'---','P':'.--.','Q':'--.-','R':'.-.','S':'...','T':'-','U':'..-','V':'...-','W':'.--','X':'-..-','Y':'-.--','Z':'--..','0':'-----','1':'.----','2':'..---','3':'...--','4':'....-','5':'.....','6':'-....','7':'--...','8':'---..','9':'----.',' ':'/','?':'..--..','!':'-.-.--','.':'.-.-.-',',':'--..--'};
    final morse = text.toUpperCase().split('').map((c) => morseMap[c] ?? c).join(' ');
    return ActionResult(success: true, message: '📡 $morse');
  }

  ActionResult morseToText(String morse) {
    const morseMap = {'.-':'A','-...':'B','-.-.':'C','-..':'D','.':'E','..-.':'F','--.':'G','....':'H','..':'I','.---':'J','-.-':'K','.-..':'L','--':'M','-.':'N','---':'O','.--.':'P','--.-':'Q','.-.':'R','...':'S','-':'T','..-':'U','...-':'V','.--':'W','-..-':'X','-.--':'Y','--..':'Z','-----':'0','.----':'1','..---':'2','...--':'3','....-':'4','.....':'5','-....':'6','--...':'7','---..':'8','----.':'9','/':' '};
    final text = morse.split(' ').map((c) => morseMap[c] ?? c).join('');
    return ActionResult(success: true, message: text);
  }

  ActionResult romanToNumber(String roman) {
    const map = {'I':1,'V':5,'X':10,'L':50,'C':100,'D':500,'M':1000};
    final upper = roman.toUpperCase();
    int result = 0;
    for (var i = 0; i < upper.length; i++) {
      final curr = map[upper[i]] ?? 0;
      final next = i + 1 < upper.length ? (map[upper[i + 1]] ?? 0) : 0;
      result += curr < next ? -curr : curr;
    }
    return ActionResult(success: true, message: '$roman = $result');
  }

  ActionResult numberToRoman(int number) {
    if (number < 1 || number > 3999) return ActionResult(success: false, message: 'Son 1 dan 3999 gacha bo\'lishi kerak');
    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = ['M','CM','D','CD','C','XC','L','XL','X','IX','V','IV','I'];
    var remaining = number;
    final result = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      while (remaining >= values[i]) { result.write(symbols[i]); remaining -= values[i]; }
    }
    return ActionResult(success: true, message: '$number = $result');
  }

  ActionResult hashText(String text) {
    // Simple hash using Dart's hashCode (not cryptographic, but useful for demos)
    final hash = text.hashCode.toRadixString(16).padLeft(8, '0');
    return ActionResult(success: true, message: 'Hash: 0x$hash (${text.length} belgi)');
  }

  ActionResult repeatText(String text, int count) {
    if (count < 1 || count > 100) return ActionResult(success: false, message: 'Takrorlash 1 dan 100 gacha');
    return ActionResult(success: true, message: text * count);
  }

  ActionResult removeSpaces(String text) {
    return ActionResult(success: true, message: text.replaceAll(RegExp(r'\s+'), ''));
  }
}
