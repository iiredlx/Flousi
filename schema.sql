-- FLOUSI proposed PostgreSQL/Supabase schema — draft, not wired to Phase 1.
-- Apply in a disposable development project first. Review constraints, indexes,
-- currency precision, retention, and RLS behavior before production use.
create extension if not exists pgcrypto;

create type public.account_kind as enum ('cash','bank','card','savings','other');
create type public.transaction_kind as enum ('income','expense','transfer_in','transfer_out','adjustment');
create type public.budget_period as enum ('weekly','monthly','yearly','custom');
create type public.goal_status as enum ('active','completed','paused','archived');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) <= 80),
  language_code text not null default 'en' check (language_code ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  locale text not null default 'en-US',
  time_zone text not null default 'UTC',
  theme text not null default 'system' check (theme in ('light','dark','system')),
  base_currency char(3) not null default 'USD' check (base_currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  kind public.account_kind not null default 'cash',
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  opening_balance_minor bigint not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  key text not null check (char_length(key) between 1 and 60),
  label text not null check (char_length(label) between 1 and 80),
  applies_to text not null check (applies_to in ('income','expense','both')),
  is_system boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid not null,
  category_id uuid,
  kind public.transaction_kind not null,
  amount_minor bigint not null check (amount_minor > 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  merchant text check (char_length(merchant) <= 120),
  note text check (char_length(note) <= 1000),
  occurred_at timestamptz not null,
  transfer_group_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (account_id, user_id) references public.accounts(id, user_id) on delete cascade,
  foreign key (category_id) references public.categories(id) on delete set null
);

create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  name text not null check (char_length(name) between 1 and 80),
  period public.budget_period not null default 'monthly',
  limit_minor bigint not null check (limit_minor > 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  starts_on date not null,
  ends_on date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_on is null or ends_on >= starts_on)
);

create table public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  target_minor bigint not null check (target_minor > 0),
  saved_minor bigint not null default 0 check (saved_minor >= 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  target_date date,
  status public.goal_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_id uuid not null references public.savings_goals(id) on delete cascade,
  amount_minor bigint not null check (amount_minor > 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  occurred_at timestamptz not null default now(),
  transaction_id uuid references public.transactions(id) on delete set null,
  note text check (char_length(note) <= 500),
  created_at timestamptz not null default now()
);

create table public.debts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  direction text not null check (direction in ('owed_to_me','owed_by_me')),
  counterparty_label text not null check (char_length(counterparty_label) between 1 and 120),
  original_minor bigint not null check (original_minor > 0),
  outstanding_minor bigint not null check (outstanding_minor >= 0 and outstanding_minor <= original_minor),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  due_date date,
  settled_at timestamptz,
  note text check (char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exchange_rates (
  id uuid primary key default gen_random_uuid(),
  base_currency char(3) not null check (base_currency ~ '^[A-Z]{3}$'),
  quote_currency char(3) not null check (quote_currency ~ '^[A-Z]{3}$'),
  rate numeric(24,12) not null check (rate > 0),
  source text not null check (char_length(source) between 1 and 120),
  observed_at timestamptz not null,
  fetched_at timestamptz not null default now(),
  unique (base_currency, quote_currency, source, observed_at),
  check (base_currency <> quote_currency)
);

create index transactions_user_occurred_idx on public.transactions(user_id, occurred_at desc);
create index transactions_user_account_idx on public.transactions(user_id, account_id);
create index budgets_user_dates_idx on public.budgets(user_id, starts_on, ends_on);
create index goals_user_status_idx on public.savings_goals(user_id, status);
create index contributions_user_goal_idx on public.goal_contributions(user_id, goal_id, occurred_at desc);
create index debts_user_due_idx on public.debts(user_id, due_date);
create index rates_pair_observed_idx on public.exchange_rates(base_currency, quote_currency, observed_at desc);

-- Owner-scoped RLS: never rely on UI filters for isolation.
alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.savings_goals enable row level security;
alter table public.goal_contributions enable row level security;
alter table public.debts enable row level security;
alter table public.exchange_rates enable row level security;

create policy "profile owner can read" on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy "profile owner can insert" on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy "profile owner can update" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "account owner all" on public.accounts for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "category owner read or system" on public.categories for select to authenticated using (user_id = (select auth.uid()) or (user_id is null and is_system = true));
create policy "category owner insert" on public.categories for insert to authenticated with check (user_id = (select auth.uid()) and is_system = false);
create policy "category owner update" on public.categories for update to authenticated using (user_id = (select auth.uid()) and is_system = false) with check (user_id = (select auth.uid()) and is_system = false);
create policy "category owner delete" on public.categories for delete to authenticated using (user_id = (select auth.uid()) and is_system = false);
create policy "transaction owner all" on public.transactions for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "budget owner all" on public.budgets for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "goal owner all" on public.savings_goals for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "contribution owner all" on public.goal_contributions for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "debt owner all" on public.debts for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
-- Exchange rates are public reference data; clients can read but cannot write.
create policy "exchange rates authenticated read" on public.exchange_rates for select to authenticated using (true);

-- IMPORTANT SECURITY REVIEW NOTES:
-- 1) `categories` and `goal_contributions` need additional ownership integrity checks.
--    Before production, use composite foreign keys (id,user_id) or triggers so a user
--    cannot attach another user's category/goal/transaction by guessing a UUID.
-- 2) Exchange-rate writes must be performed by a trusted server/service role only.
-- 3) Add updated_at triggers, profile bootstrap trigger, and tests for every policy.
-- 4) Use integer minor units only when currency precision rules are modeled correctly;
--    currencies with 0 or 3 minor digits need currency metadata rather than assumptions.
