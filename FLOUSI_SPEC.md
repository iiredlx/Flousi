# FLOUSI — Product Requirements & Technical Plan

**Version:** 0.1 · **Status:** Phase 1 testable prototype · **Product:** Global personal-finance companion

## 1. Product vision

FLOUSI helps individuals understand cash flow, control spending, track debts, and reach savings goals. It is a personal finance organizer—not a bank, investment broker, or source of guaranteed financial advice.

### Product principles
- Private by default; collect the minimum data needed.
- Multi-currency amounts are stored with an explicit currency and never silently reinterpreted.
- Accessible, responsive UI with Arabic RTL and English LTR from the beginning.
- Light and dark themes, keyboard accessibility, readable contrast, and reduced-motion support.
- Be transparent about exchange-rate source/time and distinguish estimates from confirmed values.
- No bank integration or financial claims until security, legal, and operational reviews are complete.

## 2. Audience & platform

- Primary audience: individuals managing personal spending, savings, budgets, and informal debts.
- Global audience: locale, time zone, language, number/date formatting, and base currency are user preferences.
- Initial delivery: responsive web app/PWA-ready architecture. Native mobile wrappers can be considered after product validation.
- Initial languages: Arabic and English. Translation dictionary architecture supports later languages.
- Initial currencies: ISO 4217 currency codes. Display currency is a preference, not a replacement for transaction currency.

## 3. Scope by phase

### Phase 1 — clickable, testable local prototype (included)
- Dashboard with balance, monthly income/expenses, net cash flow, chart, latest transactions, and goals.
- Create and delete transactions; income/expense types; category, date, amount, note.
- Budget overview with category spending against illustrative limits.
- Create/delete savings goals with target, current saved amount, and optional date.
- Arabic/English toggle; RTL/LTR layout; light/dark mode; display currency selector.
- Demo data and reset button; local browser persistence only.

### Phase 2 — secure accounts & cloud persistence
- Choose managed PostgreSQL (e.g. Supabase) with Row Level Security (RLS) or equivalent backend.
- Sign up, sign in, sign out, email verification, password reset, sessions, account deletion, and export.
- User-owned transactions, accounts, categories, budgets, savings goals, debts, and preferences.
- Schema migrations, server-side validation, authorization tests, audit events for sensitive actions.
- Remove prototype hard-coded exchange rates; add a server-side rate provider, provider attribution, timestamp, caching, and stale-rate behavior.

### Phase 3 — complete personal finance toolkit
- Multiple wallets/accounts and transfers; transfer is not income or expense.
- Recurring transactions, scheduled reminders, debts/IOUs, installments, and bills.
- Budget periods and rollover rules; savings contributions and withdrawals.
- CSV import/export; downloadable reports; backup and restore.
- Search, filtering, pagination, data retention and account deletion workflows.

### Phase 4 — smart insights & reliability
- Explainable spending summaries; user-controlled alerts; optional AI categorization.
- AI must not make trades, move money, or claim professional advice. Do not send identifiable transaction details to an AI provider without explicit informed opt-in.
- Notifications, PWA offline support, sync conflict handling, monitoring, analytics with privacy controls.

### Phase 5 — integrations & monetization (only after validation)
- Optional open-banking providers by region, with explicit consent and least-privilege access.
- Premium reporting/automation; transparent pricing and easy cancellation.
- Security review, threat modeling, privacy policy, terms, and region-specific legal review before release.

## 4. Page inventory

1. **Welcome / onboarding:** language, locale, time zone, base currency, privacy explanation.
2. **Authentication:** sign-up, sign-in, email verification, password reset, active sessions.
3. **Dashboard:** total balances by account/currency, cash-flow summaries, budgets, recent activity, goal progress.
4. **Transactions:** list, search, filters, pagination, create/edit/delete, receipts later.
5. **Transaction form:** type, amount, currency, account, category, date, merchant/name, note, optional tags.
6. **Accounts / wallets:** cash, bank, cards; account currency; opening balance; archived state.
7. **Budgets:** categories, period, limit, spent, remaining, warning preferences.
8. **Savings goals:** target amount/currency, saved amount, deadline, contributions, status.
9. **Debts & bills:** person/vendor, amount, currency, due date, installments, paid status.
10. **Reports:** income vs expense, category trends, period comparison, CSV export.
11. **Insights:** deterministic rules first; AI summaries opt-in and labeled.
12. **Settings:** language, theme, locale, time zone, base/display currency, rate source, privacy, data export/delete.
13. **Help / legal:** help, FAQ, privacy policy, terms, security contact.
14. **Admin / operations (internal only):** support tooling with scoped access and audit logging; no routine browsing of users' finances.

## 5. Core domain rules

- Every monetary amount is stored as an integer in minor units where practical (e.g. cents), plus ISO currency code. Avoid floating-point arithmetic for financial values.
- Each transaction belongs to exactly one user and one account. The transaction currency must be explicit.
- A transfer links two accounts and creates balanced outflow/inflow legs; it must not inflate income or expenses.
- Never add unlike currencies without a documented conversion rate, rate timestamp, source, and rounding policy.
- Exchange rates are quotes with `base_currency`, `quote_currency`, `rate`, `source`, `observed_at`, and `fetched_at`. Store the original amount/currency; conversions are derived.
- Use UTC timestamps in storage; retain the user's time zone for display and date-boundary calculations.
- Deleted data handling, soft-delete vs hard-delete, and retention periods must be defined before production.
- The dashboard balance in the prototype is a simplified sum of demo income minus demo expenses; production balance must come from accounts and opening balances plus ledger movements.

## 6. Proposed data model

- `profiles`: one per authenticated user; locale, time zone, language, theme, base currency.
- `accounts`: user-owned wallet/account, name, type, currency, opening balance, status.
- `categories`: user-defined or system categories, localized labels, income/expense applicability.
- `transactions`: user, account, type, amount_minor, currency, category, occurred_at, note, merchant, created/updated timestamps.
- `transfers`: user, source account, destination account, amount/currencies, conversion quote where applicable; linked ledger entries.
- `budgets`: user, category, period, limit_minor, currency, start/end date.
- `savings_goals`: user, title, target_minor, currency, target_date, status.
- `goal_contributions`: user, goal, amount_minor, currency, occurred_at, linked transaction optionally.
- `debts`: user, direction (owed_to_me / owed_by_me), counterparty label, amount_minor, currency, due date, status.
- `exchange_rates`: base/quote currencies, rate decimal, source, observed_at, fetched_at.
- `recurring_rules`: user, schedule, transaction template, next_run_at, status.
- `audit_events`: restricted, append-only record for sensitive security/admin actions; never store passwords, tokens, or full financial payloads unnecessarily.

See `schema.sql` for an illustrative initial PostgreSQL schema with owner-scoped RLS. Review and migrate it before production; it is not a substitute for a security audit.

## 7. Security & privacy rules

- Authentication: use a proven auth provider; never implement password storage yourself. Enforce verified email where appropriate, secure session handling, rate limits, and secure recovery.
- Authorization: deny by default. Every user-owned table must have RLS policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE` based on the authenticated user ID. Check ownership server-side for every mutation.
- Secrets: service-role keys, API keys, signing secrets, and provider credentials stay server-side in environment secrets. Never embed privileged keys in browser code or a mobile app.
- Validation: validate schemas and ranges on the server; treat browser validation as convenience only. Use parameterized queries and safe output encoding.
- Transport/storage: HTTPS everywhere; managed database encryption at rest; avoid logging financial notes/amounts; apply least privilege and backups.
- Session/security controls: rate limit login/reset/exports, protect against CSRF where cookie auth is used, use secure cookies, and define session revocation.
- XSS/CSRF/SQLi: contextual output encoding, CSP, framework protections, parameterized SQL, CSRF protection where applicable.
- Data rights: allow users to export and delete their data; document retention and backups; avoid collecting contacts/location unless a clear feature requires it.
- Sensitive features: bank connections require explicit consent, provider scopes, revocation, token encryption, and incident response. No scraping bank credentials.
- AI: opt-in; minimize/redact payloads; disclose processor; do not use user data for training without explicit permission.
- Production readiness: threat model, dependency scans, backup-restore test, penetration test, privacy review, incident response, and documented access controls.

## 8. Phase 1 acceptance tests

1. Open `index.html` on desktop and mobile widths without layout overflow.
2. Switch Arabic ↔ English; direction changes RTL ↔ LTR and labels update.
3. Switch dark ↔ light; preference persists after reload.
4. Change display currency; amounts change display only, while original demo amounts remain unchanged.
5. Add an expense and income; dashboard summaries, list, and chart refresh.
6. Search transactions and filter income/expense.
7. Delete a transaction; summaries update and deletion persists after reload.
8. Add and delete a savings goal; progress is clamped to 100% for display and changes persist after reload.
9. Budget usage updates from current-month expenses in the matching category.
10. Reset demo data restores seeded sample records after confirmation.
11. Invalid, zero, negative, or non-numeric amounts cannot be submitted through the form.
12. Confirm prototype notice is visible and no real bank connection or live rate is implied.

## 9. Known prototype limitations

- `localStorage` is device/browser-local, unencrypted at the application level, and not appropriate for sensitive real financial data.
- Display exchange rates are illustrative constants and not live. Rates and labels must be updated before public demo to avoid misleading users.
- Demo balance is not an accounting ledger.
- No auth, backend, cloud sync, bank API, push notification, server validation, or multi-user support.
- Currency selector changes display conversion for the current prototype; production transactions must each retain their own currency.

## 10. Suggested implementation stack for Phase 2

- Frontend: TypeScript + React/Next.js or equivalent; component-level tests; accessible design tokens; i18n library with RTL support.
- Backend: PostgreSQL + managed authentication/RLS (e.g. Supabase) or a small API with equivalent authorization guarantees.
- Validation: shared schemas (e.g. Zod) with authoritative server validation.
- Tests: unit tests for money/currency rules, integration tests for RLS, end-to-end tests for main flows, and accessibility checks.
- Hosting: static/edge frontend plus managed database; separate dev/staging/prod projects and secrets.

## 11. Delivery gates

- **Gate A (now):** prototype passes acceptance tests; review usability and terminology with a few target users.
- **Gate B:** schema/auth design approved; RLS tests prove user A cannot read/write user B data.
- **Gate C:** backups, export/delete, exchange-rate provenance, and incident response work in staging.
- **Gate D:** accessibility, privacy/legal, and independent security review completed before production launch.
