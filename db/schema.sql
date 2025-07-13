-- db/schema.sql

-- ENUMs
CREATE TYPE currency_enum AS ENUM ('USD', 'EUR', 'INR', 'GBP', 'JPY');
CREATE TYPE transfer_status AS ENUM ('pending', 'completed', 'failed', 'reversed');

-- ACCOUNTS
CREATE TABLE accounts (
  id bigserial PRIMARY KEY,
  owner varchar NOT NULL,
  balance bigint NOT NULL CHECK (balance >= 0),
  currency currency_enum NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ENTRIES
CREATE TABLE entries (
  id bigserial PRIMARY KEY,
  account_id bigint NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  amount bigint NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- TRANSFERS
CREATE TABLE transfers (
  id bigserial PRIMARY KEY,
  from_account_id bigint NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
  to_account_id bigint NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
  amount bigint NOT NULL CHECK (amount > 0),
  status transfer_status NOT NULL DEFAULT 'pending',
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- INDEXES
CREATE INDEX idx_accounts_owner ON accounts(owner);
CREATE INDEX idx_entries_account_id ON entries(account_id);
CREATE INDEX idx_transfers_from_id ON transfers(from_account_id);
CREATE INDEX idx_transfers_to_id ON transfers(to_account_id);
CREATE INDEX idx_transfers_both ON transfers(from_account_id, to_account_id);
