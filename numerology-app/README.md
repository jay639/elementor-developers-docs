# Ank Jyoti — Indian numerology platform

A production-ready numerology product: an Android/iOS mobile app, a REST API with a
PostgreSQL database, and a secure web admin panel. Every interpretation, every
compatibility rule and every Chaldean letter value is stored in the database and
edited from the admin panel, so the numerology system can be corrected and
extended without shipping a new app build.

Available in **English, Hindi and Marathi**.

---

## What it does

| Module | What the user gets |
| --- | --- |
| **Mulank & Bhagyank** | Driver and Conductor numbers from a date of birth, with the full working shown and a database-driven interpretation (including all 81 Mulank × Bhagyank combinations). |
| **Lucky Number Finder** | The root of any bike, car, mobile, house or business number, compared against the user's own numbers using configurable friendly/neutral/unfriendly rules. |
| **Name Numerology** | Chaldean name value, keeping **both** the compound number and the root number, optionally compared with the user's Mulank and Bhagyank. |
| **Marriage Compatibility** | Rules evaluated **in both directions** (male → female *and* female → male) and graded Strong / Good / Not Matched, with the reason for the result spelled out. |
| **Today's Lucky Number** | Derived from the current date every day — never hard-coded — with a short interpretation. |
| **History & saved results** | Paginated cloud history for signed-in users; guests calculate freely without an account. |
| **Admin panel** | Analytics, number content, the 81 combinations, compatibility rules, Chaldean mapping, users, app settings, legal documents and an audit log. |

---

## Repository layout

```
numerology-app/
├── packages/core/        @numerology/core — the calculation engine (pure, no I/O)
├── apps/api/             Express + TypeScript + Prisma + PostgreSQL
├── apps/admin/           React + Vite admin panel
├── apps/mobile/          Expo (React Native) app for Android and iOS
└── docs/                 API reference, deployment, production checklist
```

### One engine, three consumers

```
        ┌──────────────────────────────┐
        │   @numerology/core (pure TS) │  Mulank · Bhagyank · roots · Chaldean
        │   136 unit tests             │  compatibility · today's number
        └───────┬───────────────┬──────┘
                │               │
      ┌─────────▼──────┐   ┌────▼───────────────┐
      │  API (server)  │   │  Mobile (offline)  │
      │  + DB rules    │   │  + cached rules    │
      │  + DB content  │   │  + cached content  │
      └─────────┬──────┘   └────────────────────┘
                │
      ┌─────────▼──────┐
      │  Admin panel   │  edits the rules and the content the API serves
      └────────────────┘
```

The mobile app never re-implements a calculation: online it calls the API, and
offline it runs the *same* engine against rules cached from the last sync.

---

## Quick start

Requirements: Node.js 20+, PostgreSQL 14+, and (for the mobile app) the Expo CLI.

```bash
# 1. Install (workspaces: core, api, admin)
cd numerology-app
npm install

# 2. Configure the API
cd apps/api
cp .env.example .env          # then edit DATABASE_URL and the four JWT secrets
createdb numerology_dev       # or point DATABASE_URL at an existing database

# 3. Create the schema and load the seed content
npm run db:migrate            # prisma migrate deploy
npm run db:seed               # numbers 1-9, 81 combinations, rules, settings (× 3 locales)

# 4. Run the API
npm run dev                   # http://localhost:4000  (health check: /health)
```

```bash
# 5. Run the admin panel (proxies /api to the API in development)
cd ../admin
npm run dev                   # http://localhost:5173
```

```bash
# 6. Run the mobile app
cd ../mobile
npm install                   # separate install: React Native is not hoisted
cp .env.example .env          # EXPO_PUBLIC_API_BASE_URL
npm start                     # then press "a" for Android or "i" for iOS
```

Generate strong secrets with:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

### First administrator

`npm run db:seed` creates a super administrator from `SEED_ADMIN_EMAIL` and
`SEED_ADMIN_PASSWORD` in `apps/api/.env` and flags it `mustChangePassword`. Sign
in at the admin panel and change the password before going live — the panel shows
a banner until you do.

Seeded roles: **Super Admin** (everything), **Content Admin** (numerology content
and rules), **Support Admin** (view and disable users), **Analyst** (read-only).

---

## Environment variables

Every variable is documented in `apps/api/.env.example`, `apps/admin/.env.example`
and `apps/mobile/.env.example`. No secret is ever committed; the API refuses to
start if a required variable is missing or too weak.

| Variable | Used by | Notes |
| --- | --- | --- |
| `DATABASE_URL` | API | PostgreSQL connection string |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | API | User tokens, ≥ 32 characters |
| `ADMIN_JWT_ACCESS_SECRET` / `ADMIN_JWT_REFRESH_SECRET` | API | Separate admin tokens — never share these with the user secrets |
| `CORS_ORIGINS` | API | Comma-separated list of admin panel origins |
| `RATE_LIMIT_*` | API | Request throttling |
| `SEED_ADMIN_*` | API (seed only) | First administrator |
| `VITE_API_BASE_URL` | Admin | Empty in development (uses the Vite proxy) |
| `EXPO_PUBLIC_API_BASE_URL` | Mobile | `10.0.2.2` for the Android emulator |

---

## Testing

```bash
npm test                                  # engine + API (from numerology-app/)
npm run test -w @numerology/core          # 136 engine unit tests
npm run test -w @numerology/api           # 93 API integration tests (needs a test database)
cd apps/mobile && npm test                # 19 mobile unit tests
```

The API tests run against a **real** PostgreSQL database (never mocks). Create it
once and copy the example environment file:

```bash
createdb numerology_test
cd apps/api && cp .env.test.example .env.test
```

`globalSetup` applies migrations with `prisma migrate deploy`, loads the seed
content and clears rows left over from previous runs. It refuses to run against a
database whose URL is not the test database.

What is covered:

* every Mulank from day 1–31, Bhagyank worked examples, leap years, invalid and
  future dates;
* number roots for vehicle numbers, mobile numbers, formatting and edge cases;
* the Chaldean table (26 letters, nothing on 9) and `RAHUL = 17 → 8`;
* **all nine marriage rules**, in both directions, positive and negative cases;
* rule changes made in the admin panel taking effect in the next calculation;
* authentication, RBAC, disabled accounts, account deletion, analytics consent,
  maintenance mode, history isolation between users.

---

## Documentation

* [`docs/API.md`](docs/API.md) — every endpoint, with request and response shapes.
* [`docs/NUMEROLOGY.md`](docs/NUMEROLOGY.md) — the calculation rules and the
  bidirectional compatibility design.
* [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — production deployment for the API,
  the admin panel and the app stores.
* [`docs/PRODUCTION-CHECKLIST.md`](docs/PRODUCTION-CHECKLIST.md) — what to verify
  before release.

---

## Product principles

Numerology is presented as interpretation and guidance, never as a guaranteed
prediction. The app deliberately avoids absolute claims about marriage, wealth,
health or the future; a "Not Matched" compatibility result is accompanied by an
invitation to consult a qualified astrologer, and the app never claims to perform
Vedic Kundali calculations, which it does not.
