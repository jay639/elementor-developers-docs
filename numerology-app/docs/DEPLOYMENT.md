# Deployment

Three environments are supported: **development**, **staging** and **production**.
They must never share a database or a set of secrets.

## API

Build and run:

```bash
cd apps/api
npm ci
npm run build          # prisma generate + tsc
npm run db:migrate     # prisma migrate deploy — never `migrate dev` in production
npm start              # node dist/server.js
```

Requirements in production:

* **HTTPS only.** Terminate TLS at the load balancer and forward to the API; the
  app sets `trust proxy` so `req.ip` and rate limiting use the real client address.
* **Environment variables** injected by the platform (never a committed `.env`).
  The process refuses to start if a secret is missing or shorter than 32 characters.
* **`CORS_ORIGINS`** set to the admin panel origin only. Mobile apps send no
  `Origin` header and are unaffected.
* **Health check** `GET /health` for the load balancer; it returns 503 when the
  database is unreachable.
* **Graceful shutdown** is already handled on `SIGTERM`, so rolling deploys do not
  drop in-flight requests.
* **Migrations** run as a separate release step before the new version starts.

### Database

* Managed PostgreSQL 14+ with automated daily backups and point-in-time recovery.
* Restore drills: verify a restore into a scratch database at least once a quarter.
* Connection pooling (PgBouncer or the provider's pooler) in front of the API.
* Retain `audit_logs` and `analytics_events` according to your privacy policy.

### Monitoring

* Ship the structured `pino` logs to your log platform. Credentials, tokens and
  passwords are redacted before they are written.
* Alert on: 5xx rate, `/health` failures, p95 latency, database connections,
  failed logins per minute (credential stuffing) and rate-limit rejections.
* Add an error tracker (Sentry or equivalent) to the API and the admin panel.

## Admin panel

```bash
cd apps/admin
npm ci
VITE_API_BASE_URL=https://api.example.com npm run build   # emits dist/
```

Serve `dist/` from any static host behind HTTPS, with SPA fallback to
`index.html`. Recommended headers: HSTS, `X-Content-Type-Options: nosniff`,
`Referrer-Policy: same-origin`, and a CSP allowing only your API origin. The panel
is already marked `noindex, nofollow`. Restrict access further with your own
network controls (VPN or IP allow-list) if the deployment warrants it.

## Mobile app

The project is an Expo app; builds are produced with EAS.

```bash
cd apps/mobile
npx eas build --platform android --profile production   # .aab for Google Play
npx eas build --platform ios --profile production       # for App Store Connect
```

Configured already:

* App identity: `app.ankjyoti.mobile` on both platforms, icon, adaptive icon and
  splash screen in `assets/`.
* `app.json` holds the version and Android `versionCode`; `eas.json` enables
  `autoIncrement` for production builds.
* Per-profile `EXPO_PUBLIC_API_BASE_URL` (development → emulator host,
  staging and production → the respective API).

Before the first store submission:

1. Replace `extra.eas.projectId` in `app.json` with your real EAS project id.
2. Create the Android upload keystore through EAS (`eas credentials`) and keep it
   in the EAS store — never in the repository.
3. Fill in the store listing, privacy policy URL (the app serves the same text from
   `/content/legal/PRIVACY`) and the data-safety declaration: the app collects a
   date of birth and optional email, and analytics only with consent.

To produce native projects for a non-EAS pipeline:

```bash
npx expo prebuild        # writes android/ and ios/ (both are gitignored)
```

## Release order

1. Migrate the database.
2. Deploy the API.
3. Deploy the admin panel.
4. Submit the mobile build.

The mobile app tolerates an older API (calculations fall back to the on-device
engine), but the API must never be behind the schema.
