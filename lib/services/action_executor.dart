import 'package:android_intent_plus/android_intent.dart';
import 'package:collection/collection.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'telegram_service.dart';
import 'whatsapp_service.dart';
import 'weather_service.dart';
import 'news_service.dart';
import 'unit_converter_service.dart';
import 'reminder_service.dart';
import 'todo_service.dart';
import 'health_tracker_service.dart';
import 'math_tools_service.dart';
import 'text_tools_service.dart';
import 'date_tools_service.dart';
import 'fun_content_service.dart';
import 'device_control_service.dart';
import 'location_search_service.dart';
import 'finance_tools_service.dart';
import 'habit_service.dart';
import 'scheduled_service.dart';
import 'daily_briefing_service.dart';
import 'data_export_service.dart';
import 'contact_manager_service.dart';
import 'qr_service.dart';
import 'journal_service.dart';
import 'smart_suggestion_service.dart';
import 'password_vault_service.dart';
import 'book_tracker_service.dart';
import 'workout_plan_service.dart';
import 'brain_game_service.dart';
import 'favorites_service.dart';
import 'usage_stats_service.dart';

class ActionExecutor {
  final Logger _logger = Logger();
  final TodoService _todo = TodoService();
  final HealthTrackerService _health = HealthTrackerService();
  final MathToolsService _math = MathToolsService();
  final TextToolsService _text = TextToolsService();
  final DateToolsService _date = DateToolsService();
  final FunContentService _fun = FunContentService();
  final DeviceControlService _device = DeviceControlService();
  final LocationSearchService _location = LocationSearchService();
  final FinanceToolsService _finance = FinanceToolsService();
  final HabitService _habit = HabitService();
  final ScheduledService _scheduled = ScheduledService();
  final DailyBriefingService _briefing = DailyBriefingService();
  final DataExportService _export = DataExportService();
  final ContactManagerService _contact = ContactManagerService();
  final QrService _qr = QrService();
  final JournalService _journal = JournalService();
  final SmartSuggestionService _suggestions = SmartSuggestionService();
  final PasswordVaultService _vault = PasswordVaultService();
  final BookTrackerService _books = BookTrackerService();
  final WorkoutPlanService _workout = WorkoutPlanService();
  final BrainGameService _brain = BrainGameService();
  final FavoritesService _favorites = FavoritesService();
  final UsageStatsService _usageStats = UsageStatsService();

  static final ActionExecutor _instance = ActionExecutor._internal();
  factory ActionExecutor() => _instance;
  ActionExecutor._internal();

  Future<ActionResult> execute(String actionType, Map<String, dynamic> params) async {
    _logger.d('Executing action: $actionType with params: $params');

    switch (actionType) {
      case 'MAKE_CALL':
        return _makeCall(params['phone'] as String? ?? '');
      case 'SEND_SMS':
        return _sendSms(
          params['phone'] as String? ?? '',
          params['message'] as String? ?? '',
        );
      case 'OPEN_APP':
        return _openApp(params['app'] as String? ?? '');
      case 'PLAY_MUSIC':
        return _playMusic(params['query'] as String? ?? '');
      case 'SEARCH_WEB':
        return _searchWeb(params['query'] as String? ?? '');
      case 'SET_ALARM':
        return _setAlarm(
          params['time'] as String? ?? '',
          params['label'] as String? ?? 'ADM AI Eslatma',
        );
      case 'OPEN_SETTINGS':
        return _openSettings(params['section'] as String? ?? '');
      case 'SEND_TELEGRAM':
        return _sendTelegram(
          params['contact'] as String? ?? '',
          params['message'] as String? ?? '',
        );
      case 'SEND_WHATSAPP':
        return _sendWhatsApp(
          params['phone'] as String? ?? '',
          params['message'] as String? ?? '',
        );
      case 'SEARCH_YOUTUBE':
        return _searchYouTube(params['query'] as String? ?? '');
      case 'OPEN_CAMERA':
        return _openCamera();
      case 'OPEN_GALLERY':
        return _openGallery();
      case 'OPEN_MAPS':
        return _openMaps(params['location'] as String? ?? '');
      case 'GET_WEATHER':
        return _getWeather(params['city'] as String? ?? '');
      case 'GET_NEWS':
        return _getNews(params['topic'] as String?);
      case 'CONVERT_UNITS':
        return _convertUnits(params);
      case 'CREATE_EVENT':
        return _createCalendarEvent(params);
      case 'SEND_EMAIL':
        return _sendEmail(params);
      case 'SET_REMINDER':
        return _setReminder(params);
      case 'FIND_CONTACT':
        return _findContact(params['name'] as String? ?? '');
      case 'SET_TIMER':
        final rawDuration = params['duration'] ?? params['seconds'];
        return _setTimer(
          rawDuration is int ? rawDuration : int.tryParse(rawDuration?.toString() ?? '') ?? 300,
          params['label'] as String? ?? params['message'] as String? ?? 'ADM AI Taymer',
        );
      case 'NAVIGATE_TO':
        return _navigateTo(params['location'] as String? ?? '');
      case 'SHARE_TEXT':
        return _shareText(params['text'] as String? ?? '');
      case 'TRANSLATE_TEXT':
        return _translateText(
          params['text'] as String? ?? '',
          params['from'] as String? ?? 'auto',
          params['to'] as String? ?? 'uz',
        );
      case 'TAKE_NOTE':
        return _takeNote(
          params['title'] as String? ?? '',
          params['content'] as String? ?? '',
        );
      case 'GET_NOTES':
        return _getNotes();
      case 'DELETE_NOTE':
        return _deleteNote(params['title'] as String? ?? '');
      case 'GET_TIME':
        return _getTime();
      case 'CALCULATE':
        return _calculate(params['expression'] as String? ?? '');
      case 'OPEN_URL':
        return _openUrl(params['url'] as String? ?? '');
      case 'TOGGLE_FLASHLIGHT':
        return _toggleFlashlight();
      case 'SHOW_DEVICE_INFO':
        return _showDeviceInfo();

      // ── TODO / SHOPPING / GOALS ──
      case 'CREATE_TODO':
        return _todo.createTodo(
          title: params['title'] as String? ?? '',
          description: params['description'] as String?,
          priority: params['priority'] as String? ?? 'normal',
          dueDate: params['dueDate'] as String?,
        );
      case 'GET_TODOS':
        return _todo.getTodos();
      case 'COMPLETE_TODO':
        return _todo.completeTodo(params['title'] as String? ?? '');
      case 'DELETE_TODO':
        return _todo.deleteTodo(params['title'] as String? ?? '');
      case 'ADD_SHOPPING_ITEM':
        return _todo.addShoppingItem(
          item: params['item'] as String? ?? '',
          quantity: (params['quantity'] as num?)?.toInt() ?? 1,
          note: params['note'] as String?,
        );
      case 'GET_SHOPPING_LIST':
        return _todo.getShoppingList();
      case 'DELETE_SHOPPING_ITEM':
        return _todo.deleteShoppingItem(params['item'] as String? ?? '');
      case 'CLEAR_SHOPPING_LIST':
        return _todo.clearShoppingList();
      case 'MARK_SHOPPING_BOUGHT':
        return _todo.markShoppingItemBought(params['item'] as String? ?? '');
      case 'SET_GOAL':
        return _todo.setGoal(
          title: params['title'] as String? ?? '',
          target: params['target'] as String?,
          deadline: params['deadline'] as String?,
        );
      case 'GET_GOALS':
        return _todo.getGoals();
      case 'COMPLETE_GOAL':
        return _todo.completeGoal(params['title'] as String? ?? '');
      case 'DELETE_GOAL':
        return _todo.deleteGoal(params['title'] as String? ?? '');

      // ── HEALTH TRACKING ──
      case 'LOG_WATER':
        return _health.logWater(glasses: (params['glasses'] as num?)?.toInt() ?? 1);
      case 'GET_WATER_LOG':
        return _health.getWaterLog();
      case 'LOG_WEIGHT':
        final w = params['kg'] is num ? (params['kg'] as num).toDouble() : double.tryParse(params['kg']?.toString() ?? '') ?? 0;
        return _health.logWeight(kg: w);
      case 'GET_WEIGHT_LOG':
        return _health.getWeightLog();
      case 'LOG_SLEEP':
        final h = params['hours'] is num ? (params['hours'] as num).toDouble() : double.tryParse(params['hours']?.toString() ?? '') ?? 0;
        return _health.logSleep(hours: h, quality: params['quality'] as String?);
      case 'GET_SLEEP_LOG':
        return _health.getSleepLog();
      case 'LOG_MOOD':
        return _health.logMood(mood: params['mood'] as String? ?? 'normal', note: params['note'] as String?);
      case 'GET_MOOD_LOG':
        return _health.getMoodLog();
      case 'LOG_EXERCISE':
        return _health.logExercise(
          type: params['type'] as String? ?? 'mashq',
          minutes: (params['minutes'] as num?)?.toInt() ?? 30,
          calories: (params['calories'] as num?)?.toInt(),
        );
      case 'GET_EXERCISE_LOG':
        return _health.getExerciseLog();
      case 'GET_HEALTH_SUMMARY':
        return _health.getDailyHealthSummary();

      // ── MATH TOOLS ──
      case 'RANDOM_NUMBER':
        return _math.randomNumber(
          min: (params['min'] as num?)?.toInt() ?? 1,
          max: (params['max'] as num?)?.toInt() ?? 100,
        );
      case 'DICE_ROLL':
        return _math.diceRoll(sides: (params['sides'] as num?)?.toInt() ?? 6);
      case 'COIN_FLIP':
        return _math.coinFlip();
      case 'FIBONACCI':
        return _math.fibonacci((params['n'] as num?)?.toInt() ?? 10);
      case 'FACTORIAL':
        return _math.factorial((params['n'] as num?)?.toInt() ?? 5);
      case 'IS_PRIME':
        return _math.isPrime((params['n'] as num?)?.toInt() ?? 0);
      case 'CONVERT_BASE':
        return _math.convertBase(
          value: params['value'] as String? ?? '',
          fromBase: (params['fromBase'] as num?)?.toInt() ?? 10,
          toBase: (params['toBase'] as num?)?.toInt() ?? 2,
        );
      case 'CALCULATE_BMI':
        final weight = params['weight'] is num ? (params['weight'] as num).toDouble() : double.tryParse(params['weight']?.toString() ?? '') ?? 0;
        final height = params['height'] is num ? (params['height'] as num).toDouble() : double.tryParse(params['height']?.toString() ?? '') ?? 0;
        return _math.calculateBMI(weightKg: weight, heightCm: height);
      case 'CALCULATE_CALORIES':
        return _math.calculateCalories(
          weightKg: (params['weight'] as num?)?.toDouble() ?? 70,
          heightCm: (params['height'] as num?)?.toDouble() ?? 170,
          age: (params['age'] as num?)?.toInt() ?? 25,
          gender: params['gender'] as String? ?? 'erkak',
          activity: params['activity'] as String? ?? 'moderate',
        );
      case 'CALCULATE_AREA':
        return _math.calculateArea(
          shape: params['shape'] as String? ?? '',
          dimensions: Map<String, double>.from((params['dimensions'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {}),
        );
      case 'CALCULATE_VOLUME':
        return _math.calculateVolume(
          shape: params['shape'] as String? ?? '',
          dimensions: Map<String, double>.from((params['dimensions'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {}),
        );
      case 'GCD':
        return _math.gcd((params['a'] as num?)?.toInt() ?? 0, (params['b'] as num?)?.toInt() ?? 0);
      case 'LCM':
        return _math.lcm((params['a'] as num?)?.toInt() ?? 0, (params['b'] as num?)?.toInt() ?? 0);
      case 'POWER':
        return _math.power((params['base'] as num?)?.toDouble() ?? 0, (params['exponent'] as num?)?.toDouble() ?? 0);
      case 'SQRT':
        return _math.squareRoot((params['value'] as num?)?.toDouble() ?? 0);
      case 'PERCENTAGE':
        return _math.percentage(value: (params['value'] as num?)?.toDouble() ?? 0, total: (params['total'] as num?)?.toDouble() ?? 0);
      case 'PERCENT_OF':
        return _math.percentOf(percent: (params['percent'] as num?)?.toDouble() ?? 0, of: (params['of'] as num?)?.toDouble() ?? 0);

      // ── TEXT TOOLS ──
      case 'COUNT_WORDS':
        return _text.countWords(params['text'] as String? ?? '');
      case 'COUNT_CHARACTERS':
        return _text.countCharacters(params['text'] as String? ?? '');
      case 'TEXT_TO_UPPER':
        return _text.toUpperCase(params['text'] as String? ?? '');
      case 'TEXT_TO_LOWER':
        return _text.toLowerCase(params['text'] as String? ?? '');
      case 'REVERSE_TEXT':
        return _text.reverseText(params['text'] as String? ?? '');
      case 'ENCODE_BASE64':
        return _text.encodeBase64(params['text'] as String? ?? '');
      case 'DECODE_BASE64':
        return _text.decodeBase64(params['text'] as String? ?? '');
      case 'GENERATE_PASSWORD':
        return _text.generatePassword(length: (params['length'] as num?)?.toInt() ?? 16);
      case 'FORMAT_NUMBER':
        return _text.formatNumber((params['number'] as num?)?.toDouble() ?? 0);
      case 'GENERATE_UUID':
        return _text.generateUUID();
      case 'CAPITALIZE_WORDS':
        return _text.capitalizeWords(params['text'] as String? ?? '');
      case 'EXTRACT_NUMBERS':
        return _text.extractNumbers(params['text'] as String? ?? '');
      case 'EXTRACT_EMAILS':
        return _text.extractEmails(params['text'] as String? ?? '');
      case 'EXTRACT_PHONES':
        return _text.extractPhones(params['text'] as String? ?? '');
      case 'SLUGIFY':
        return _text.slugify(params['text'] as String? ?? '');
      case 'TEXT_TO_MORSE':
        return _text.textToMorse(params['text'] as String? ?? '');
      case 'MORSE_TO_TEXT':
        return _text.morseToText(params['text'] as String? ?? '');
      case 'ROMAN_TO_NUMBER':
        return _text.romanToNumber(params['text'] as String? ?? '');
      case 'NUMBER_TO_ROMAN':
        return _text.numberToRoman((params['number'] as num?)?.toInt() ?? 0);
      case 'HASH_TEXT':
        return _text.hashText(params['text'] as String? ?? '');
      case 'REPEAT_TEXT':
        return _text.repeatText(params['text'] as String? ?? '', (params['count'] as num?)?.toInt() ?? 2);
      case 'REMOVE_SPACES':
        return _text.removeSpaces(params['text'] as String? ?? '');

      // ── DATE TOOLS ──
      case 'COUNTDOWN':
        return _date.countdown(targetDate: params['date'] as String? ?? '', eventName: params['event'] as String?);
      case 'WORLD_CLOCK':
        return _date.worldClock(params['city'] as String? ?? '');
      case 'DATE_DIFFERENCE':
        return _date.dateDifference(date1: params['date1'] as String? ?? '', date2: params['date2'] as String? ?? '');
      case 'ADD_DAYS':
        return _date.addDays(date: params['date'] as String? ?? '', days: (params['days'] as num?)?.toInt() ?? 0);
      case 'GET_ZODIAC':
        return _date.getZodiac(params['date'] as String? ?? '');
      case 'GET_CALENDAR_WEEK':
        return _date.getCalendarWeek();
      case 'CALCULATE_AGE':
        return _date.calculateAge(params['birthDate'] as String? ?? '');
      case 'IS_LEAP_YEAR':
        return _date.isLeapYear((params['year'] as num?)?.toInt() ?? DateTime.now().year);
      case 'DAYS_IN_MONTH':
        return _date.daysInMonth((params['month'] as num?)?.toInt() ?? DateTime.now().month, year: (params['year'] as num?)?.toInt());
      case 'GET_UNIX_TIMESTAMP':
        return _date.getUnixTimestamp();
      case 'FROM_UNIX_TIMESTAMP':
        return _date.fromUnixTimestamp((params['timestamp'] as num?)?.toInt() ?? 0);
      case 'GET_HIJRI_DATE':
        return _date.getHijriDate();
      case 'GET_PRAYER_TIMES':
        return _date.getPrayerTimes(params['city'] as String? ?? '');

      // ── FUN CONTENT ──
      case 'GET_QUOTE':
        return _fun.getQuote();
      case 'GET_JOKE':
        return _fun.getJoke();
      case 'GET_FACT':
        return _fun.getFact();
      case 'GET_MOTIVATION':
        return _fun.getMotivation();
      case 'GET_PROVERB':
        return _fun.getProverb();
      case 'GET_RIDDLE':
        return _fun.getRiddle();

      // ── FINANCE TOOLS ──
      case 'CALCULATE_LOAN':
        return _finance.calculateLoan(
          amount: (params['amount'] as num?)?.toDouble() ?? 0,
          annualRate: (params['rate'] as num?)?.toDouble() ?? 0,
          months: (params['months'] as num?)?.toInt() ?? 12,
        );
      case 'CALCULATE_TIP':
        return _finance.calculateTip(
          amount: (params['amount'] as num?)?.toDouble() ?? 0,
          tipPercent: (params['percent'] as num?)?.toDouble() ?? 15,
          splitCount: (params['split'] as num?)?.toInt() ?? 1,
        );
      case 'CALCULATE_DISCOUNT':
        return _finance.calculateDiscount(
          price: (params['price'] as num?)?.toDouble() ?? 0,
          discount: (params['discount'] as num?)?.toDouble() ?? 0,
        );
      case 'CALCULATE_TAX':
        return _finance.calculateTax(
          amount: (params['amount'] as num?)?.toDouble() ?? 0,
          taxRate: (params['rate'] as num?)?.toDouble() ?? 12,
        );
      case 'CALCULATE_INTEREST':
        return _finance.calculateInterest(
          principal: (params['principal'] as num?)?.toDouble() ?? 0,
          annualRate: (params['rate'] as num?)?.toDouble() ?? 0,
          years: (params['years'] as num?)?.toInt() ?? 1,
        );
      case 'CALCULATE_SAVINGS':
        return _finance.calculateSavings(
          monthlyAmount: (params['monthly'] as num?)?.toDouble() ?? 0,
          annualRate: (params['rate'] as num?)?.toDouble() ?? 0,
          months: (params['months'] as num?)?.toInt() ?? 12,
        );
      case 'CALCULATE_PROFIT':
        return _finance.calculateProfit(
          cost: (params['cost'] as num?)?.toDouble() ?? 0,
          revenue: (params['revenue'] as num?)?.toDouble() ?? 0,
        );
      case 'CALCULATE_INFLATION':
        return _finance.calculateInflation(
          amount: (params['amount'] as num?)?.toDouble() ?? 0,
          inflationRate: (params['rate'] as num?)?.toDouble() ?? 10,
          years: (params['years'] as num?)?.toInt() ?? 5,
        );
      case 'CONVERT_CURRENCY':
        return _finance.convertCurrency(
          amount: (params['amount'] as num?)?.toDouble() ?? 0,
          from: params['from'] as String? ?? 'USD',
          to: params['to'] as String? ?? 'UZS',
        );
      case 'SET_BUDGET':
        return _finance.setBudget(
          amount: (params['amount'] as num?)?.toDouble() ?? 0,
          category: params['category'] as String? ?? 'umumiy',
        );
      case 'GET_BUDGET':
        return _finance.getBudget();
      case 'CALCULATE_MORTGAGE':
        return _finance.calculateMortgage(
          price: (params['price'] as num?)?.toDouble() ?? 0,
          downPayment: (params['downPayment'] as num?)?.toDouble() ?? 0,
          annualRate: (params['rate'] as num?)?.toDouble() ?? 0,
          years: (params['years'] as num?)?.toInt() ?? 20,
        );
      case 'CALCULATE_SALARY':
        return _finance.calculateNetSalary(
          grossSalary: (params['salary'] as num?)?.toDouble() ?? 0,
          taxRate: (params['taxRate'] as num?)?.toDouble() ?? 12,
        );

      // ── DEVICE CONTROL ──
      case 'OPEN_WIFI':
        return _device.openWifiSettings();
      case 'OPEN_BLUETOOTH':
        return _device.openBluetoothSettings();
      case 'OPEN_DND':
        return _device.openDndSettings();
      case 'OPEN_AIRPLANE':
        return _device.openAirplaneSettings();
      case 'OPEN_BRIGHTNESS':
        return _device.openBrightnessSettings();
      case 'OPEN_NOTIFICATION_SETTINGS':
        return _device.openNotificationSettings();
      case 'OPEN_BATTERY_SETTINGS':
        return _device.openBatterySettings();
      case 'OPEN_STORAGE_SETTINGS':
        return _device.openStorageSettings();
      case 'OPEN_NFC':
        return _device.openNfcSettings();
      case 'OPEN_DEVELOPER_SETTINGS':
        return _device.openDeveloperSettings();
      case 'OPEN_ACCESSIBILITY':
        return _device.openAccessibilitySettings();
      case 'OPEN_DATETIME_SETTINGS':
        return _device.openDateTimeSettings();
      case 'OPEN_ACCOUNT_SETTINGS':
        return _device.openAccountSettings();
      case 'OPEN_LOCATION_SETTINGS':
        return _device.openLocationSettings();
      case 'OPEN_SECURITY_SETTINGS':
        return _device.openSecuritySettings();
      case 'OPEN_LANGUAGE_SETTINGS':
        return _device.openLanguageSettings();
      case 'OPEN_SOUND_SETTINGS':
        return _device.openSoundSettings();
      case 'OPEN_HOTSPOT':
        return _device.openHotspotSettings();
      case 'OPEN_VPN':
        return _device.openVpnSettings();
      case 'OPEN_DATA_USAGE':
        return _device.openDataUsageSettings();
      case 'OPEN_APP_INFO':
        return _device.openAppInfo(params['package'] as String? ?? '');
      case 'UNINSTALL_APP':
        return _device.uninstallApp(params['package'] as String? ?? '');
      case 'COPY_TO_CLIPBOARD':
        return _device.copyToClipboard(params['text'] as String? ?? '');
      case 'READ_CLIPBOARD':
        return _device.readClipboard();
      case 'DIAL_USSD':
        return _device.dialUssd(params['code'] as String? ?? '');
      case 'OPEN_PLAY_STORE':
        return _device.openPlayStore(params['package'] as String? ?? '');
      case 'SPEED_TEST':
        return _device.speedTest();

      // ── LOCATION SEARCH ──
      case 'FIND_NEARBY':
        return _location.findNearby(params['type'] as String? ?? '');
      case 'FIND_RESTAURANT':
        return _location.findRestaurant(query: params['query'] as String?);
      case 'FIND_CAFE':
        return _location.findCafe();
      case 'FIND_PHARMACY':
        return _location.findPharmacy();
      case 'FIND_ATM':
        return _location.findATM();
      case 'FIND_HOSPITAL':
        return _location.findHospital();
      case 'FIND_HOTEL':
        return _location.findHotel(query: params['query'] as String?);
      case 'FIND_GAS_STATION':
        return _location.findGasStation();
      case 'FIND_PARKING':
        return _location.findParking();
      case 'FIND_SUPERMARKET':
        return _location.findSupermarket();
      case 'FIND_MOSQUE':
        return _location.findMosque();
      case 'FIND_SCHOOL':
        return _location.findSchool();
      case 'FIND_BANK':
        return _location.findBank();
      case 'FIND_POLICE':
        return _location.findPolice();
      case 'FIND_GYM':
        return _location.findGym();
      case 'FIND_PARK':
        return _location.findPark();
      case 'FIND_CAR_WASH':
        return _location.findCarWash();
      case 'FIND_BEAUTY':
        return _location.findBeauty();
      case 'FIND_DENTIST':
        return _location.findDentist();
      case 'FIND_LIBRARY':
        return _location.findLibrary();
      case 'SEARCH_MOVIE':
        return _location.searchMovie(params['query'] as String? ?? '');
      case 'SEARCH_BOOK':
        return _location.searchBook(params['query'] as String? ?? '');
      case 'SEARCH_RECIPE':
        return _location.searchRecipe(params['query'] as String? ?? '');
      case 'SEARCH_IMAGE':
        return _location.searchImage(params['query'] as String? ?? '');
      case 'SEARCH_FLIGHT':
        return _location.searchFlight(from: params['from'] as String?, to: params['to'] as String?);
      case 'OPEN_TAXI':
        return _location.openTaxi(service: params['service'] as String?);
      case 'OPEN_PAYME':
        return _location.openPayme();
      case 'OPEN_CLICK':
        return _location.openClick();
      case 'OPEN_UZUM':
        return _location.openUzum();
      case 'OPEN_MYID':
        return _location.openMyId();

      // ── HABITS ──
      case 'CREATE_HABIT':
        return _habit.createHabit(name: params['name'] as String? ?? '');
      case 'LOG_HABIT':
        return _habit.logHabit(name: params['name'] as String? ?? '');
      case 'GET_HABITS':
        return _habit.getHabits();
      case 'GET_HABIT_STATS':
        return _habit.getHabitStats(params['name'] as String? ?? '');
      case 'DELETE_HABIT':
        return _habit.deleteHabit(params['name'] as String? ?? '');
      case 'RESET_HABIT':
        return _habit.resetHabit(params['name'] as String? ?? '');

      // ── SCHEDULED ACTIONS ──
      case 'SCHEDULE_ACTION':
        final triggerAt = DateTime.tryParse(params['triggerAt']?.toString() ?? '');
        if (triggerAt == null) {
          return const ActionResult(success: false, message: 'Vaqtni to\'g\'ri formatda kiriting (YYYY-MM-DD HH:MM)');
        }
        return _scheduled.scheduleAction(
          actionType: params['actionType'] as String? ?? '',
          params: Map<String, dynamic>.from(params['actionParams'] as Map? ?? {}),
          triggerAt: triggerAt,
          description: params['description'] as String?,
        );
      case 'GET_SCHEDULED':
        return _scheduled.getScheduledActions();
      case 'CANCEL_SCHEDULED':
        return _scheduled.cancelScheduledAction(params['description'] as String? ?? '');
      case 'GET_SCHEDULE_HISTORY':
        return _scheduled.getHistory();
      case 'CLEAR_SCHEDULED':
        return _scheduled.clearPending();

      // ── DAILY BRIEFING ──
      case 'GET_DAILY_BRIEFING':
        return _briefing.getDailyBriefing();
      case 'GET_QUICK_STATUS':
        return _briefing.getQuickStatus();

      // ── DATA EXPORT ──
      case 'EXPORT_BOOKKEEPING':
        return _export.exportBookkeeping();
      case 'EXPORT_HEALTH':
        return _export.exportHealthLog();
      case 'EXPORT_NOTES':
        return _export.exportNotes();
      case 'EXPORT_TODOS':
        return _export.exportTodos();
      case 'EXPORT_ALL':
        return _export.exportAll();

      // ── CONTACT MANAGEMENT ──
      case 'ADD_CONTACT':
        return _contact.addContact(
          name: params['name'] as String? ?? '',
          phone: params['phone'] as String?,
          email: params['email'] as String?,
          company: params['company'] as String?,
        );
      case 'LIST_CONTACTS':
        return _contact.listContacts(
          limit: (params['limit'] as num?)?.toInt() ?? 10,
          query: params['query'] as String?,
        );
      case 'GET_CONTACT_COUNT':
        return _contact.getContactCount();
      case 'DELETE_CONTACT':
        return _contact.deleteContact(params['name'] as String? ?? '');

      // ── QR CODE ──
      case 'GENERATE_QR':
        return _qr.generateQr(params['data'] as String? ?? '');
      case 'SCAN_QR':
        return _qr.scanQr();
      case 'GENERATE_WIFI_QR':
        return _qr.generateWifiQr(
          ssid: params['ssid'] as String? ?? '',
          password: params['password'] as String? ?? '',
          encryption: params['encryption'] as String? ?? 'WPA',
        );
      case 'GENERATE_CONTACT_QR':
        return _qr.generateContactQr(
          name: params['name'] as String? ?? '',
          phone: params['phone'] as String?,
          email: params['email'] as String?,
        );

      // ── POMODORO (uses SET_TIMER) ──
      case 'POMODORO_START':
        final pomodoroMinutes = (params['minutes'] as num?)?.toInt() ?? 25;
        return _setTimer(
          pomodoroMinutes * 60,
          params['label'] as String? ?? 'Pomodoro',
        );

      // ── JOURNAL ──
      case 'JOURNAL_ADD':
        return _journal.addEntry(
          content: params['content'] as String? ?? '',
          mood: params['mood'] as String?,
          tags: params['tags'] as String?,
        );
      case 'JOURNAL_LIST':
        return _journal.getEntries(limit: (params['limit'] as num?)?.toInt() ?? 10);
      case 'JOURNAL_GET_BY_DATE':
        return _journal.getEntryByDate(params['date'] as String? ?? '');
      case 'JOURNAL_DELETE':
        return _journal.deleteEntry(params['date'] as String? ?? '');
      case 'JOURNAL_SEARCH':
        return _journal.searchJournal(params['query'] as String? ?? '');
      case 'JOURNAL_STATS':
        return _journal.getJournalStats();

      // ── SMART SUGGESTIONS ──
      case 'GET_SUGGESTIONS':
        return _suggestions.getSuggestions();

      // ── PASSWORD VAULT ──
      case 'VAULT_ADD':
        return _vault.addPassword(
          service: params['service'] as String? ?? '',
          username: params['username'] as String? ?? '',
          password: params['password'] as String? ?? '',
        );
      case 'VAULT_GET':
        return _vault.getPassword(params['service'] as String? ?? '');
      case 'VAULT_LIST':
        return _vault.listPasswords();
      case 'VAULT_DELETE':
        return _vault.deletePassword(params['service'] as String? ?? '');
      case 'VAULT_UPDATE':
        return _vault.updatePassword(
          service: params['service'] as String? ?? '',
          newPassword: params['newPassword'] as String? ?? '',
        );
      case 'VAULT_GENERATE':
        return _vault.generateAndSave(
          service: params['service'] as String? ?? '',
          username: params['username'] as String? ?? '',
          length: (params['length'] as num?)?.toInt() ?? 16,
        );

      // ── BOOK TRACKER ──
      case 'ADD_BOOK':
        return _books.addBook(
          title: params['title'] as String? ?? '',
          author: params['author'] as String?,
          totalPages: (params['totalPages'] as num?)?.toInt(),
        );
      case 'UPDATE_BOOK_PROGRESS':
        return _books.updateProgress(
          title: params['title'] as String? ?? '',
          currentPage: (params['currentPage'] as num?)?.toInt() ?? 0,
        );
      case 'FINISH_BOOK':
        return _books.finishBook(params['title'] as String? ?? '');
      case 'GET_BOOKS':
        return _books.getBooks(status: params['status'] as String?);
      case 'ADD_TO_WISHLIST':
        return _books.addToWishlist(
          title: params['title'] as String? ?? '',
          author: params['author'] as String?,
        );
      case 'DELETE_BOOK':
        return _books.deleteBook(params['title'] as String? ?? '');
      case 'GET_READING_STATS':
        return _books.getReadingStats();
      case 'RATE_BOOK':
        return _books.rateBook(
          title: params['title'] as String? ?? '',
          rating: (params['rating'] as num?)?.toInt() ?? 5,
        );

      // ── WORKOUT PLANS ──
      case 'GET_WORKOUT_PLANS':
        return _workout.getPlans();
      case 'GET_WORKOUT_PLAN':
        return _workout.getPlan(params['name'] as String? ?? '');
      case 'START_WORKOUT':
        return _workout.startWorkout(params['name'] as String? ?? '');
      case 'LOG_WORKOUT':
        return _workout.logWorkout(
          planName: params['name'] as String? ?? '',
          minutes: (params['minutes'] as num?)?.toInt() ?? 30,
          caloriesBurned: (params['calories'] as num?)?.toInt(),
        );

      // ── BRAIN GAMES ──
      case 'MATH_QUIZ':
        return _brain.getMathQuiz(difficulty: params['difficulty'] as String? ?? 'normal');
      case 'CHECK_ANSWER':
        return _brain.checkAnswer(answer: params['answer'] as String? ?? '');
      case 'WORD_GAME':
        return _brain.getWordGame();
      case 'CHECK_WORD_ANSWER':
        return _brain.checkWordAnswer(answer: params['answer'] as String? ?? '');
      case 'NUMBER_SEQUENCE':
        return _brain.getNumberSequence();
      case 'CHECK_SEQUENCE_ANSWER':
        return _brain.checkSequenceAnswer(answer: params['answer'] as String? ?? '');
      case 'TRIVIA_QUESTION':
        return _brain.getTriviaQuestion();
      case 'CHECK_TRIVIA_ANSWER':
        return _brain.checkTriviaAnswer(answer: params['answer'] as String? ?? '');
      case 'GET_GAME_SCORES':
        return _brain.getScores();
      case 'RESET_GAME_SCORES':
        return _brain.resetScores();

      // ── FAVORITES ──
      case 'ADD_FAVORITE':
        return _favorites.addFavorite(
          name: params['name'] as String? ?? '',
          type: params['type'] as String? ?? 'command',
          data: Map<String, dynamic>.from(params['data'] as Map? ?? {}),
        );
      case 'GET_FAVORITES':
        return _favorites.getFavorites(type: params['type'] as String?);
      case 'REMOVE_FAVORITE':
        return _favorites.removeFavorite(params['name'] as String? ?? '');
      case 'EXECUTE_FAVORITE':
        return _favorites.executeFavorite(params['name'] as String? ?? '');
      case 'ADD_QUICK_COMMAND':
        return _favorites.addQuickCommand(
          name: params['name'] as String? ?? '',
          actionType: params['actionType'] as String? ?? '',
          params: Map<String, dynamic>.from(params['actionParams'] as Map? ?? {}),
        );
      case 'GET_QUICK_COMMANDS':
        return _favorites.getQuickCommands();

      // ── USAGE STATS ──
      case 'GET_TOP_ACTIONS':
        return _usageStats.getTopActions(limit: (params['limit'] as num?)?.toInt() ?? 10);
      case 'GET_DAILY_ACTIVITY':
        return _usageStats.getDailyActivity();
      case 'GET_USAGE_SUMMARY':
        return _usageStats.getUsageSummary();
      case 'RESET_USAGE_STATS':
        return _usageStats.resetStats();

      // ── TELEGRAM EXPANDED ──
      case 'TELEGRAM_BOT_INFO':
        return TelegramService().getMyBotInfo();
      case 'TELEGRAM_UNREAD':
        return TelegramService().getUnreadMessages(limit: (params['limit'] as num?)?.toInt() ?? 10);
      case 'TELEGRAM_SEND_PHOTO':
        final chats = await TelegramService().fetchKnownChats();
        final chatId = _resolveTelegramChatId(chats, params['contact'] as String? ?? '');
        if (chatId == null) return ActionResult(success: false, message: '"${params['contact']}" kontakti topilmadi');
        return TelegramService().sendPhoto(chatId: chatId, photoUrl: params['photoUrl'] as String? ?? '', caption: params['caption'] as String?);
      case 'TELEGRAM_SEND_LOCATION':
        final chats2 = await TelegramService().fetchKnownChats();
        final chatId2 = _resolveTelegramChatId(chats2, params['contact'] as String? ?? '');
        if (chatId2 == null) return ActionResult(success: false, message: '"${params['contact']}" kontakti topilmadi');
        return TelegramService().sendLocation(
          chatId: chatId2,
          latitude: (params['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (params['longitude'] as num?)?.toDouble() ?? 0,
        );
      case 'TELEGRAM_SEND_POLL':
        final chats3 = await TelegramService().fetchKnownChats();
        final chatId3 = _resolveTelegramChatId(chats3, params['contact'] as String? ?? '');
        if (chatId3 == null) return ActionResult(success: false, message: '"${params['contact']}" kontakti topilmadi');
        final options = (params['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
        return TelegramService().sendPoll(chatId: chatId3, question: params['question'] as String? ?? '', options: options);
      case 'TELEGRAM_SEND_CONTACT':
        final chats4 = await TelegramService().fetchKnownChats();
        final chatId4 = _resolveTelegramChatId(chats4, params['contact'] as String? ?? '');
        if (chatId4 == null) return ActionResult(success: false, message: '"${params['contact']}" kontakti topilmadi');
        return TelegramService().sendContact(
          chatId: chatId4,
          phone: params['phone'] as String? ?? '',
          firstName: params['firstName'] as String? ?? '',
          lastName: params['lastName'] as String?,
        );
      case 'TELEGRAM_SEND_DOCUMENT':
        final chats5 = await TelegramService().fetchKnownChats();
        final chatId5 = _resolveTelegramChatId(chats5, params['contact'] as String? ?? '');
        if (chatId5 == null) return ActionResult(success: false, message: '"${params['contact']}" kontakti topilmadi');
        return TelegramService().sendDocument(chatId: chatId5, documentUrl: params['documentUrl'] as String? ?? '', caption: params['caption'] as String?);
      case 'TELEGRAM_KNOWN_CHATS':
        return TelegramService().getKnownChatsList();
      case 'TELEGRAM_MEMBER_COUNT':
        return TelegramService().getChatMemberCount((params['chatId'] as num?)?.toInt() ?? 0);

      default:
        return ActionResult(
          success: false,
          message: 'Noma\'lum buyruq: $actionType',
        );
    }
  }

  Future<ActionResult> _makeCall(String phone) async {
    final status = await Permission.phone.request();
    if (status.isDenied) {
      return ActionResult(
        success: false,
        message: 'Qo\'ng\'iroq ruxsati berilmagan',
      );
    }

    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      await FlutterPhoneDirectCaller.callNumber(cleaned);
      return ActionResult(success: true, message: '$cleaned ga qo\'ng\'iroq qilinmoqda');
    } catch (e) {
      final uri = Uri(scheme: 'tel', path: cleaned);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return ActionResult(success: true, message: 'Qo\'ng\'iroq qilinmoqda');
      }
      return ActionResult(success: false, message: 'Qo\'ng\'iroq qilishda xato');
    }
  }

  Future<ActionResult> _sendSms(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return ActionResult(success: true, message: 'SMS ilovasi ochildi');
    }
    return ActionResult(success: false, message: 'SMS yuborishda xato');
  }

  Future<ActionResult> _openApp(String appName) async {
    final packageMap = {
      'telegram': 'org.telegram.messenger',
      'whatsapp': 'com.whatsapp',
      'instagram': 'com.instagram.android',
      'youtube': 'com.google.android.youtube',
      'gmail': 'com.google.android.gm',
      'maps': 'com.google.android.apps.maps',
      'chrome': 'com.android.chrome',
      'camera': 'com.android.camera2',
      'calculator': 'com.android.calculator2',
      'spotify': 'com.spotify.music',
      'netflix': 'com.netflix.mediaclient',
      'facebook': 'com.facebook.katana',
      'twitter': 'com.twitter.android',
      'tiktok': 'com.zhiliaoapp.musically',
      'zoom': 'us.zoom.videomeetings',
      'calendar': 'com.google.android.calendar',
      'clock': 'com.google.android.deskclock',
      'notes': 'com.google.android.keep',
      'files': 'com.google.android.documentsui',
      'passwords': 'com.google.android.apps.authenticator2',
      'sheets': 'com.google.android.apps.docs.editors.sheets',
      'teams': 'com.microsoft.teams',
      'meet': 'com.google.android.apps.meetings',
      'skype': 'com.skype.raider',
      'radio': 'com.xiaomi.midrop',
      'drive': 'com.google.android.apps.docs',
      'photos': 'com.google.android.apps.photos',
      'dialer': 'com.google.android.dialer',
      'sms': 'com.google.android.apps.messaging',
      'gallery': 'com.google.android.apps.photos',
      'settings': 'com.android.settings',
    };

    final lowerName = appName.toLowerCase();
    String? packageName;

    for (final entry in packageMap.entries) {
      if (lowerName.contains(entry.key)) {
        packageName = entry.value;
        break;
      }
    }

    if (packageName != null) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: packageName,
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return ActionResult(success: true, message: '$appName ochildi');
      } catch (e) {
        final storeUrl = Uri.parse(
          'market://details?id=$packageName',
        );
        if (await canLaunchUrl(storeUrl)) {
          await launchUrl(storeUrl);
        }
        return ActionResult(
          success: false,
          message: '$appName topilmadi, Play Store ochildi',
        );
      }
    }

    return ActionResult(success: false, message: '$appName ilovasi topilmadi');
  }

  Future<ActionResult> _playMusic(String query) async {
    final spotifyUri = Uri.parse(
      'spotify:search:${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(spotifyUri)) {
      await launchUrl(spotifyUri);
      return ActionResult(success: true, message: 'Spotify\'da qidirilmoqda: $query');
    }

    final youtubeUri = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$query music")}',
    );
    await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: 'YouTube\'da musiqa qidirilmoqda');
  }

  Future<ActionResult> _searchWeb(String query) async {
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: 'Google\'da qidirilmoqda: $query');
  }

  Future<ActionResult> _setAlarm(String time, String label) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': label,
      },
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Uyg\'otgich sozlandi: $time - $label');
    } catch (e) {
      return ActionResult(success: false, message: 'Uyg\'otgich sozlashda xato');
    }
  }

  Future<ActionResult> _openSettings(String section) async {
    final settingsMap = {
      'wifi': 'android.settings.WIFI_SETTINGS',
      'bluetooth': 'android.settings.BLUETOOTH_SETTINGS',
      'sound': 'android.settings.SOUND_SETTINGS',
      'display': 'android.settings.DISPLAY_SETTINGS',
      'battery': 'android.settings.BATTERY_SAVER_SETTINGS',
      'storage': 'android.settings.INTERNAL_STORAGE_SETTINGS',
      'apps': 'android.settings.MANAGE_ALL_APPLICATIONS_SETTINGS',
      'location': 'android.settings.LOCATION_SOURCE_SETTINGS',
      'security': 'android.settings.SECURITY_SETTINGS',
      'language': 'android.settings.LOCALE_SETTINGS',
    };

    final lowerSection = section.toLowerCase();
    String action = 'android.settings.SETTINGS';

    for (final entry in settingsMap.entries) {
      if (lowerSection.contains(entry.key)) {
        action = entry.value;
        break;
      }
    }

    final intent = AndroidIntent(action: action);
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Sozlamalar ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Sozlamalar ochishda xato');
    }
  }

  Future<ActionResult> _sendTelegram(String contact, String message) async {
    final telegram = TelegramService();
    if (telegram.isConfigured && message.isNotEmpty) {
      try {
        await telegram.sendToContact(contact: contact, text: message);
        return ActionResult(
          success: true,
          message: '"$contact" ga Telegram orqali xabar yuborildi',
        );
      } on TelegramException catch (e) {
        _logger.w('Telegram avto-yuborish ishlamadi: $e');
        // Fall through to opening the app — bot can't reach this contact yet.
      }
    }

    final uri = Uri.parse('https://t.me/$contact');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(
        success: true,
        message: telegram.isConfigured
            ? 'Bu kontakt botga hali yozmagan, shuning uchun Telegram qo\'lda ochildi'
            : 'Telegram ochildi (avtomatik yuborish uchun Sozlamalar → Integratsiyalarda bot tokenini kiriting)',
      );
    }
    return ActionResult(success: false, message: 'Telegram topilmadi');
  }

  Future<ActionResult> _sendWhatsApp(String phone, String message) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final whatsapp = WhatsAppService();

    if (await whatsapp.isConfigured && message.isNotEmpty) {
      try {
        await whatsapp.sendTextMessage(phone: cleaned, text: message);
        return ActionResult(
          success: true,
          message: '$cleaned ga WhatsApp orqali xabar yuborildi',
        );
      } on WhatsAppException catch (e) {
        _logger.w('WhatsApp avto-yuborish ishlamadi: $e');
        // Fall through to opening the app — likely outside the 24h window
        // or the recipient hasn't messaged the business number yet.
      }
    }

    final uri = Uri.parse(
      'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(
        success: true,
        message: await whatsapp.isConfigured
            ? 'Avtomatik yuborib bo\'lmadi (24 soatlik oyna yopiq), shuning uchun WhatsApp qo\'lda ochildi'
            : 'WhatsApp ochildi (avtomatik yuborish uchun Sozlamalar → Integratsiyalarda Business hisobni ulang)',
      );
    }
    return ActionResult(success: false, message: 'WhatsApp topilmadi');
  }

  Future<ActionResult> _searchYouTube(String query) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SEARCH',
      package: 'com.google.android.youtube',
      arguments: {'query': query},
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'YouTube\'da qidirilmoqda: $query');
    } catch (e) {
      final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'YouTube ochildi');
    }
  }

  Future<ActionResult> _openCamera() async {
    final intent = AndroidIntent(
      action: 'android.media.action.IMAGE_CAPTURE',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Kamera ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Kamera ochishda xato');
    }
  }

  Future<ActionResult> _openGallery() async {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      type: 'image/*',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Galereya ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Galereya ochishda xato');
    }
  }

  Future<ActionResult> _getWeather(String city) async {
    if (city.isEmpty) {
      return ActionResult(success: false, message: 'Qaysi shahar uchun ob-havoni aytay?');
    }
    try {
      final info = await WeatherService().getCurrentWeather(city);
      return ActionResult(success: true, message: info.toSpokenSummary(), data: info);
    } on WeatherException catch (e) {
      return ActionResult(
        success: false,
        message: e.message.contains('sozlanmagan')
            ? 'Ob-havo ma\'lumotlari uchun Sozlamalar → Integratsiyalarda OpenWeatherMap API kalitini kiriting'
            : e.message,
      );
    }
  }

  Future<ActionResult> _getNews(String? topic) async {
    try {
      final articles = await NewsService().getTopHeadlines(topic: topic);
      if (articles.isEmpty) {
        return ActionResult(success: true, message: 'Hozircha yangiliklar topilmadi');
      }
      final summary = articles
          .take(5)
          .map((a) => '• ${a.title} (${a.source})')
          .join('\n');
      return ActionResult(
        success: true,
        message: 'So\'nggi yangiliklar:\n$summary',
        data: articles,
      );
    } on NewsException catch (e) {
      return ActionResult(
        success: false,
        message: e.message.contains('sozlanmagan')
            ? 'Yangiliklar uchun Sozlamalar → Integratsiyalarda GNews API kalitini kiriting'
            : e.message,
      );
    }
  }

  Future<ActionResult> _convertUnits(Map<String, dynamic> params) async {
    final rawValue = params['value'];
    final value = rawValue is num ? rawValue.toDouble() : double.tryParse(rawValue?.toString() ?? '');
    final from = params['from'] as String? ?? '';
    final to = params['to'] as String? ?? '';

    if (value == null || from.isEmpty || to.isEmpty) {
      return ActionResult(
        success: false,
        message: 'Aylantirish uchun qiymat va o\'lchov birliklarini ayting (masalan: 10 kilometrni milga aylantir)',
      );
    }

    try {
      final result = UnitConverter.convert(value: value, from: from, to: to);
      return ActionResult(
        success: true,
        message: '${_formatNumber(value)} $from = ${_formatNumber(result)} $to',
        data: result,
      );
    } on UnitConversionException catch (e) {
      return ActionResult(success: false, message: e.message);
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    final fixed = value.toStringAsFixed(4);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<ActionResult> _createCalendarEvent(Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? '';
    if (title.isEmpty) {
      return const ActionResult(success: false, message: 'Tadbir nomini ayting');
    }

    final description = params['description'] as String? ?? '';
    final location = params['location'] as String? ?? '';
    final dateStr = params['date'] as String? ?? '';
    final timeStr = params['time'] as String? ?? '';

    var startTime = DateTime.now();
    if (dateStr.contains('ertaga') || dateStr.contains('tomorrow')) {
      startTime = startTime.add(const Duration(days: 1));
    } else if (dateStr.isNotEmpty && !dateStr.contains('bugun') && !dateStr.contains('today')) {
      startTime = DateTime.tryParse(dateStr) ?? startTime;
    }

    if (timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? startTime.hour;
        final minute = int.tryParse(parts[1]) ?? 0;
        startTime = DateTime(startTime.year, startTime.month, startTime.day, hour, minute);
      }
    }

    final beginMs = startTime.millisecondsSinceEpoch;
    final endMs = startTime.add(const Duration(hours: 1)).millisecondsSinceEpoch;

    final intent = AndroidIntent(
      action: 'android.intent.action.INSERT',
      data: 'content://com.android.calendar/events',
      arguments: {
        'title': title,
        'description': description,
        'eventLocation': location,
        'beginTime': beginMs,
        'endTime': endMs,
      },
    );

    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Kalendarga qo\'shilmoqda: $title');
    } catch (e) {
      return ActionResult(success: false, message: 'Kalendar ochishda xato');
    }
  }

  Future<ActionResult> _sendEmail(Map<String, dynamic> params) async {
    final to = params['to'] as String? ?? '';
    final subject = params['subject'] as String? ?? '';
    final body = params['body'] as String? ?? '';

    if (to.isEmpty) {
      return const ActionResult(success: false, message: 'Email manzilini ayting');
    }

    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return ActionResult(success: true, message: '$to ga email tayyorlanmoqda');
    }
    return const ActionResult(success: false, message: 'Email ilovasi topilmadi');
  }

  Future<ActionResult> _setReminder(Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? 'Eslatma';
    final message = params['message'] as String? ?? title;
    final timeStr = params['time'] as String? ?? '5';

    final minutes = int.tryParse(timeStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 5;

    final reminder = await ReminderService().add(
      title: title,
      message: message,
      minutesFromNow: minutes,
    );

    return ActionResult(
      success: true,
      message: '$minutes daqiqadan so\'ng eslatiladi: $title',
      data: reminder.id,
    );
  }

  Future<ActionResult> _findContact(String name) async {
    if (name.isEmpty) {
      return const ActionResult(success: false, message: 'Kontakt ismini ayting');
    }

    final status = await Permission.contacts.request();
    if (status.isDenied) {
      return const ActionResult(
        success: false,
        message: 'Kontaktlar ruxsati berilmagan',
      );
    }

    final contacts = await ContactsService.getContacts(
      query: name,
      withThumbnails: false,
    );

    if (contacts.isEmpty) {
      return ActionResult(
        success: false,
        message: '"$name" nomli kontakt topilmadi',
      );
    }

    final results = contacts.take(3).map((c) {
      final phone = c.phones?.firstOrNull?.value ?? 'raqam yo\'q';
      return '${c.displayName ?? "Nomsiz"}: $phone';
    }).join('\n');

    return ActionResult(
      success: true,
      message: 'Topilgan kontaktlar:\n$results',
      data: contacts.first.phones?.firstOrNull?.value,
    );
  }

  Future<ActionResult> _openMaps(String location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/${Uri.encodeComponent(location)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'Xaritada topilmoqda: $location');
    }
    return ActionResult(success: false, message: 'Xarita ochishda xato');
  }

  // ── SET_TIMER ──────────────────────────────────────────────────────────────

  Future<ActionResult> _setTimer(int seconds, String message) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: {
        'android.intent.extra.alarm.LENGTH': seconds,
        'android.intent.extra.alarm.MESSAGE': message,
        'android.intent.extra.alarm.SKIP_UI': true,
      },
    );
    try {
      await intent.launch();
      final minutes = seconds >= 60 ? '${seconds ~/ 60} daqiqa' : '$seconds soniya';
      return ActionResult(success: true, message: 'Taymer sozlandi: $minutes - $message');
    } catch (e) {
      return ActionResult(success: false, message: 'Taymer sozlashda xato');
    }
  }

  // ── NAVIGATE_TO ────────────────────────────────────────────────────────────

  Future<ActionResult> _navigateTo(String location) async {
    if (location.isEmpty) {
      return const ActionResult(success: false, message: 'Manzilni ayting');
    }
    final uri = Uri.parse(
      'google.navigation:q=${Uri.encodeComponent(location)}&mode=d',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'Navigatsiya boshlandi: $location');
    } catch (e) {
      // Fallback to Google Maps web URL
      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(location)}',
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return ActionResult(success: true, message: 'Xaritada yo\'nalish: $location');
      }
      return ActionResult(success: false, message: 'Navigatsiya ochishda xato');
    }
  }

  // ── SHARE_TEXT ─────────────────────────────────────────────────────────────

  Future<ActionResult> _shareText(String text) async {
    if (text.isEmpty) {
      return const ActionResult(success: false, message: 'Ulashish uchun matn ayting');
    }
    final intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      type: 'text/plain',
      arguments: {
        'android.intent.extra.TEXT': text,
      },
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Ulashish oynasi ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Ulashishda xato');
    }
  }

  // ── TRANSLATE_TEXT ─────────────────────────────────────────────────────────

  Future<ActionResult> _translateText(String text, String from, String to) async {
    if (text.isEmpty) {
      return const ActionResult(success: false, message: 'Tarjima qilish uchun matn ayting');
    }
    final uri = Uri.parse(
      'https://translate.google.com/?sl=${Uri.encodeComponent(from)}&tl=${Uri.encodeComponent(to)}&text=${Uri.encodeComponent(text)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'Google Tarjimon ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Tarjimon ochishda xato');
    }
  }

  // ── TAKE_NOTE ──────────────────────────────────────────────────────────────

  Future<ActionResult> _takeNote(String title, String content) async {
    if (title.isEmpty && content.isEmpty) {
      return const ActionResult(success: false, message: 'Eslatma sarlavhasi yoki matnini ayting');
    }
    try {
      final box = await Hive.openBox('notes');
      final id = const Uuid().v4();
      final note = {
        'id': id,
        'title': title.isNotEmpty ? title : 'Eslatma',
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      };
      await box.put(id, note);
      return ActionResult(
        success: true,
        message: 'Eslatma saqlandi: ${note['title']}',
        data: note,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Eslatma saqlashda xato: $e');
    }
  }

  // ── GET_NOTES ──────────────────────────────────────────────────────────────

  Future<ActionResult> _getNotes() async {
    try {
      final box = await Hive.openBox('notes');
      if (box.isEmpty) {
        return const ActionResult(success: true, message: 'Hozircha eslatmalar yo\'q');
      }
      final notes = box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      notes.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      final lastNotes = notes.take(10).toList();
      final summary = lastNotes
          .map((n) => '• ${n['title']}: ${n['content']}')
          .join('\n');
      return ActionResult(
        success: true,
        message: 'Eslatmalar (${lastNotes.length}):\n$summary',
        data: lastNotes,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Eslatmalarni o\'qishda xato: $e');
    }
  }

  // ── DELETE_NOTE ────────────────────────────────────────────────────────────

  Future<ActionResult> _deleteNote(String title) async {
    if (title.isEmpty) {
      return const ActionResult(success: false, message: 'O\'chirish uchun eslatma sarlavhasini ayting');
    }
    try {
      final box = await Hive.openBox('notes');
      final lowerTitle = title.toLowerCase();
      String? keyToDelete;
      for (final key in box.keys) {
        final note = Map<String, dynamic>.from(box.get(key) as Map);
        if ((note['title'] as String).toLowerCase() == lowerTitle) {
          keyToDelete = key as String;
          break;
        }
      }
      if (keyToDelete != null) {
        await box.delete(keyToDelete);
        return ActionResult(success: true, message: 'Eslatma o\'chirildi: $title');
      }
      return ActionResult(success: false, message: '"$title" nomli eslatma topilmadi');
    } catch (e) {
      return ActionResult(success: false, message: 'Eslatmani o\'chirishda xato: $e');
    }
  }

  // ── GET_TIME ───────────────────────────────────────────────────────────────

  static const _uzbekDays = [
    'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba',
    'Juma', 'Shanba', 'Yakshanba',
  ];
  static const _uzbekMonths = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
  ];

  Future<ActionResult> _getTime() async {
    final now = DateTime.now();
    final dayName = _uzbekDays[now.weekday - 1];
    final monthName = _uzbekMonths[now.month - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final message =
        'Hozir $hour:$minute, $dayName, ${now.day}-$monthName ${now.year}-yil';
    return ActionResult(success: true, message: message);
  }

  // ── CALCULATE ──────────────────────────────────────────────────────────────

  Future<ActionResult> _calculate(String expression) async {
    if (expression.isEmpty) {
      return const ActionResult(success: false, message: 'Hisoblash uchun ifoda ayting');
    }
    try {
      final result = _evaluateExpression(expression);
      final formatted = result == result.roundToDouble() && result.abs() < 1e15
          ? result.toStringAsFixed(0)
          : result.toString();
      return ActionResult(success: true, message: '$expression = $formatted');
    } catch (e) {
      return ActionResult(success: false, message: 'Hisoblashda xato: ifodani tekshiring');
    }
  }

  double _evaluateExpression(String expr) {
    expr = expr.replaceAll(' ', '')
        .replaceAll('х', '*')  // Cyrillic х
        .replaceAll('×', '*')  // ×
        .replaceAll('÷', '/'); // ÷
    return _parseExpression(expr, 0).value;
  }

  _ParseResult _parseExpression(String expr, int pos) {
    var result = _parseTerm(expr, pos);
    var value = result.value;
    var i = result.pos;
    while (i < expr.length && (expr[i] == '+' || expr[i] == '-')) {
      final op = expr[i];
      i++;
      result = _parseTerm(expr, i);
      i = result.pos;
      if (op == '+') {
        value += result.value;
      } else {
        value -= result.value;
      }
    }
    return _ParseResult(value, i);
  }

  _ParseResult _parseTerm(String expr, int pos) {
    var result = _parseFactor(expr, pos);
    var value = result.value;
    var i = result.pos;
    while (i < expr.length && (expr[i] == '*' || expr[i] == '/')) {
      final op = expr[i];
      i++;
      result = _parseFactor(expr, i);
      i = result.pos;
      if (op == '*') {
        value *= result.value;
      } else {
        if (result.value == 0) throw Exception('Division by zero');
        value /= result.value;
      }
    }
    return _ParseResult(value, i);
  }

  _ParseResult _parseFactor(String expr, int pos) {
    if (pos < expr.length && expr[pos] == '(') {
      final result = _parseExpression(expr, pos + 1);
      // skip closing ')'
      final newPos = result.pos < expr.length && expr[result.pos] == ')'
          ? result.pos + 1
          : result.pos;
      return _ParseResult(result.value, newPos);
    }

    // Handle unary minus
    if (pos < expr.length && expr[pos] == '-') {
      final result = _parseFactor(expr, pos + 1);
      return _ParseResult(-result.value, result.pos);
    }

    // Parse number
    var i = pos;
    while (i < expr.length &&
        (expr.codeUnitAt(i) >= 48 && expr.codeUnitAt(i) <= 57 || expr[i] == '.')) {
      i++;
    }
    if (i == pos) throw FormatException('Expected number at position $pos');
    final value = double.parse(expr.substring(pos, i));
    return _ParseResult(value, i);
  }

  // ── OPEN_URL ───────────────────────────────────────────────────────────────

  Future<ActionResult> _openUrl(String url) async {
    if (url.isEmpty) {
      return const ActionResult(success: false, message: 'URL manzilini ayting');
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return ActionResult(success: true, message: 'Sahifa ochildi: $url');
      }
      return ActionResult(success: false, message: 'URL ochishda xato: $url');
    } catch (e) {
      return ActionResult(success: false, message: 'URL ochishda xato: $url');
    }
  }

  // ── TOGGLE_FLASHLIGHT ─────────────────────────────────────────────────────

  Future<ActionResult> _toggleFlashlight() async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.android.systemui',
        componentName: 'com.android.systemui.flashlight.FlashlightActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return const ActionResult(success: true, message: 'Fonar yoqildi/o\'chirildi');
    } catch (e) {
      // Fallback: open display settings
      try {
        final fallbackIntent = AndroidIntent(
          action: 'android.settings.DISPLAY_SETTINGS',
        );
        await fallbackIntent.launch();
        return const ActionResult(
          success: true,
          message: 'Fonar to\'g\'ridan-to\'g\'ri boshqarib bo\'lmadi, displey sozlamalari ochildi',
        );
      } catch (e2) {
        return const ActionResult(success: false, message: 'Fonarni boshqarishda xato');
      }
    }
  }

  // ── SHOW_DEVICE_INFO ──────────────────────────────────────────────────────

  Future<ActionResult> _showDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final now = DateTime.now();
      final dayName = _uzbekDays[now.weekday - 1];
      final message = '''Qurilma ma'lumotlari:
• Ilova nomi: ${packageInfo.appName}
• Versiya: ${packageInfo.version}
• Build raqami: ${packageInfo.buildNumber}
• Qurilma vaqti: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}, $dayName, ${now.day}-${_uzbekMonths[now.month - 1]} ${now.year}''';
      return ActionResult(
        success: true,
        message: message,
        data: {
          'appName': packageInfo.appName,
          'version': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'deviceTime': now.toIso8601String(),
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Qurilma ma\'lumotlarini olishda xato: $e');
    }
  }

  int? _resolveTelegramChatId(Map<String, int> chats, String contact) {
    final key = contact.toLowerCase().replaceAll('@', '').trim();
    return chats[key];
  }
}

class ActionResult {
  final bool success;
  final String message;
  final dynamic data;

  const ActionResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class _ParseResult {
  final double value;
  final int pos;

  const _ParseResult(this.value, this.pos);
}
