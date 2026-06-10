# ADM AI Backend

Foydalanuvchilar, obunalar va admin panel uchun REST API server (Node.js + Express + SQLite).

## Ishga tushirish

```bash
cd backend
cp .env.example .env   # JWT_SECRET va admin parolini o'zgartiring
npm install
npm start
```

Server `http://localhost:4000` da ishga tushadi. Birinchi marta ishga tushganda
`.env`dagi `ADMIN_BOOTSTRAP_EMAIL` / `ADMIN_BOOTSTRAP_PASSWORD` bilan admin
hisobi avtomatik yaratiladi — production'da darhol parolni almashtiring.

## API yo'nalishlari

### Autentifikatsiya
- `POST /api/auth/register` — ro'yxatdan o'tish
- `POST /api/auth/login` — kirish (JWT token qaytaradi)
- `GET /api/auth/me` — joriy foydalanuvchi

### Foydalanuvchi
- `GET /api/users/me/usage` — kunlik AI so'rovlar holati
- `POST /api/users/me/usage/increment` — so'rov sonini oshirish
- `PATCH /api/users/me` — profilni yangilash
- `POST /api/users/me/tickets` — qo'llab-quvvatlash murojaati yuborish
- `GET /api/users/me/tickets` — murojaatlar tarixi
- `DELETE /api/users/me` — hisobni va unga tegishli barcha ma'lumotlarni butunlay o'chirish (Google Play hisobni o'chirish talabi)

### Obuna
- `POST /api/subscriptions/purchase` — xaridni faollashtirish (Google Play receipt)
- `GET /api/subscriptions/me` — obunalar tarixi
- `POST /api/subscriptions/cancel` — obunani bekor qilish

### To'lovlar (Click / Payme)
- `POST /api/payments/click/create` — Click checkout havolasini yaratish
- `POST /api/payments/click/webhook` — Click Prepare/Complete callback'i (Click chaqiradi)
- `POST /api/payments/payme/create` — Payme checkout havolasini yaratish
- `POST /api/payments/payme/webhook` — Payme JSON-RPC callback'i (Payme chaqiradi)

### Admin panel (faqat `role = admin`)
- `GET /api/admin/stats` — umumiy statistika (foydalanuvchilar, daromad, grafiklar)
- `GET /api/admin/users` — foydalanuvchilar ro'yxati (qidiruv, filtrlash, sahifalash)
- `GET /api/admin/users/:id` — foydalanuvchi tafsilotlari
- `PATCH /api/admin/users/:id` — tarif/rol/holatni o'zgartirish
- `DELETE /api/admin/users/:id` — foydalanuvchini o'chirish
- `GET /api/admin/subscriptions` — barcha obunalar
- `GET /api/admin/tickets` — qo'llab-quvvatlash murojaatlari
- `PATCH /api/admin/tickets/:id` — murojaat holatini yangilash
- `GET /api/admin/broadcasts` — yuborilgan xabarnomalar
- `POST /api/admin/broadcasts` — barcha/tarif bo'yicha xabarnoma yuborish

## Google Play xaridlarini server tomonida tasdiqlash

`POST /api/subscriptions/purchase` endi Google Play Developer API
(`purchases.subscriptions.get`, `src/services/googlePlay.js`) orqali haqiqiy
tekshiruvni qo'llab-quvvatlaydi: token yaroqsiz yoki to'lov holati faol
bo'lmasa, faollashtirish `402` bilan rad etiladi.

Buni yoqish uchun (faqat Play Console hisobi egasi bajara oladigan qadamlar):

1. Google Cloud Console'da loyihangizga bog'langan **service account**
   yarating va undan JSON kalit faylini yuklab oling.
2. Play Console → **Setup → API access** bo'limida shu service account'ga
   "View financial data" (yoki "Manage orders and subscriptions") huquqini
   bering va ilova bilan bog'lang.
3. JSON kalit faylini serverga joylashtiring va `.env`da ko'rsating:
   ```
   GOOGLE_PLAY_PACKAGE_NAME=com.admai.app
   GOOGLE_PLAY_SERVICE_ACCOUNT_KEY=./google-play-service-account.json
   ```
4. Serverni qayta ishga tushiring — `googlePlay.isConfigured()` `true`
   qaytarganda barcha xaridlar avtomatik ravishda Google Play API orqali
   tekshiriladi (muddati ham `expiryTimeMillis`dan olinadi).

Bu o'zgaruvchilar sozlanmagan bo'lsa, server ogohlantirish chiqaradi va
mijoz yuborgan kvitansiyaga ishonib faollashtirishni davom ettiradi (joriy
xulq-atvor) — chunki bu kalitni faqat hisob egasi yarata oladi va undan
tashqarida ta'minlab bo'lmaydi.

## Click va Payme orqali to'lov qabul qilish

`/api/payments/*` Click va Payme — O'zbekistondagi eng ko'p ishlatiladigan
to'lov tizimlari — orqali obuna sotib olishni qo'llab-quvvatlaydi (Google
Play billing'ga muqobil/qo'shimcha sifatida, ayniqsa raqamli mahsulot uchun
Play Store komissiyasidan qochish kerak bo'lganda foydali). Ishlashi uchun
**faqat tadbirkorlik/merchant hisobi egasi yarata oladigan** hisob va kalitlar
kerak:

### Click
1. [merchant.click.uz](https://merchant.click.uz) saytida ro'yxatdan o'ting
   va "Shop API" xizmatini ulang — sizga `SERVICE_ID`, `MERCHANT_ID` va
   `SECRET_KEY` beriladi.
2. Click kabinetida webhook manzilini
   `https://<sizning-domeningiz>/api/payments/click/webhook` qilib sozlang.
3. `.env`ga qo'shing:
   ```
   CLICK_SERVICE_ID=...
   CLICK_MERCHANT_ID=...
   CLICK_SECRET_KEY=...
   ```

### Payme
1. [business.paycom.uz](https://business.paycom.uz) saytida ro'yxatdan
   o'ting va ilova uchun kassa (cash register) yarating — sizga
   `MERCHANT_ID` va maxfiy `KEY` beriladi.
2. Payme kabinetida webhook (Merchant API endpoint) manzilini
   `https://<sizning-domeningiz>/api/payments/payme/webhook` qilib sozlang.
3. `.env`ga qo'shing:
   ```
   PAYME_MERCHANT_ID=...
   PAYME_KEY=...
   ```

### Ishlash tartibi
1. Ilova `POST /api/payments/click/create` yoki `/api/payments/payme/create`
   chaqiradi → mahalliy `payments` jadvalida `pending` yozuv yaratiladi va
   checkout havolasi qaytariladi (`url_launcher` orqali ochiladi).
2. Foydalanuvchi to'lovni yakunlagach, Click/Payme webhook orqali serverga
   qaytadi — imzo/avtorizatsiya tekshiriladi (`services/click.js`,
   `services/payme.js`), keyin `payments` yozuvi yangilanadi va muvaffaqiyatli
   to'lovda obuna avtomatik faollashtiriladi (`subscriptions` jadvaliga
   yangi yozuv + foydalanuvchi tarifi yangilanadi).

`CLICK_SECRET_KEY`/`PAYME_KEY` sozlanmagan bo'lsa, `/api/payments/*`
`503 "sozlanmagan"` bilan javob beradi — hech qachon tasdiqlanmagan to'lovni
"ishonib" faollashtirmaydi (Google Play oqimidan farqli, chunki bu yerda
pul to'g'ridan-to'g'ri va tasdiqlanmasdan faollashtirish jiddiy xavf
tug'diradi).

## Production'ga joylashtirish (Docker)

Backend Docker konteynerida ishga tushirish uchun tayyor:

```bash
cd backend
cp .env.example .env   # JWT_SECRET, ADMIN_BOOTSTRAP_PASSWORD va h.k. ni to'ldiring
docker compose up -d --build
```

Bu nima qiladi:
- `Dockerfile` — Node 22 asosida konteyner qurib, `better-sqlite3`ning
  native qismini build vaqtida kompilyatsiya qiladi
- `docker-compose.yml` — konteynerni ishga tushiradi, `.env`dagi maxfiy
  qiymatlarni o'tkazadi va SQLite fayli uchun **named volume** (`admai-data`)
  biriktiradi — konteyner qayta qurilganda yoki yangilanganda ma'lumotlar
  bazasi saqlanib qoladi
- O'rnatilgan **healthcheck** — `GET /health` orqali konteyner holatini
  kuzatadi (`docker compose ps` da `healthy`/`unhealthy` ko'rinadi)

Konteyner loglarini kuzatish: `docker compose logs -f api`

## Monitoring va abuse-kuzatuv

Har bir HTTP so'rov `requestLogger` middleware orqali bitta JSON qatorida
`stdout`ga yoziladi (`{ts, method, path, status, durationMs, ip, userId,
level}`) — bu Docker/`journald`/har qanday log agregatori (Loki, ELK,
CloudWatch va h.k.) bilan to'g'ridan-to'g'ri ishlaydi, qo'shimcha
sozlashsiz. `level: "error"` — 5xx, `level: "warn"` — 4xx va rate-limit
hodisalarini bildiradi.

Rate-limit chegaralariga urilgan so'rovlar alohida `event:
"rate_limit_exceeded"` yozuvi sifatida `console.warn`ga chiqariladi —
IP va foydalanuvchi ID bilan birga, shubhali (bruteforce/abuse) trafikni
log orqali kuzatish uchun.

Joriy chegaralar (`src/app.js`):
- Umumiy `/api/*`: 15 daqiqada 300 so'rov
- `/api/auth/login`, `/api/auth/register`: 15 daqiqada 20 urinish
- `/api/users/me/usage/increment`: 1 daqiqada 30 so'rov

Production uchun tavsiya: log oqimini Grafana Loki yoki shunga o'xshash
xizmatga yo'naltiring va `event: "rate_limit_exceeded"` bo'yicha alert
(masalan, bitta IP'dan 10 daqiqada 5+ hodisa) sozlang.
