# Production readiness checklist

Status recorded when this build was prepared. Items marked ☐ need a decision or an
action from the team deploying the product — they cannot be completed from inside
the repository.

## Calculations

- [x] Mulank for every day 1–31, including the two-digit reductions.
- [x] Bhagyank from the complete date, with the working shown to the user.
- [x] Leap years, impossible dates (30 February, 31 April), future dates and
      pre-1900 dates rejected with friendly messages.
- [x] Number roots for vehicle, mobile, house and free-form numbers; separators
      stripped; empty, digit-less and over-long input rejected.
- [x] Chaldean table complete (26 letters, nothing on 9); compound **and** root
      numbers preserved.
- [x] All nine marriage rules tested in both directions, positive and negative.
- [x] Today's number derived from the live date, never hard-coded.
- [x] One engine shared by the API and the mobile app — no duplicated logic.
- [x] 136 engine unit tests, 93 API integration tests, 19 mobile unit tests, all green.

## Data and configuration

- [x] All interpretation text is database-driven and editable in the admin panel.
- [x] 9 numbers × 3 locales and 81 combinations × 3 locales seeded.
- [x] Marriage rules, number compatibility rules and the Chaldean table are data,
      not code; a change takes effect on the next calculation.
- [x] Seeds are idempotent and preserve values an administrator has already edited.
- [x] Migrations are versioned and applied with `prisma migrate deploy`.
- [ ] Review the seeded interpretation text with your numerology subject-matter
      expert before launch; it is baseline content, meant to be refined.

## Security

- [x] Passwords hashed with bcrypt (cost 12 by default); never selected in a query
      that returns to a client.
- [x] Refresh tokens are opaque, stored as SHA-256 hashes, rotated on use and
      revocable; disabling an account revokes every session immediately.
- [x] Admin authentication is fully separate: different table, secrets and token
      audience. A user token is rejected by every admin route.
- [x] RBAC enforced server side on every admin route; permissions re-read from the
      database on each request.
- [x] Zod validation on every write endpoint; Prisma parameterises all queries.
- [x] Helmet security headers, strict CORS allow-list, request size limit,
      general and stricter auth rate limits.
- [x] Errors return safe messages; stack traces are never sent in production.
- [x] Credentials and tokens redacted from logs.
- [x] No secrets in source control; `.env.example` provided for every app.
- [ ] Rotate the seeded administrator password and set real secrets in the
      production environment.
- [ ] Run a dependency audit (`npm audit`) and schedule it in CI.
- [ ] Add a WAF or platform-level DDoS protection in front of the API.

## Privacy and legal

- [x] Guest use: every core calculation works without an account.
- [x] Analytics events are allow-listed, require consent, and personal fields are
      stripped before storage.
- [x] Account deletion removes profile, history, saved results and devices, and
      anonymises analytics rows.
- [x] Terms, privacy policy, disclaimer and about text in all three languages,
      editable by an administrator.
- [x] Results are framed as interpretation, never guaranteed prediction; no
      alarming language on an unmatched compatibility result.
- [x] The Kundali referral never claims the app performs Vedic Kundali matching.
- [ ] Have the privacy policy and terms reviewed for your jurisdiction (DPDP Act
      in India) and add your company details and contact address.

## Applications

- [x] Mobile app bundles for Android (verified with `expo export`).
- [x] Light and dark mode across every screen; system default respected.
- [x] English, Hindi and Marathi throughout the UI and the API content.
- [x] Loading, empty and error states on every screen; no frozen interface.
- [x] Touch targets ≥ 44px, screen-reader labels, dynamic text scaling, no
      colour-only signalling.
- [x] Offline: Mulank, Bhagyank, roots, today's number, Chaldean and compatibility
      all calculate on the device, clearly marked as offline results.
- [x] Admin panel builds, is responsive to tablet width, and runs with no console
      errors (verified in a headless browser against the live API).
- [x] No placeholder buttons: every visible control performs a real action.
- [ ] Provide the real EAS `projectId` and store credentials.
- [ ] Manual QA pass on physical Android and iOS devices.

## Operations

- [x] `/health` endpoint including a database check.
- [x] Graceful shutdown on SIGTERM.
- [x] Structured logging with redaction.
- [x] Maintenance mode that never locks the administrator out.
- [ ] Configure database backups and rehearse a restore.
- [ ] Wire up error tracking, uptime and API monitoring alerts.
- [ ] Decide log and analytics retention periods.

## Not built (deliberately)

The architecture leaves room for these, but no placeholder UI ships for them:
push notification delivery (the token registration and preferences exist, the
sending service does not), Google/Apple sign-in (the schema supports the providers),
Lo Shu grid, lucky colours and dates, paid reports and subscriptions.
