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

### Obuna
- `POST /api/subscriptions/purchase` — xaridni faollashtirish (Google Play receipt)
- `GET /api/subscriptions/me` — obunalar tarixi
- `POST /api/subscriptions/cancel` — obunani bekor qilish

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
