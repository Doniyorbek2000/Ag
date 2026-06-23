import 'dart:math';
import 'action_executor.dart';

class FunContentService {
  static final _random = Random();

  ActionResult getQuote() {
    // 30+ motivational quotes in Uzbek
    const quotes = [
      'Ilm olish \u{2014} har bir muslim erkak va ayolning farzidir. \u{2014} Hadis',
      'Sabr \u{2014} imonning yarmi. \u{2014} Hadis',
      'Muvaffaqiyatning siri \u{2014} boshlashdir. \u{2014} Mark Tven',
      'Kelajak bugun nima qilayotganingizga bog\'liq. \u{2014} Mahatma Gandi',
      'Ilm orttirish uchun hech qachon kech emas. \u{2014} Alisher Navoiy',
      'Har bir katta sayohat bitta qadam bilan boshlanadi. \u{2014} Lao Tzu',
      'Qiyinchilik \u{2014} bu imkoniyat kiyimida keladi. \u{2014} Albert Eynshteyn',
      'O\'zingizga ishoning, siz hech narsa qilolmaydi. \u{2014} Napoleon Bonapart',
      'Eng yaxshi vaqt \u{2014} hozir. \u{2014} Konfutsiy',
      'Bilim \u{2014} kuch. \u{2014} Frensiz Bekon',
      'Mehnat \u{2014} boylikning kaliti. \u{2014} Xalq maqoli',
      'Yaxshilik qil, daryoga tashla. \u{2014} O\'zbek maqoli',
      'O\'rganish juda katta boylik. \u{2014} Muso Xorazmiy',
      'Hayot \u{2014} bu kurash, kurashmasang yashay olmaysan. \u{2014} Bob Marli',
      'Xatolik qilmaslik uchun hech narsa qilmaslik kerak. \u{2014} Albert Eynshteyn',
      'Bugun qilolgan ishingni ertaga qoldirma. \u{2014} Benjamin Franklin',
      'Tirishqoqlik \u{2014} muvaffaqiyatning onasi. \u{2014} Xalq maqoli',
      'Kitob \u{2014} eng yaxshi do\'st. \u{2014} Xalq maqoli',
      'Bilimli kishi \u{2014} kuchli kishi. \u{2014} Xalq maqoli',
      'Yaxshi so\'z \u{2014} yarim rizq. \u{2014} Hadis',
      'Sabr bilan osmon ham teshiladi. \u{2014} O\'zbek maqoli',
      'O\'qigan bilar, o\'qimagan \u{2014} balar. \u{2014} O\'zbek maqoli',
      'Inson o\'z taqdirini o\'zi yaratadi. \u{2014} Xalq donoligi',
      'Har bir qorong\'u tunning yorug\' tongi bor. \u{2014} O\'zbek maqoli',
      'Darg\'azab bo\'lma, jahannam olovidan saqlaning. \u{2014} Hadis',
      'Eng yaxshi inson \u{2014} odamlarga foydasi tegadiganidir. \u{2014} Hadis',
      'Agar siz tushlarni ko\'rsangiz, ularni haqiqatga aylantiring. \u{2014} Uolt Disney',
      'Hech qachon taslim bo\'lmang! \u{2014} Uinston Cherchill',
      'Yuragingiz aytgan ishni qiling. \u{2014} Stiv Jobs',
      'Dunyo \u{2014} kitob, sayohat qilmaganlar faqat bir sahifasini o\'qiydi. \u{2014} Avliyo Avgustin',
    ];
    return ActionResult(
        success: true,
        message: '\u{1F4AC} ${quotes[_random.nextInt(quotes.length)]}');
  }

  // 20+ jokes in Uzbek
  ActionResult getJoke() {
    const jokes = [
      'Nega dasturchilar qorong\'uda ishlashni yoqtiradi? Chunki yorug\'lik bug\'larni jalb qiladi! \u{1F41B}',
      'Doktor: "Siz juda ko\'p kompyuter oldida o\'tirasiz." Bemor: "Buni qanday bildingiz?" Doktor: "Siz stulga emas, kresloga o\'tirdingiz."',
      'Ota: "Bolam, yaxshi o\'qi, katta bo\'lib nima bo\'lasan?" Bola: "Katta bo\'laman!"',
      'Qo\'shni: "Shovqin qilmang, devorlar yupqa!" Javob: "Kechirasiz, devorlar qalin bo\'lganda ham eshitilardi!"',
      'WiFi bor joyda \u{2014} vatan shu yerda. \u{1F4F6}',
      'Ustoz: "Sen arifmetikani bilasanmi?" Talaba: "Ha, 3+3=8." Ustoz: "Yo\'q, 6." Talaba: "Yaqinlashtim-ku!"',
      'Bemor: "Doktor, men ko\'zga ko\'rinmayman!" Doktor: "Keyingi bemor!"',
      'Matematik: "Sen bilasanmi, butun olam raqamlardan iborat?" Xotini: "Ayniqsa, oyligingning raqami juda kichik!"',
      'Nega telefon hech qachon yolg\'on gapirmaydi? Chunki uning yuzida hamisha haqiqat ko\'rinadi \u{2014} battery 1%! \u{1FAAB}',
      'Dasturchi xotiniga: "if (sevaman) { uylan(); } else { console.log(\'keyinroq\'); }"',
      'Farzand: "Ota, nega dengiz suvi sho\'r?" Ota: "Chunki unda juda ko\'p baliqlar ter to\'kadi!" \u{1F41F}',
      'Nega kitob kutubxonadan qochdi? Chunki u "ochiq kitob" bo\'lgisi keldi! \u{1F4D6}',
      'Doktor: "Sizga vitamindagi yetishmovchilik bor." Bemor: "Xo\'sh, qaysi vitamin?" Doktor: "D... vitamin D... eng yaxshi vitamin \u{2014} dam olish!"',
      'Qanday qilib dasturchi bayramni nishonlaydi? Bug\'larni tuzatib! \u{1F389}',
      'Nima uchun dasturchi hammomda uzoq o\'tiradi? Chunki u "loop"dan chiqolmayapti! \u{1F504}',
      'Ota: "Bolam, matematikadan nechchi oldingiz?" Bola: "1 dan 5 gacha raqamlardan birini!"',
      'Nega paxtakor kuchli? Chunki uning ichida "paxta" bor \u{2014} yumshoq lekin chidamli! \u{26BD}',
      'Xotin: "Telefon bill juda katta!" Er: "Bu mening emas, sening WhatsApp guruhlaring!"',
      'IT mutaxassis: "Kompyuterni o\'chirib yoqdingizmi?" Mijoz: "Ha, 3 marta!" IT: "Nima uchun 3 marta?!" Mijoz: "Har safar yordam so\'raganingizda shuni deysiz-da!"',
      'Nega dasturchilar tabiatni yoqtiradi? Chunki u "bug"siz! \u{1F33F}',
    ];
    return ActionResult(
        success: true,
        message: '\u{1F604} ${jokes[_random.nextInt(jokes.length)]}');
  }

  ActionResult getFact() {
    const facts = [
      '\u{1F9E0} Inson miyasi kuniga 70 000 ga yaqin fikr ishlab chiqaradi.',
      '\u{1F30D} Yer yuzi 71% suvdan iborat, lekin ichimlik suvga yaroqli qismi atigi 1%.',
      '\u{1F419} Sakkizoyoqning uchta yuragi va ko\'k qoni bor.',
      '\u{1F319} Oy Yerdan har yili 3.8 sm uzoqlashmoqda.',
      '\u{1F40B} Ko\'k kit \u{2014} Yer tarixidagi eng katta hayvon, uning yuragi mashina hajmida.',
      '\u{1F9EC} Inson DNK si 99.9% boshqa barcha odamlarnikiga o\'xshash.',
      '\u{1F3D4}\u{FE0F} Everest cho\'qqisi har yili 4 mm ko\'tarilmoqda.',
      '\u{26A1} Chaqmoq harorati Quyosh sirtidan 5 baravar issiq.',
      '\u{1F41C} Chumolilar o\'z vaznidan 50 marta og\'ir yukni ko\'taradi.',
      '\u{1F4F1} Birinchi SMS 1992-yilda "Merry Christmas" matni bilan yuborilgan.',
      '\u{1F30A} Dunyo okeanining 80% dan ko\'pi hali o\'rganilmagan.',
      '\u{1F9CA} Antarktida muzligi Yer yuzidagi chuchuk suvning 70% ni saqlaydi.',
      '\u{1F988} Akulalar dinozavrlardan oldin paydo bo\'lgan \u{2014} 400 million yil avval.',
      '\u{1F333} Amazonka o\'rmoni Yer kislorodining 20% ini ishlab chiqaradi.',
      '\u{1F52C} Inson tanasida 37.2 trillion hujayra mavjud.',
      '\u{1F41D} Asalari 1 kg asal uchun 4 million gulga qo\'nadi.',
      '\u{1F30D} O\'zbekiston Markaziy Osiyodagi eng katta aholili davlat.',
      '\u{1F54C} Samarqand \u{2014} dunyodagi eng qadimiy shaharlardan biri (2750+ yil).',
      '\u{1F4DA} Al-Xorazmiy \u{2014} algebra fanining asoschisi, IX asr.',
      '\u{1F3DB}\u{FE0F} Ibn Sino 450 dan ortiq ilmiy asar yozgan.',
      '\u{1F33E} O\'zbekiston dunyoda paxta eksporti bo\'yicha 6-o\'rinda.',
      '\u{1F9EE} Nol (0) raqamini hind matematiklariga va uni Yevropa amaliyotiga Al-Xorazmiy kiritgan.',
      '\u{1F680} Xalqaro kosmik stansiya Yer atrofida 90 daqiqada bir marta aylanadi.',
      '\u{1F48E} Olmos \u{2014} Yerdagi eng qattiq tabiiy modda.',
      '\u{1F418} Fillar bir-birlarini 50 km masofadan sezishi mumkin.',
    ];
    return ActionResult(
        success: true, message: facts[_random.nextInt(facts.length)]);
  }

  ActionResult getMotivation() {
    // ~15 motivational messages
    const msgs = [
      '\u{1F4AA} Bugun siz kechagingizdagi o\'zingizdan yaxshiroqsiz!',
      '\u{1F31F} Har bir yangi kun \u{2014} yangi imkoniyat!',
      '\u{1F525} Qiyinchiliklardan qo\'rqmang, ular sizni kuchliroq qiladi!',
      '\u{1F680} Muvaffaqiyat \u{2014} bu harakat qilishdir. Harakatsizlik \u{2014} muvaffaqiyatsizlik.',
      '\u{1F3AF} Katta maqsadlaringiz bo\'lsin, kichik qadamlar bilan yuring!',
      '\u{1F48E} Olmos \u{2014} bu bosim ostida qolgan ko\'mir.',
      '\u{1F308} Har bir yomg\'irdan keyin kamalak paydo bo\'ladi.',
      '\u{2B50} Siz noyobsiz! Butun dunyoda sizga o\'xshagan boshqa hech kim yo\'q.',
      '\u{1F3C6} G\'olib bo\'lish uchun avval raqobat qilishni o\'rganing \u{2014} o\'zingiz bilan!',
      '\u{1F33A} Bugun yaxshilik qiling \u{2014} u sizga qaytib keladi.',
      '\u{1F4C8} Muvaffaqiyat yo\'li \u{2014} har kuni 1% yaxshilanish.',
      '\u{1F985} Baland parvoz qiling, lekin ildizlaringizni unutmang.',
      '\u{1F4A1} G\'oya bor \u{2014} yo\'l bor. Ishonch bor \u{2014} kuch bor.',
      '\u{1F393} O\'rganish \u{2014} umr bo\'yi davom etadigan sayohat.',
      '\u{1F33B} Pessimist shamoldan shikoyat qiladi, optimist uni kutadi, realist yelkanini to\'g\'rilaydi.',
    ];
    return ActionResult(
        success: true, message: msgs[_random.nextInt(msgs.length)]);
  }

  ActionResult getProverb() {
    const proverbs = [
      '\u{1F4DC} Mehnat qilsang eminsan, mehnat qilmasang xazinasan. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Birlashgan o\'zar, birlashmagan to\'zar. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Ona yurtim \u{2014} oltin beshigim. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Tilni bilgan \u{2014} elni biladi. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Ot odam bilan, odam \u{2014} ot bilan. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Bilim \u{2014} ulug\' boylik. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} O\'zingdan katta bilan kengash, o\'zingdan kichik bilan maslahat. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Yaxshi do\'st \u{2014} yomon kunning yo\'ldoshi. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} So\'z kumush bo\'lsa, sukut \u{2014} oltin. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Qo\'rqqanning ko\'zi katta. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Ozgina bilimdan ko\'ra, ko\'p mehnat yaxshi. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Harakat \u{2014} baraka. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Suvdan baland joyda turmaydi. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Besh barmoq teng emas. \u{2014} O\'zbek maqoli',
      '\u{1F4DC} Odam ko\'rki \u{2014} bilim, yer ko\'rki \u{2014} ekin. \u{2014} O\'zbek maqoli',
    ];
    return ActionResult(
        success: true,
        message: proverbs[_random.nextInt(proverbs.length)]);
  }

  ActionResult getRiddle() {
    const riddles = [
      '\u{1F914} Topishmoq: Ot minadi, tosh yeydi? \u{2014} Javob: Tegirmon',
      '\u{1F914} Topishmoq: Boshi bor \u{2014} miyasi yo\'q, ko\'zi bor \u{2014} ko\'rmaydi? \u{2014} Javob: Igna',
      '\u{1F914} Topishmoq: Qo\'li yo\'q \u{2014} eshikni ochadi? \u{2014} Javob: Shamol',
      '\u{1F914} Topishmoq: Tilsiz so\'zlaydi, quloqsiz eshitadi? \u{2014} Javob: Kitob',
      '\u{1F914} Topishmoq: Bir otning ikki bolasi, biri qora, biri oq? \u{2014} Javob: Kecha va kunduz',
      '\u{1F914} Topishmoq: Yerda yotadi \u{2014} oyoq bilan bosib bo\'lmaydi? \u{2014} Javob: Soya',
      '\u{1F914} Topishmoq: Oqar-oqar, oqib bo\'lmas? \u{2014} Javob: Vaqt',
      '\u{1F914} Topishmoq: Boshi bor \u{2014} tomi yo\'q, oyog\'i bor \u{2014} etiqi yo\'q? \u{2014} Javob: Ko\'cha',
      '\u{1F914} Topishmoq: Kim ikki marta tug\'iladi? \u{2014} Javob: Parranda (tuxum \u{2192} jo\'ja)',
      '\u{1F914} Topishmoq: Qorni bor \u{2014} och emas, orqasi bor \u{2014} yuk ko\'tarmaydi? \u{2014} Javob: Rubob',
    ];
    return ActionResult(
        success: true,
        message: riddles[_random.nextInt(riddles.length)]);
  }
}
