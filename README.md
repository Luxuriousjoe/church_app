# ✝️ Grace Church Media App — Full Stack Blueprint

A complete Flutter + Node.js church media application for capturing, uploading, and viewing photos, videos, and sermon audio — integrated with YouTube and Telegram.

---

## 📁 Project Structure

```
church_app/
├── flutter/          # Flutter mobile app (iOS + Android)
├── backend/          # Node.js + Express REST API
└── database/         # MySQL schema (Aiven)
```

---

## 🚀 Quick Start

### 1. Database Setup (Aiven MySQL)

1. Create a free MySQL cluster at [aiven.io](https://aiven.io)
2. Copy the connection credentials
3. Run the schema:

```bash
mysql -h <host> -P <port> -u <user> -p <database> < database/schema.sql
```

---

### 2. Backend Setup (Node.js)

```bash
cd backend
npm install
cp .env.example .env
# Fill in all values in .env
npm run dev        # Development
npm start          # Production
```

**Required `.env` values:**
| Key | Description |
|-----|-------------|
| `DB_HOST` | Aiven MySQL host |
| `DB_USER` / `DB_PASSWORD` | Database credentials |
| `JWT_SECRET` | Random secret string (min 32 chars) |
| `YOUTUBE_CLIENT_ID` | From Google Cloud Console |
| `YOUTUBE_CLIENT_SECRET` | From Google Cloud Console |
| `YOUTUBE_REFRESH_TOKEN` | OAuth refresh token (see below) |
| `TELEGRAM_BOT_TOKEN` | From @BotFather |
| `TELEGRAM_CHANNEL_ID` | Channel ID (e.g. @graceChurchMedia) |

---

### 3. YouTube OAuth2 Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **YouTube Data API v3**
3. Create OAuth2 credentials (Web Application)
4. Add redirect URI: `https://your-backend.onrender.com/auth/youtube/callback`
5. Use the OAuth Playground or a one-time script to get a **refresh token**:

```js
// One-time script to get refresh token
const { google } = require('googleapis');
const oauth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
// Generate auth URL → visit it → exchange code for refresh token
const url = oauth2Client.generateAuthUrl({ access_type: 'offline', scope: ['https://www.googleapis.com/auth/youtube.upload'] });
console.log(url);
```

---

### 4. Telegram Bot Setup

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Create a new bot → copy the **bot token**
3. Create a public channel
4. Add your bot as **Administrator** with post permissions
5. Get the channel ID (use `@channelusername` or numeric `-100...` ID)

---

### 5. Flutter App Setup

```bash
cd flutter
flutter pub get

# Update lib/constants/app_constants.dart:
# Change baseUrl to your Render.com backend URL
```

**Add fonts** (download from Google Fonts):
```
flutter/assets/fonts/
├── Cinzel-Regular.ttf
├── Cinzel-Bold.ttf
├── Lato-Regular.ttf
├── Lato-Light.ttf
└── Lato-Bold.ttf
```

**Create asset directories:**
```bash
mkdir -p flutter/assets/{images,animations,fonts}
```

**Run the app:**
```bash
flutter run                    # Debug
flutter build apk --release    # Android release
flutter build ios --release    # iOS release
```

---

### 6. Deploy Backend to Render.com

1. Push code to GitHub
2. Connect repo to [Render.com](https://render.com)
3. Set all environment variables in the Render dashboard
4. Deploy → get your public URL
5. Update `AppConstants.baseUrl` in Flutter with the Render URL

---

## 🏗️ Architecture

```
[Flutter App]
    ↓ HTTPS REST API
[Node.js / Express — Render.com]
    ↓ MySQL pool
[Aiven MySQL Database]
    ↓ External APIs
[YouTube Data API v3] + [Telegram Bot API]
```

---

## 👥 User Roles

| Feature | Regular User | Admin |
|---------|-------------|-------|
| View media library | ✅ | ✅ |
| Play videos / audio | ✅ | ✅ |
| Search media | ✅ | ✅ |
| Capture photos/videos | ❌ | ✅ |
| Record audio | ❌ | ✅ |
| Upload to YouTube & Telegram | ❌ | ✅ |
| View upload queue | ❌ | ✅ |
| Manage users | ❌ | ✅ |
| View activity logs | ❌ | ✅ |
| Dashboard stats | ❌ | ✅ |

---

## 📱 Flutter Screens

| Screen | Route | Access |
|--------|-------|--------|
| Splash | `/splash` | All |
| Login | `/login` | All |
| Home | `/` | Authenticated |
| Media Library | `/library` | Authenticated |
| Media Detail | `/media/:id` | Authenticated |
| Capture | `/capture` | Admin only |
| Upload Queue | `/queue` | Admin only |
| Settings | `/settings` | Authenticated |

---

## 🔌 API Endpoints

### Auth
```
POST   /api/auth/login           → Login
POST   /api/auth/refresh         → Refresh token
POST   /api/auth/logout          → Logout
GET    /api/auth/me              → Get current user
PUT    /api/auth/change-password → Change password
```

### Media
```
GET    /api/media                → List media (paginated, filterable)
GET    /api/media/:id            → Get media by ID
POST   /api/media                → Create media entry [Admin]
PUT    /api/media/:id            → Update media [Admin]
DELETE /api/media/:id            → Delete media [Admin]
GET    /api/media/admin/queue    → Get admin's media queue [Admin]
```

### Uploads
```
GET    /api/uploads              → Get upload queue [Admin]
PATCH  /api/uploads/:id/status   → Update upload status [Admin]
POST   /api/uploads/:id/trigger  → Trigger upload [Admin]
```

### Admin
```
GET    /api/admin/stats          → Dashboard stats [Admin]
GET    /api/admin/users          → List all users [Admin]
POST   /api/admin/users          → Create user [Admin]
POST   /api/admin/admins         → Create admin [Admin]
PATCH  /api/admin/users/:id/toggle → Toggle user active [Admin]
GET    /api/admin/logs           → Activity logs [Admin]
```

---

## 🎨 Design System

- **Primary Font:** Cinzel (headings — sacred/classical feel)
- **Body Font:** Lato (clean, readable)
- **Primary Color:** Deep Midnight Navy `#0D1B2A`
- **Accent:** Sacred Gold `#D4AF37`
- **Theme:** Dark, reverent, inspired by sacred architecture

---

## 🔒 Security Checklist

- [x] JWT access tokens (7 day expiry)
- [x] Refresh tokens with rotation (30 day expiry)
- [x] bcrypt password hashing (12 rounds)
- [x] Helmet.js security headers
- [x] Rate limiting (100 req / 15 min)
- [x] CORS configured
- [x] Admin role middleware
- [x] Flutter Secure Storage for tokens
- [x] SSL for Aiven database connection
- [ ] Enable HTTPS redirect on Render (automatic)
- [ ] Set strong JWT_SECRET in production

---

## 🐛 Troubleshooting

**"Database connection failed"**
→ Check Aiven firewall rules — add your Render.com IP or allow all (0.0.0.0/0) for testing.

**YouTube upload fails**
→ Refresh token may have expired. Re-run the OAuth flow to get a new one.

**Telegram "chat not found"**
→ Ensure the bot is an admin of the channel. Use numeric ID `-100xxxxxxxxxx` format.

**Flutter "connection refused"**
→ Update `AppConstants.baseUrl` — use `http://10.0.2.2:5000/api` for Android emulator.

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x + Riverpod + go_router |
| Backend | Node.js 18+ + Express.js |
| Database | MySQL 8 (Aiven) |
| Hosting | Render.com |
| Video | YouTube Data API v3 + OAuth2 |
| Messaging | Telegram Bot API |
| Auth | JWT + bcrypt |
| Storage | Flutter Secure Storage |
| Background | Workmanager (Flutter) + node-cron (backend) |

---

*Made with 🙏 for Grace Church Media Ministry*
