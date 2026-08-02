# 📈 StockShaala — शेयर बाज़ार की पाठशाला

An **educational** Indian stock-market learning app for beginners. Hindi + English, free-tier stack, fully SEBI-compliant (educational only — **no tips, no advice**).

> ⚠️ StockShaala is **not** a SEBI-registered Investment Advisor. All market data and the virtual portfolio are for **educational and simulation purposes only**.

---

## ✨ Features

- **Google Sign-In only** (no separate account creation)
- **Learning modules** — lessons by category (Basics, Technical, Fundamental, F&O)
- **Concept Cards** — swipeable bite-sized concepts
- **Daily Challenge** — one MCQ per day (+XP)
- **Quiz** — 8-question quizzes with explanations
- **Virtual Trading** — ₹1,00,000 virtual cash, real (delayed) NSE prices via Yahoo Finance, fully local
- **Market** — sector heatmap + top gainers
- **Streaks & XP** — Duolingo-style, all on-device
- **Badges & levels**
- **Disclaimer system** — full-screen on first launch + daily reminder bottom-sheet
- **Profile** — App Update, Share, Feedback, Rate, Reset Portfolio, Delete Account, Sign Out

## 🏗️ Architecture

Clean Architecture + GetIt DI + GoRouter. State via `setState` for screens (lightweight) — swap to BLoC where you want.

```
lib/
├── core/
│   ├── constants/      app_constants, stock_universe
│   ├── di/             injection (GetIt)
│   ├── router/         app_router (GoRouter)
│   ├── services/       auth, market_api (Yahoo), local_db (sqflite),
│   │                   progress (streak/XP), content, disclaimer, app_services
│   ├── theme/          colors, theme
│   ├── utils/          formatters (INR)
│   └── widgets/        shared widgets, app_logo (CustomPaint)
├── data/models/        quote, holding, transaction, lesson, quiz, concept_card
└── features/
    ├── splash/ disclaimer/ onboarding/ auth/
    ├── home/ learn/ market/ quiz/
    ├── simulation/     portfolio_repository, portfolio_page, stock_detail_page
    └── profile/
```

## 💸 Cost model (all free-tier)

- **Firebase**: Auth, Remote Config, FCM — free Spark plan is plenty
- **Market data**: Yahoo Finance unofficial endpoint — no key, pull-to-refresh (not websocket)
- **All simulation/progress data**: local SQLite + SharedPreferences — zero backend cost, works offline

## 🚀 Getting Started

```bash
flutter pub get
flutterfire configure        # generates lib/firebase_options.dart
flutter run
```

See **SETUP_CHECKLIST.md** for everything you must add manually (Google JSON, signing, etc.).
