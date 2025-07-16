-- Reverse the init schema migration
-- Drop tables in reverse order (due to foreign key dependencies)
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS entries;
DROP TABLE IF EXISTS accounts;

-- Drop custom types
DROP TYPE IF EXISTS transfer_status;
DROP TYPE IF EXISTS currency_enum;
