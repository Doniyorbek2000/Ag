import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'action_executor.dart';

class LocationSearchService {
  // Generic nearby search
  Future<ActionResult> findNearby(String type) async {
    return _searchMaps(type, '$type yaqin atrofda qidirilmoqda');
  }

  Future<ActionResult> findRestaurant({String? query}) async {
    return _searchMaps(query ?? 'restoran', 'Restoran qidirilmoqda');
  }

  Future<ActionResult> findCafe() async {
    return _searchMaps('kafe kofe', 'Kafe qidirilmoqda');
  }

  Future<ActionResult> findPharmacy() async {
    return _searchMaps('dorixona apteka', 'Dorixona qidirilmoqda');
  }

  Future<ActionResult> findATM() async {
    return _searchMaps('bankomat ATM', 'Bankomat qidirilmoqda');
  }

  Future<ActionResult> findHospital() async {
    return _searchMaps('shifoxona kasalxona', 'Shifoxona qidirilmoqda');
  }

  Future<ActionResult> findHotel({String? query}) async {
    return _searchMaps(query ?? 'mehmonxona hotel', 'Mehmonxona qidirilmoqda');
  }

  Future<ActionResult> findGasStation() async {
    return _searchMaps('benzin yoqilg\'i stansiya', 'Yoqilg\'i stansiyasi qidirilmoqda');
  }

  Future<ActionResult> findParking() async {
    return _searchMaps('parkovka avtoturargoh', 'Parkovka qidirilmoqda');
  }

  Future<ActionResult> findSupermarket() async {
    return _searchMaps('supermarket do\'kon', 'Supermarket qidirilmoqda');
  }

  Future<ActionResult> findMosque() async {
    return _searchMaps('masjid jome', 'Masjid qidirilmoqda');
  }

  Future<ActionResult> findSchool() async {
    return _searchMaps('maktab ta\'lim', 'Maktab qidirilmoqda');
  }

  Future<ActionResult> findBank() async {
    return _searchMaps('bank filial', 'Bank qidirilmoqda');
  }

  Future<ActionResult> findPolice() async {
    return _searchMaps('politsiya IIB', 'Politsiya bo\'limi qidirilmoqda');
  }

  Future<ActionResult> findGym() async {
    return _searchMaps('sport zal trenazhyor', 'Sport zal qidirilmoqda');
  }

  Future<ActionResult> findPark() async {
    return _searchMaps('park bog\' dam olish', 'Park qidirilmoqda');
  }

  Future<ActionResult> findCarWash() async {
    return _searchMaps('avtomoyka', 'Avtomoyka qidirilmoqda');
  }

  Future<ActionResult> findBeauty() async {
    return _searchMaps('go\'zallik salon sartarosh', 'Salon qidirilmoqda');
  }

  Future<ActionResult> findDentist() async {
    return _searchMaps('stomatolog tish doktori', 'Stomatolog qidirilmoqda');
  }

  Future<ActionResult> findLibrary() async {
    return _searchMaps('kutubxona', 'Kutubxona qidirilmoqda');
  }

  // Search engines for specific content
  Future<ActionResult> searchMovie(String query) async {
    final uri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent("$query film")}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: '🎬 "$query" film qidirilmoqda');
  }

  Future<ActionResult> searchBook(String query) async {
    final uri = Uri.parse('https://www.google.com/search?tbm=bks&q=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: '📚 "$query" kitob qidirilmoqda');
  }

  Future<ActionResult> searchRecipe(String query) async {
    final uri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent("$query retsept tayyorlash")}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: '🍽️ "$query" retsept qidirilmoqda');
  }

  Future<ActionResult> searchImage(String query) async {
    final uri = Uri.parse('https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: '🖼️ "$query" rasm qidirilmoqda');
  }

  Future<ActionResult> searchFlight({String? from, String? to}) async {
    final query = [if (from != null) from, if (to != null) to].join(' to ');
    final uri = Uri.parse('https://www.google.com/travel/flights?q=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: '✈️ Parvoz qidirilmoqda: $query');
  }

  // Open Uzbek popular apps
  Future<ActionResult> openTaxi({String? service}) async {
    final apps = {
      'yandex': 'ru.yandex.taxi',
      'mytaxi': 'uz.mytaxi.client',
      'uklon': 'ua.com.uklon',
    };
    final key = service?.toLowerCase() ?? 'yandex';
    final package = apps[key] ?? apps['yandex']!;
    return _launchApp(package, '${key.toUpperCase()} taksi');
  }

  Future<ActionResult> openPayme() async {
    return _launchApp('uz.dida.payme', 'Payme');
  }

  Future<ActionResult> openClick() async {
    return _launchApp('air.com.ssdsoftware.clickuz', 'Click');
  }

  Future<ActionResult> openUzum() async {
    return _launchApp('uz.uzumbank.app', 'Uzum Bank');
  }

  Future<ActionResult> openMyId() async {
    return _launchApp('uz.myid.android', 'MyID');
  }

  // Helper: search Google Maps
  Future<ActionResult> _searchMaps(String query, String message) async {
    final uri = Uri.parse('https://www.google.com/maps/search/${Uri.encodeComponent(query)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: '📍 $message');
    } catch (e) {
      return ActionResult(success: false, message: 'Xarita ochishda xato');
    }
  }

  // Helper: launch app by package
  Future<ActionResult> _launchApp(String packageName, String label) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: packageName,
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return ActionResult(success: true, message: '$label ochildi');
    } catch (e) {
      final storeUrl = Uri.parse('market://details?id=$packageName');
      try {
        if (await canLaunchUrl(storeUrl)) {
          await launchUrl(storeUrl);
          return ActionResult(success: false, message: '$label topilmadi, Play Store ochildi');
        }
      } catch (_) {}
      return ActionResult(success: false, message: '$label ilovasi topilmadi');
    }
  }
}
