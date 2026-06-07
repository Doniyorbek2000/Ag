# ADM AI

Android uchun professional shaxsiy AI yordamchi ilovasi — Siri va Google Assistant darajasidagi imkoniyatlar bilan.

## Asosiy imkoniyatlar

- **AI Chat & Ovozli boshqarish** — Claude AI asosida tabiiy tilda muloqot, O'zbek/Rus/Ingliz tillarida ovozli buyruqlar
- **Telefon boshqaruvi** — qo'ng'iroq, SMS, sozlamalar (WiFi, Bluetooth, ovoz, displey)
- **Ilovalar integratsiyasi** — Telegram, WhatsApp, Instagram, YouTube, Google xizmatlari, Spotify va boshqalar
- **Call Center** — terish paneli, kontaktlar, AI yordamida qo'ng'iroq skriptlarini yaratish
- **Buxgalteriya / Moliya** — daromad va xarajatlar hisobi, kategoriyalar, grafiklar
- **Kontaktlar boshqaruvi** — qidirish, qo'ng'iroq qilish, xabar yuborish
- **Obuna tariflari** — Bepul, Pro, Ultra, VIP

## Texnologiyalar

- Flutter (Android)
- Riverpod (state management)
- Hive (lokal saqlash)
- Claude API (AI)
- speech_to_text / flutter_tts (ovozli boshqarish)
- go_router (navigatsiya)

## Loyihani ishga tushirish

```bash
flutter pub get
flutter run
```

API kalitni `Sozlamalar > AI Sozlamalar` bo'limidan kiritish mumkin (ixtiyoriy — bepul rejimda ham ishlaydi).

## Loyiha tuzilishi

```
lib/
├── main.dart                 # Kirish nuqtasi
├── theme/                    # Ilova mavzusi (rang, shrift)
├── router/                   # Navigatsiya (go_router)
├── models/                   # Ma'lumot modellari (Hive)
├── providers/                # Riverpod state notifierlar
├── services/                 # AI, ovoz, amal bajaruvchi xizmatlar
├── screens/                  # Ekranlar
└── widgets/                  # Qayta ishlatiluvchi vidjetlar
```
