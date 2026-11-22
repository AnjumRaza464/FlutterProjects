# Cassia Seed — Admin Web Panel

A separate Flutter **Web** app (same project, same Firebase) for managing the
product catalog: add / edit / delete varieties, flip "available", set sort
order, and upload images. It also shows the **orders** farmers send from the
app. Protected by Firebase Auth (email + password).

Entry point: `lib/admin/main_admin.dart` (the farmer app is `lib/main.dart`).

---

## One-time setup

### 1. Add web support to the project
The project has no `web/` folder yet. Add it once:

```powershell
flutter create . --platforms web
```

### 2. Add a Web app to Firebase and refresh the config
`firebase_options.dart` currently has Android + iOS only. Add Web:

```powershell
flutterfire configure
```

Pick the **cassia-seed** project and tick **Web** when prompted. This
regenerates `firebase_options.dart` with the web config the admin panel needs.

### 3. Turn on Email/Password sign-in and create an admin user
In the Firebase console → **Authentication**:
1. **Sign-in method** → enable **Email/Password**.
2. **Users** → **Add user** → enter your admin email + a password.

(There is no sign-up screen in the panel on purpose — you create admins here.)

---

## Run it

```powershell
flutter run -d chrome -t lib/admin/main_admin.dart
```

Sign in with the admin user you created. You'll see the product list.

---

## Orders

When a farmer sends their cart from the app, the order is saved to the
Firestore `orders` collection and also arrives as a WhatsApp message. The two
share an order number (like `CS-261121-7K2M`) so you can match them up.

Tap the **receipt icon** in the top bar to open Orders. Its badge counts the
orders nobody has handled yet. For each order you can:

- see the customer's name, city, phone, the varieties and quantities, and
  their note;
- tap **WhatsApp** or **Call** to reply with the price;
- tap the status pill to mark it **Confirmed**, **Delivered** or
  **Cancelled**;
- delete it (for test or junk orders).

An order shows up here as soon as the farmer taps "Send order on WhatsApp",
even if they never press send inside WhatsApp — so a new order with no
WhatsApp message is worth a call.

---

## Security rules (important — do this before real use)

By default your database may be open or locked. Set rules so **anyone can read
the catalog** (the app needs this) but **only signed-in admins can write**, and
so **anyone can place an order** but **only signed-in admins can see orders**
(they hold customers' names and phone numbers).

**Firestore.** The rules now live in the repo at **`firestore.rules`** — that
is the single source of truth. Deploy them with:

```powershell
firebase deploy --only firestore:rules
```

> **IMPORTANT — do this once, before you deploy the new rules.**
> Farmers and dealers now sign in too, so "signed in" no longer means "admin".
> The rules decide who is an admin from an **`admins`** collection. If you
> deploy the rules without adding yourself, the admin panel can no longer edit
> products or read orders.
>
> 1. In **Authentication → Users**, copy your admin account's **User UID**.
> 2. In **Firestore**, create a collection **`admins`**, add a document whose
>    **Document ID is that UID** (any field inside, e.g. `role: "admin"`).
> 3. Repeat for each admin. Then deploy the rules above.

Without the `orders` block, orders from the app are refused by Firestore (the
WhatsApp message still goes out, but nothing appears under Orders).

**Storage (product photos).** Photo storage has to be switched on once before
any photo can be uploaded from this panel. As of 21 Nov 2026 it is NOT switched
on for `cassia-seed`:

1. **Upgrade the project to the Blaze plan** — Firebase only offers Storage on
   Blaze. Console → ⚙ → *Usage and billing* → *Modify plan*. This is the same
   upgrade the AI features need (see `functions/SETUP.md`), so one upgrade
   unlocks both. Blaze still includes a free monthly allowance.
2. **Create the storage space** — Console → *Storage* → *Get started* → pick a
   location → *Done*.
3. **Apply the rules** — they are already in this project (`storage.rules`):

   ```powershell
   firebase deploy --only storage
   ```

Until then, uploading a photo here fails. The app is not affected: photos of
the 19 Cassia packs are built into the app and show without Storage.

The rules that get applied (anyone can view a product photo; only signed-in
admins can upload):

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{id} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

Notes:
- Product/order writes are now limited to admins listed in the `admins`
  collection (see the box above). Storage writes still allow any signed-in
  user — for stricter control, gate those on the same `admins` collection too.
- The app's **"Load demo products" button runs unauthenticated**, so it only
  works while writes are still open (test mode). Once you apply the rules
  above, add products through this admin panel instead.
- Placing an order needs no sign-in, so anyone with the app could send junk
  orders. Delete those from the Orders screen; enabling **Firebase App Check**
  before launch (see `functions/SETUP.md`) is the real fix.

---

## Deploy the panel (optional, later)

To host the panel online:

```powershell
flutter build web -t lib/admin/main_admin.dart
```

The build lands in `build/web`. You can deploy it with Firebase Hosting
(`firebase init hosting` → public dir `build/web`, then
`firebase deploy --only hosting`). Keep it on a separate site/URL from the
farmer app.

---

## Dealer & farmer accounts (v5)

The farmer app now has two accounts, reached from the cards at the top of Home:

- **Farmer Login** — a farmer signs in with their **mobile number** and a
  **6-digit secret number (PIN)**, or registers step by step (name → mobile →
  PIN → district → village → crops). Their profile is saved at
  `farmers/{uid}`; they read and write only their own.
- **Dealership** — a dealer **applies** (sign-in details + shop details) or
  **signs in** with mobile number + password. Their account lives at
  `dealers/{uid}` with `status: pending` until you approve it.

**How sign-in works.** There is no SMS/OTP — the mobile number is mapped to a
Firebase Auth e-mail behind the scenes (`<number>@farmer.cassiaseed.app` or
`…@dealer.cassiaseed.app`) and the PIN / password is the Firebase password, so
**Email/Password sign-in must stay enabled** (it already is, for admin). The
farmer never sees that e-mail.

**Reviewing dealers.** The admin dashboard's top bar has a **handshake icon**
(badge = applications waiting). It opens the Dealers list where you can:

- **Approve** or **Reject** a new application;
- **Edit balance / tier / awards** for an approved dealer — the outstanding
  balance, total purchases, tier (e.g. *Gold*), awards and benefits. These are
  shown read-only on the dealer's own dashboard. **Only admins can change
  them** (the Firestore rules block a dealer from editing their own balance).

The dealer can tap **Request statement on WhatsApp** to message the company for
their latest ledger — replies are manual (no automatic accounting sync).

> The original v5 reference built this on a Supabase backend with an
> accounting-sync Edge Function and WhatsApp Business API. That is a separate,
> larger integration; this build covers the farmer-facing screens, the
> accounts, and manual admin review on our existing Firebase.
