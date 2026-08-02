# ✅ StockShaala — Manual Setup Checklist

Everything below is stuff **you must add yourself** — credentials, generated files, and console config that can't be committed to code. Work top to bottom.

---

## 1. 🔥 Firebase project

1. Go to <https://console.firebase.google.com> → **Add project** → name it `StockShaala`.
2. Install the FlutterFire CLI and configure (this generates `lib/firebase_options.dart`, which is intentionally **not** included):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. After it runs, open `lib/main.dart` and switch the init line to:
   ```dart
   import 'firebase_options.dart';
   ...
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

## 2. 📄 Google services config files (the "Google JSON")

These are downloaded from the Firebase console when you register each app. `flutterfire configure` usually places them for you, but verify:

- **Android** → `android/app/google-services.json`  ← **the file you mentioned**
- **iOS** → `ios/Runner/GoogleService-Info.plist`

> Add `google-services.json` to `.gitignore` — never commit it publicly.

Also confirm the Gradle plugin lines exist:
- `android/build.gradle` → `classpath 'com.google.gms:google-services:4.4.2'`
- `android/app/build.gradle` → `apply plugin: 'com.google.gms.google-services'`

## 3. 🔑 Google Sign-In — SHA fingerprints (Android)

Google Sign-In will silently fail without this.

1. Generate your SHA-1 and SHA-256:
   ```bash
   cd android && ./gradlew signingReport
   ```
   (For release, use your upload keystore.)
2. Firebase console → **Project Settings → Your Android app → Add fingerprint** → paste **both** SHA-1 and SHA-256.
3. Re-download `google-services.json` after adding fingerprints.

## 4. 👤 Enable Google as a sign-in provider

Firebase console → **Authentication → Sign-in method → Google → Enable** → set a support email → Save.

## 5. ⚙️ Firebase Remote Config (push content without an app update)

Console → **Remote Config** → add these **String** parameters (paste the JSON from `assets/data/` as the value, or leave empty to use the bundled assets as fallback):

| Key | Value |
|-----|-------|
| `lessons` | contents of `assets/data/lessons.json` |
| `quiz` | contents of `assets/data/quiz.json` |
| `concept_cards` | contents of `assets/data/concept_cards.json` |

The app reads Remote Config first, then falls back to the bundled asset, so it works even if you skip this.

## 6. 🔔 Firebase Cloud Messaging (notifications) — optional now

- Android works out of the box once Firebase is wired.
- **iOS**: upload an **APNs key** in console → Project Settings → Cloud Messaging, and enable Push Notifications + Background Modes capabilities in Xcode.

## 7. 🔄 In-app update (`in_app_update`) — IMPORTANT

This **only works for apps installed from the Play Store** (including internal testing track). It does nothing on a debug/sideloaded build — that's expected.

1. Upload at least one build to the **Play Console** (internal testing is fine).
2. To actually see the update prompt, the Play Store version must have a **higher `versionCode`** than the installed one.
3. No code change needed — `AppServices.checkForUpdate()` is already called on splash and from Profile.

## 8. ✏️ Replace the placeholders in `lib/core/constants/app_constants.dart`

| Constant | Replace with |
|----------|--------------|
| `playStoreId` | your real package, e.g. `com.bhushan.stockshaala` |
| `feedbackEmail` | the inbox you want feedback sent to |
| `privacyPolicyUrl` | your hosted privacy policy URL |

Make sure the **package name** matches everywhere: `android/app/build.gradle` (`applicationId`), Firebase console, and this constant.

## 9. 🎨 App icon & launcher name

- Drop your icon and run `flutter_launcher_icons`, or replace `android/app/src/main/res/mipmap-*/ic_launcher.png` manually.
- The logo design is in `lib/core/widgets/app_logo.dart` (CustomPaint) — export it to PNG/SVG for the launcher icon.

## 10. 🛡️ Android build config minimums

In `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 23      // Firebase Auth needs >= 21; 23 is safe
    targetSdkVersion 34
    multiDexEnabled true
}
```

## 11. 🍎 iOS extras (if shipping iOS)

- `ios/Runner/Info.plist` → add the reversed client ID URL scheme from `GoogleService-Info.plist` (for Google Sign-In).
- Minimum iOS 13.
- Add a privacy usage string only if you later add features that need it.

---

## 🧩 The 4 features you specifically asked about — where they live

| Feature | File | Notes |
|---------|------|-------|
| **App Update** | `core/services/app_services.dart` → `checkForUpdate()` | Called on splash + Profile → "Check for Update". Play Store only. |
| **Share** | `app_services.dart` → `shareApp()` | Profile → "Share App". Uses `share_plus`. |
| **Feedback** | `app_services.dart` → `sendFeedback()` | Profile → "Send Feedback". Opens email with app version pre-filled. |
| **Delete Account** | `features/profile/profile_page.dart` → `_confirmDelete()` / `_performDelete()` | **As you requested:** shows a dialog, wipes local sim data, attempts Firebase delete, then logs out to `/login`. Since there's no separate account system (Google sign-in only), the dialog explains the user can return by signing in again. |

---

## ✅ Final pre-launch checks

- [ ] `flutter analyze` is clean
- [ ] Google Sign-In works on a real device (SHA added)
- [ ] Disclaimer shows on first launch and once daily after
- [ ] Virtual buy/sell updates portfolio and persists after restart
- [ ] Reset Portfolio restores ₹1,00,000
- [ ] Delete Account clears data and returns to login
- [ ] Market data loads (test on mobile, not web — Yahoo blocks web CORS)
- [ ] Privacy policy URL is live (Play Store requires it)
- [ ] Play Store listing clearly states "educational only, not investment advice"
