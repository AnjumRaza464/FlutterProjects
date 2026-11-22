# AI features — backend setup

Two Cloud Functions run the app's AI features server-side, so the OpenAI API
key never ships in the app:

| Function       | Used by           | What it does                                        |
| -------------- | ----------------- | --------------------------------------------------- |
| `diagnoseCrop` | Crop Doctor tab   | Diagnoses a crop photo (OpenAI vision).             |
| `askCassia`    | Ask Cassia AI tab | Answers farming / variety questions in a chat.      |

Both use the same key and are deployed together by the steps below. Until they
are deployed, the app shows "not set up yet" on those two tabs.

## One-time setup

1. **Enable the Blaze (pay-as-you-go) plan** on the Firebase project
   `cassia-seed`. Cloud Functions require Blaze. (The free Spark plan can't
   deploy functions.) You still get a monthly free tier.

2. **Install deps** (already done if you ran `npm install` in `functions/`):

   ```powershell
   cd functions; npm install
   ```

3. **Get an OpenAI API key** at https://platform.openai.com → API keys →
   create key, and add billing credit to the OpenAI account.

4. **Add the key as a Firebase secret** (stored in Google Secret Manager, not
   in the app or the repo):

   ```powershell
   firebase functions:secrets:set OPENAI_API_KEY
   ```

   Paste the key when prompted.

5. **Deploy** (this deploys both functions):

   ```powershell
   firebase deploy --only functions
   ```

Run step 5 again whenever `src/index.ts` changes.

## Model / cost

The model for both functions is set by one constant in `src/index.ts`:

```ts
const MODEL = "gpt-4o-mini"; // cheap, vision-capable (default)
```

`gpt-4o-mini` is a low-cost vision model with Structured Outputs — a good fit
for a high-volume farmer app. For higher accuracy, switch to a larger
vision-capable model (check OpenAI's models page for the current best/cheapest
names), then redeploy. Change only this line.

## How Ask Cassia knows the catalog

`askCassia` reads the Firestore `products` collection (the same documents the
Shop tab shows) and gives the model that list, including which varieties are
available. This is what keeps its answers in line with the Shop:

- It only talks about varieties that are in the catalog, and never quotes
  prices — it points farmers to "Add to cart" in the Shop instead, since the
  price is confirmed on WhatsApp once the cart is sent.
- A variety with `available: false` is described as **not available yet** and
  is never offered for sale, the same rule the Shop's overlay follows.

The list is re-read at most once a minute, so a change made in Firestore (or
later the admin panel) reaches the chat within about a minute — no redeploy.
Whether a variety can be ordered always comes from Firestore, never from the
app.

## Before launch (recommended hardening)

Both functions currently accept unauthenticated calls (farmers aren't signed
in). To stop abuse of your OpenAI budget, enable **Firebase App Check** and
require it on the functions. Until then, `maxInstances: 10` caps the blast
radius, and `askCassia` limits each request to the last 12 messages.

## Local testing

```powershell
cd functions; npm run serve
```

This builds and starts the Functions emulator. Point the app at the emulator
with `FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001)` while
testing (don't ship that line).
