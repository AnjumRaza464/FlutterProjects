# Admin panel hosting (separate site)

The **admin panel** is deployed to its **own** Firebase Hosting site so it never
clashes with the farmer web app:

| App | Live URL | Build target | Deploy config |
|---|---|---|---|
| Farmer app (web) | https://cassia-seed.web.app | `lib/main.dart` | root `firebase.json` |
| **Admin panel** | **https://cassia-seed-admin.web.app** | `lib/admin/main_admin.dart` | **this folder's `firebase.json`** |

A single Firebase site can only hold one app, so each one has its own site now.
This folder's `firebase.json` has `"site": "cassia-seed-admin"` and serves from
`hosting-admin/public/` (a copy of the admin web build). Deploying the admin from
here **never touches** the farmer app's hosting — the root `firebase.json` is
left alone, so the farmer deploy workflow is unchanged.

`hosting-admin/public/` is a build artifact (git-ignored); don't edit it by hand.

## Redeploy the admin panel after changes

From the project **root** (PowerShell):

```powershell
flutter build web -t lib/admin/main_admin.dart --release
Remove-Item -Recurse -Force hosting-admin\public -ErrorAction SilentlyContinue
Copy-Item -Recurse build\web hosting-admin\public
cd hosting-admin
firebase deploy --only hosting --project cassia-seed
cd ..
```

That rebuilds the admin web app, snapshots it into `hosting-admin/public/`, and
publishes it to https://cassia-seed-admin.web.app. The farmer app
(`cassia-seed.web.app`) is deployed separately from the project root and is not
affected.
