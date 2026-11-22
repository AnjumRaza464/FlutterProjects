# Cassia Grower — commands & update cheat sheet

Run every command from the project folder:
`E:\FlutterProjects\cassia_grower`

---

## ⭐ The golden rule

- **Data changes = automatic.** Adding/editing products, flipping "Available",
  handling orders — done in the admin panel, live in seconds. **No commands.**
- **Code changes = you must re-deploy** the part you changed (see below).

---

## 1. Everyday tasks — NO commands needed

Do these in the **admin panel** (the website). They update the farmer app
instantly:

- Add / edit / delete a product
- Turn a product **Available** on/off
- Change sort order, pack size, image, etc.
- View and handle **orders**

---

## 2. Updating the ADMIN PANEL (website)

**First time only** — set up hosting (choose `build/web` as the public folder,
single-page app = **Yes**, do **not** overwrite index.html):

```powershell
firebase init hosting
```

**Every time you change the admin code:**

```powershell
flutter build web -t lib/admin/main_admin.dart
firebase deploy --only hosting
```

Everyone opening the link sees the new version immediately.

---

## 3. Updating the FARMER APP (Android APK)

**Build the installable file:**

```powershell
flutter build apk --release
```

It lands at: `build\app\outputs\flutter-apk\app-release.apk`

**Then give farmers the new version:**

- **Shared APK** (WhatsApp / download link): each farmer must re-install it.
- **Google Play Store** (recommended): upload a new version and Play updates
  everyone automatically. For Play, build a bundle instead:

```powershell
flutter build appbundle
```

> ⚠️ Farmers do **not** get app code changes until they install the new
> version (automatic on Play Store, manual if you share the APK).

---

## 4. Updating the AI features (Crop Doctor + Ask Cassia)

These run as Cloud Functions. Re-deploy after any change to
`functions/src/index.ts`:

```powershell
firebase deploy --only functions
```

Requirements (one-time):
- **Blaze plan** enabled on the `cassia-seed` project (Functions need it).
- OpenAI key stored as a secret (paste the `sk-...` key when asked):

```powershell
firebase functions:secrets:set OPENAI_API_KEY
```

- The AI **model** is one line in `functions/src/index.ts`:
  `const MODEL = "gpt-4o-mini";` — change it for more accuracy/less cost, then
  re-deploy.

---

## 5. Updating SECURITY RULES

After editing `firestore.rules` or `storage.rules`:

```powershell
firebase deploy --only firestore:rules
firebase deploy --only storage
```

(Storage rules only deploy after you've turned on Cloud Storage in the Firebase
console: Build → Storage → Get Started.)

---

## 6. Testing on your own computer (does NOT affect the live versions)

- Admin panel in a browser:
  ```powershell
  flutter run -d chrome -t lib/admin/main_admin.dart
  ```
- Farmer app on a connected phone/emulator:
  ```powershell
  flutter run
  ```

Changes you make while this is running reload instantly **on your screen only**.
The live website / installed app change only when you build + deploy/distribute
(sections 2–5).

---

## Quick "what do I run?" table

| I changed… | Command(s) to run | Who sees it, when |
|---|---|---|
| A product / order (in the panel) | *(nothing)* | Everyone, instantly |
| Admin panel code | `flutter build web -t lib/admin/main_admin.dart` → `firebase deploy --only hosting` | Everyone, on next page load |
| Farmer app code | `flutter build apk --release` → share APK (or Play Store) | After they install the update |
| Crop Doctor / Ask Cassia | `firebase deploy --only functions` | Instantly after deploy |
| Security rules | `firebase deploy --only firestore:rules` | Instantly after deploy |
