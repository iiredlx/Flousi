# FLOUSI — Phase 1 prototype

A responsive, bilingual (Arabic/English) personal-finance web prototype with light/dark themes, display-currency conversion, transactions, spending budgets, savings goals, and a dashboard.

## Run it

1. Download and extract `FLOUSI-phase1.zip`.
2. Open `index.html` in a modern browser, or serve this folder with any static web server.
3. Try the theme toggle, language toggle, currency selector, add transaction, add goal, search/filter, and reset demo controls.

No build step or dependencies are required. Google Fonts are optional; the browser falls back to system fonts when offline.

## Important prototype limits

- This phase is a front-end prototype, not a production financial product.
- Data is stored in this browser's `localStorage`; it is not encrypted, synced, or backed up. Do not enter real sensitive financial data.
- Currency conversion uses illustrative hard-coded rates in `app.js`; it is not a live exchange-rate feed and must not be used for financial decisions.
- There is no authentication, multi-device sync, bank connection, server API, or account recovery yet.

See `FLOUSI_SPEC.md` for product scope, page inventory, data model, security rules, phased delivery, and acceptance criteria. `schema.sql` is a proposed PostgreSQL/Supabase starting schema for a later backend phase; it is not wired into this prototype.
