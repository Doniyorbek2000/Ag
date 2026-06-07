import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

enum LegalDocument { privacyPolicy, termsOfUse }

/// Renders the static Privacy Policy / Terms of Use text. Both documents
/// describe what ADM AI collects (chat content, voice recordings processed
/// on-device, call-screening rules, contacts used only for matching) and
/// why -- required reading before granting sensitive permissions such as
/// call screening, contacts, or microphone access.
class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  String get _title => document == LegalDocument.privacyPolicy
      ? 'Maxfiylik siyosati'
      : 'Foydalanish shartlari';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Text(
            _title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final sections = document == LegalDocument.privacyPolicy
        ? _privacyPolicySections
        : _termsOfUseSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oxirgi yangilanish: 2026-06-07',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 20),
        for (final section in sections) ...[
          Text(
            section.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _LegalSection {
  final String title;
  final String body;
  const _LegalSection(this.title, this.body);
}

const _privacyPolicySections = [
  _LegalSection(
    '1. Qanday ma\'lumotlar yig\'iladi',
    'ADM AI quyidagilarni yig\'ishi mumkin: hisob ma\'lumotlari (ism, email), '
        'AI suhbatlari va ularning matni, ovozli buyruqlar (faqat matnga '
        'aylantirish uchun qurilmada qayta ishlanadi va serverga audio '
        'shaklida yuborilmaydi), buxgalteriya yozuvlari, qo\'ng\'iroq '
        'skrining qoidalari va jurnali, hamda ilova ishlatish statistikasi '
        '(kunlik so\'rovlar soni, tarif rejasi).',
  ),
  _LegalSection(
    '2. Kontaktlar va qo\'ng\'iroqlar',
    'Kontaktlar faqat "faqat tanishlardan qo\'ng\'iroq qabul qilish" '
        'funksiyasi ishlashi uchun qurilmada o\'qiladi va taqqoslanadi -- '
        'ular serverga yuborilmaydi va qurilmadan tashqariga chiqmaydi. '
        'Qo\'ng\'iroqlarni skrining qilish funksiyasi to\'liq qurilma '
        'ichida ishlaydi (Android CallScreeningService orqali).',
  ),
  _LegalSection(
    '3. Ma\'lumotlar qayerda saqlanadi',
    'Suhbat tarixi va sozlamalar qurilmangizda (mahalliy ma\'lumotlar '
        'bazasida) saqlanadi. Hisob, obuna holati va qo\'llab-quvvatlash '
        'murojaatlari ADM AI serverlarida shifrlangan holatda saqlanadi. '
        'AI javoblarini olish uchun so\'rovlar Anthropic (Claude API) '
        'serverlariga yuboriladi -- bu yerda Anthropic\'ning maxfiylik '
        'siyosati amal qiladi.',
  ),
  _LegalSection(
    '4. Ma\'lumotlardan qanday foydalaniladi',
    'Ma\'lumotlar faqat: (a) so\'ralgan xizmatni ko\'rsatish (AI javoblari, '
        'buxgalteriya hisobotlari, qo\'ng\'iroq skrining), (b) hisobingizni '
        'boshqarish va obunani tasdiqlash, (c) xizmat sifatini yaxshilash '
        'va texnik nosozliklarni bartaraf etish uchun ishlatiladi. '
        'Ma\'lumotlar uchinchi shaxslarga reklama maqsadida sotilmaydi.',
  ),
  _LegalSection(
    '5. Ruxsatlar (permissions)',
    'Mikrofon -- ovozli buyruqlar va "Hey ADM AI" uyg\'otish so\'zi uchun; '
        'Telefon -- qo\'ng\'iroq qilish va skrining uchun; Kontaktlar -- '
        'tanishlarni aniqlash uchun; Bildirishnomalar -- fonda ishlash '
        'holatini ko\'rsatish uchun. Har bir ruxsatni istalgan vaqtda '
        'tizim Sozlamalar bo\'limidan bekor qilishingiz mumkin (bu holda '
        'tegishli funksiya ishlamay qoladi).',
  ),
  _LegalSection(
    '6. Ma\'lumotlarni o\'chirish',
    'Hisobingizni va unga bog\'liq barcha ma\'lumotlarni Sozlamalar → '
        'Profil orqali yoki qo\'llab-quvvatlash xizmatiga murojaat qilib '
        'o\'chirtirishingiz mumkin. Qurilmadagi mahalliy ma\'lumotlar '
        '(suhbatlar, buxgalteriya yozuvlari) ilovani o\'chirish bilan '
        'birga butunlay yo\'qoladi.',
  ),
  _LegalSection(
    '7. Bog\'lanish',
    'Maxfiylik bo\'yicha savollaringiz bo\'lsa, ilova ichidagi '
        '"Qo\'llab-quvvatlash" bo\'limi orqali murojaat qiling.',
  ),
];

const _termsOfUseSections = [
  _LegalSection(
    '1. Xizmat tavsifi',
    'ADM AI -- sun\'iy intellekt asosidagi shaxsiy yordamchi bo\'lib, '
        'ovozli buyruqlar, ilovalarni boshqarish, buxgalteriya hisobi, '
        'qo\'ng\'iroqlarni skrining qilish va boshqa funksiyalarni taqdim '
        'etadi. Ba\'zi funksiyalar (cheksiz AI so\'rovlari, qo\'shimcha '
        'imkoniyatlar) pullik obuna asosida ishlaydi.',
  ),
  _LegalSection(
    '2. Hisob va javobgarlik',
    'Siz hisobingiz xavfsizligi va undagi barcha amallar uchun '
        'javobgarsiz. Claude API kalitini o\'zingiz kiritsangiz, undan '
        'foydalanish bilan bog\'liq xarajatlar uchun siz javobgarsiz -- '
        'ADM AI kalitni faqat sizning so\'rovlaringizni yuborish uchun '
        'ishlatadi va boshqa hech qanday maqsadda foydalanmaydi.',
  ),
  _LegalSection(
    '3. Tarif rejalari va to\'lovlar',
    'Bepul reja kuniga cheklangan miqdorda AI so\'rovlariga ruxsat '
        'beradi. Pullik obunalar (Pro, Ultra, VIP) qo\'shimcha imkoniyatlar '
        'va kengroq limitlarni ochadi. Obunalar Google Play orqali sotib '
        'olinadi va Google Play\'ning bekor qilish/qaytarish siyosatiga '
        'bo\'ysunadi.',
  ),
  _LegalSection(
    '4. Taqiqlangan foydalanish',
    'Xizmatdan: qonunga zid harakatlar uchun, boshqa shaxslarni '
        'aldash yoki ta\'qib qilish uchun, spam yoki avtomatlashtirilgan '
        'suiiste\'mol uchun foydalanish taqiqlanadi. Bunday holatlar '
        'aniqlansa, hisobingiz to\'xtatilishi mumkin.',
  ),
  _LegalSection(
    '5. Javobgarlikni cheklash',
    'AI tomonidan berilgan javoblar har doim ham 100% aniq bo\'lmasligi '
        'mumkin -- muhim qarorlar (moliyaviy, tibbiy, huquqiy) uchun '
        'mustaqil tekshiruvdan foydalaning. ADM AI dasturiy ta\'minot '
        'sifatida "qanday bo\'lsa shunday" (as-is) taqdim etiladi.',
  ),
  _LegalSection(
    '6. Shartlarning o\'zgarishi',
    'Ushbu shartlar vaqti-vaqti bilan yangilanishi mumkin. Muhim '
        'o\'zgarishlar haqida ilova ichidagi bildirishnoma orqali xabar '
        'beramiz. Yangilangan shartlardan keyin xizmatdan foydalanishni '
        'davom ettirish ularga rozilik bildirish hisoblanadi.',
  ),
];
