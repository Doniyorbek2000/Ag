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

## Eslatma

`POST /api/subscriptions/purchase` da Google Play xaridini haqiqiy tasdiqlash
uchun Google Play Developer API (`purchases.subscriptions.get`) chaqiruvini
ulash kerak — hozirgi holatda token saqlanadi, lekin tashqi tekshiruv
qo'shilmagan (`TODO` belgilangan).
