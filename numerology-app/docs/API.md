# API reference

Base URL: `/api/v1`. All responses use one envelope:

```jsonc
// success
{ "success": true, "data": { … }, "meta": { "page": 1, "pageSize": 20, "total": 42, "totalPages": 3, "hasMore": true } }

// failure
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "Please check the information you entered.", "details": [ … ] } }
```

Error codes: `VALIDATION_ERROR` (422), `UNAUTHORIZED` (401), `FORBIDDEN` (403),
`NOT_FOUND` (404), `CONFLICT` (409), `RATE_LIMITED` (429), `MAINTENANCE` (503),
`INTERNAL_ERROR` (500). Messages are always safe to show to a user; technical
detail stays in the server logs.

**Language** — send `X-Locale: en|hi|mr` (or `?locale=`, or `Accept-Language`).
Content falls back to English when a translation is missing.

**Authentication** — `Authorization: Bearer <accessToken>`. Access tokens are
short lived; refresh tokens are opaque, stored only as a SHA-256 hash and rotated
on every use. Admin tokens use different secrets and a different audience, so a
user token is rejected by every admin route and vice versa.

---

## Health

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/health` | Liveness + database check. Not under `/api/v1`. |

## Authentication

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| POST | `/auth/guest` | – | Creates an anonymous account so a visitor can sync without an email. |
| POST | `/auth/register` | optional | `{ email, password, displayName?, dateOfBirth? }`. If called with a guest token the guest account is upgraded in place, keeping its history. |
| POST | `/auth/login` | – | `{ email, password }` |
| POST | `/auth/refresh` | – | `{ refreshToken }` — rotates the token; the old one is revoked. |
| POST | `/auth/logout` | – | `{ refreshToken }` |
| POST | `/auth/logout-all` | user | Ends every session on every device. |

## Profile

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/profile` | user | Profile, preferences and the derived Mulank/Bhagyank. |
| PUT | `/profile` | user | `{ displayName?, dateOfBirth?, gender?, phone?, photoUrl? }`. Saving a date of birth recalculates and stores the numbers. `dateOfBirth: null` clears it. |
| PUT | `/profile/preferences` | user | `{ locale?, theme?, notificationsEnabled?, dailyNumberOptIn?, analyticsConsent?, marketingConsent?, shareDobOnCards? }` |
| DELETE | `/profile` | user | Account deletion: personal data is removed immediately, the account row is soft deleted, sessions are revoked. |

## Numerology

All calculation endpoints work **without** an account. With a token they also use
the saved global date of birth and write a history entry.

| Method | Path | Body / query | Returns |
| --- | --- | --- | --- |
| POST | `/numerology/calculate` | `{ dateOfBirth?, save? }` | Mulank, Bhagyank, the reduction steps for both, the two number interpretations and the combination interpretation (`combinationFallback: true` when no combination row is published). Omit `dateOfBirth` to use the saved one; `save: true` stores it as the global date of birth. |
| POST | `/numerology/lucky-number` | `{ number, dateOfBirth?, save? }` | Digits kept, compound, root, breakdown, per-axis comparison against Mulank and Bhagyank, overall level (`STRONG_MATCH`/`GOOD_MATCH`/`NEUTRAL`/`WEAK_MATCH`) and a 0-100 score. |
| POST | `/numerology/name` | `{ name, dateOfBirth?, compareWithDob? }` | Per-letter values, **compound** and **root** numbers, ignored characters, and the comparison with the user's numbers when a date of birth is available. |
| POST | `/numerology/compatibility` | `{ maleDateOfBirth, femaleDateOfBirth }` | Both partners' numbers, **both direction results**, verdict, matched direction count, score, localised reasons, the Kundali referral and the disclaimers. |
| GET | `/numerology/daily` | `?date=YYYY-MM-DD` | Today's Lucky Number (defaults to the server date) with its working and interpretation. |
| GET | `/numerology/summary` | – | Everything the home screen needs in one call. |

### Compatibility response (shortened)

```jsonc
{
  "male":   { "dob": "1995-08-15", "mulank": 6, "bhagyank": 2 },
  "female": { "dob": "1990-01-01", "mulank": 1, "bhagyank": 3 },
  "directions": [
    { "direction": "MALE_TO_FEMALE", "driverNumber": 6, "targetMulank": 1, "targetBhagyank": 3,
      "matched": false, "matchedVia": "NONE", "compatibleMulank": [5,6,9], "compatibleBhagyank": [5,6,9] },
    { "direction": "FEMALE_TO_MALE", "driverNumber": 1, "targetMulank": 6, "targetBhagyank": 2,
      "matched": false, "matchedVia": "NONE", "compatibleMulank": [1,4,7], "compatibleBhagyank": [1,4,7] }
  ],
  "verdict": "NOT_MATCHED",          // STRONG_MATCH (both) · GOOD_MATCH (one) · NOT_MATCHED (neither)
  "matchedDirections": 0,
  "score": 0,
  "reasons": ["Neither Mulank 6 nor Mulank 1 lists the other partner numbers in its rule."],
  "kundaliReferral": { "enabled": true, "url": "", "label": "…", "note": "This app does not perform Vedic Kundali calculations." },
  "marriageDisclaimer": "Numerology compatibility is only one interpretive method …"
}
```

## History, saved results, content

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/history` | user | `?page&pageSize&type&search`, newest first. |
| GET | `/history/:id` | user | A user can only read their own entries. |
| DELETE | `/history/:id` | user | Soft delete. |
| DELETE | `/history` | user | Clears the whole history. |
| GET/POST | `/favourites` | user | Saved calculations. |
| DELETE | `/favourites/:id` | user | |
| GET | `/content/numbers` | – | All nine interpretations, for offline caching. |
| GET | `/content/numbers/:number` | – | |
| GET | `/content/combinations/:mulank/:bhagyank` | – | |
| GET | `/content/rules` | – | Marriage rules, number compatibility rules and the Chaldean table, so the app can calculate offline. |
| GET | `/content/legal/:type` | – | `TERMS` · `PRIVACY` · `DISCLAIMER` · `ABOUT` |
| GET | `/settings` | – | Public app configuration only. |
| POST | `/analytics/events` | optional | Allow-listed event names only. Signed-in users are recorded only with consent; personal fields are stripped. |
| POST/DELETE | `/devices` | user | Push notification token registration. |

---

## Admin API

Mounted at `/api/v1/admin`. Every route requires an admin token and a permission;
maintenance mode never applies here, so an administrator can always switch it off.

| Method | Path | Permission |
| --- | --- | --- |
| POST | `/admin/auth/login` | – |
| POST | `/admin/auth/refresh`, `/admin/auth/logout` | – |
| GET | `/admin/auth/me` | any admin |
| POST | `/admin/auth/change-password` | any admin |
| GET | `/admin/analytics?days=30` | `analytics:read` |
| GET | `/admin/numerology/numbers?locale=` | `content:read` |
| GET/PUT | `/admin/numerology/numbers/:number/:locale` | `content:read` / `content:write` |
| GET | `/admin/numerology/combinations?locale=&page=&search=` | `content:read` |
| GET/PUT | `/admin/numerology/combinations/:mulank/:bhagyank/:locale` | `content:read` / `content:write` |
| GET/PUT | `/admin/numerology/daily-insights[/:number/:locale]` | `content:read` / `content:write` |
| GET/PUT | `/admin/numerology/legal[/:type/:locale]` | `content:read` / `content:write` |
| GET/PUT | `/admin/compatibility-rules[/:driverNumber]` | `rules:read` / `rules:write` |
| GET/PUT | `/admin/number-rules[/:baseNumber]` | `rules:read` / `rules:write` |
| GET/PUT | `/admin/chaldean-mappings` | `rules:read` / `rules:write` |
| GET | `/admin/users?page&search&status&type` | `users:read` |
| GET | `/admin/users/:id`, `/admin/users/:id/history` | `users:read` |
| PATCH | `/admin/users/:id/status` | `users:write` |
| DELETE | `/admin/users/:id` | `users:delete` |
| GET/PUT | `/admin/settings[/:key]` | `settings:read` / `settings:write` |
| GET | `/admin/audit-logs?page&search` | `audit:read` |
| GET | `/admin/roles`, `/admin/admins` | `admins:read` |

Permissions are read from the database on every request, so a role change takes
effect immediately rather than when the token expires. Every write records an
audit entry with the before and after values.
