# Guide: Implementing Full CRUD for Accounts Table with sqlc

## Introduction

This guide will help you, step by step, to implement Create, Read, Update, and Delete (CRUD) operations for the `accounts` table in a Go project using [sqlc](https://sqlc.dev/). It is written for beginners and explains not just how, but why each step is important.

- **CRUD** stands for Create, Read, Update, Delete—these are the basic operations for managing data in a database.
- **sqlc** is a tool that reads your SQL queries and database schema, then generates type-safe Go code so you can use those queries easily in your application.
- **Go and SQL**: Go is a programming language, and SQL is used to interact with databases. sqlc helps bridge the two, so you can write SQL and use it safely in Go.

---

## Project Structure Overview

- `db/schema.sql`: Defines your database tables and their columns.
- `db/query/account.sql`: Contains SQL queries for the `accounts` table.
- `db/sqlc/`: Where sqlc generates Go code based on your SQL and schema.
- `sqlc.yaml`: The configuration file for sqlc (tells it where to find your SQL and where to put generated code).

---

## 1. Write SQL Queries for CRUD

Edit (or create) `db/query/account.sql` and add the following queries:

```sql
-- name: CreateAccount :one
INSERT INTO accounts (
  owner,
  balance,
  currency
) VALUES (
  $1, $2, $3
) RETURNING *;

-- name: GetAccount :one
SELECT * FROM accounts WHERE id = $1 LIMIT 1;

-- name: ListAccounts :many
SELECT * FROM accounts ORDER BY id LIMIT $1 OFFSET $2;

-- name: UpdateAccount :one
UPDATE accounts SET balance = $2 WHERE id = $1 RETURNING *;

-- name: DeleteAccount :exec
DELETE FROM accounts WHERE id = $1;
```

### Line-by-Line Explanation

#### CreateAccount
- `-- name: CreateAccount :one` — Names the query for sqlc and says it returns one row.
- `INSERT INTO accounts (...) VALUES (...)` — Adds a new account with the given owner, balance, and currency.
- `$1, $2, $3` — Placeholders for the values you provide from Go code.
- `RETURNING *;` — Returns the full new row, including auto-generated fields like id.

#### GetAccount
- `-- name: GetAccount :one` — Fetches a single account by id.
- `SELECT * FROM accounts WHERE id = $1 LIMIT 1;` — Gets the account with the given id.

#### ListAccounts
- `-- name: ListAccounts :many` — Fetches multiple accounts.
- `ORDER BY id LIMIT $1 OFFSET $2;` — Supports pagination (limit and offset).

#### UpdateAccount
- `-- name: UpdateAccount :one` — Updates an account and returns the updated row.
- `SET balance = $2 WHERE id = $1` — Changes the balance for the account with the given id.

#### DeleteAccount
- `-- name: DeleteAccount :exec` — Deletes an account by id.

**Why:**
- Named queries let sqlc generate Go methods for you.
- Placeholders (`$1`, `$2`, etc.) keep your queries safe from SQL injection.
- Pagination is best practice for listing many records.

---

## 2. Generate Go Code with sqlc

Run the following command (usually via Makefile):

```sh
make sqlc
# or directly
sqlc generate
```

**What happens:**
- sqlc reads your SQL and schema, then generates Go code in `db/sqlc/`.
- You get Go structs and methods for each query.

---

## 3. Use the Generated Go Code

In your Go code, import the generated package and use the methods:

```go
import "yourmodule/db/sqlc"

// Example: Create an account
params := db.CreateAccountParams{
    Owner:    "alice",
    Balance:  1000,
    Currency: db.CurrencyEnumUSD,
}
account, err := queries.CreateAccount(ctx, params)

// Example: Get an account
account, err := queries.GetAccount(ctx, accountID)

// Example: List accounts
accounts, err := queries.ListAccounts(ctx, db.ListAccountsParams{Limit: 10, Offset: 0})

// Example: Update an account
updated, err := queries.UpdateAccount(ctx, db.UpdateAccountParams{ID: accountID, Balance: 2000})

// Example: Delete an account
err := queries.DeleteAccount(ctx, accountID)
```

**What & Why:**
- Each method matches your SQL query and is fully type-safe.
- You avoid manual SQL in your Go code, reducing bugs and improving maintainability.

---

## 4. How sqlc Works & Configuration

- sqlc uses `sqlc.yaml` to know where your SQL files and schema are, and where to put generated code.
- It parses your SQL and schema, checks for errors, and generates Go code that matches your queries.
- If you change your SQL or schema, always re-run `make sqlc` to update the Go code.

---

## 5. Common Problems and Solutions

- **Dependency errors (e.g., pgx not found):**
  - Run `go get github.com/jackc/pgx/v5` to install the required package.
- **SQL errors:**
  - Check your SQL syntax and make sure your schema matches your queries.
- **Regenerating code:**
  - If you change your SQL or schema, always re-run `make sqlc`.
- **Go build errors:**
  - Make sure your Go code uses the correct types and method signatures from the generated code.

---

## 6. Best Practices

- Use clear, descriptive names for your queries.
- Keep your SQL, schema, and Go code in sync by running `make sqlc` after any changes.
- Commit both your SQL and generated Go code to version control.
- Use pagination for listing queries to avoid loading too much data at once.
- Write tests for your database code using the generated methods.

---

## 7. How to Extend to Other Tables

- Repeat the same process for other tables (e.g., `entries`, `transfers`).
- Create a new SQL file (e.g., `db/query/entry.sql`), write CRUD queries, and run `make sqlc`.
- Use the generated Go code in your application.

---

## 8. Resources

- [sqlc Documentation](https://docs.sqlc.dev/)
- [Go Documentation](https://golang.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Go by Example: Database/SQL](https://gobyexample.com/sql-databases)

---


---

# Guide: Implementing Full CRUD for Entries Table with sqlc

## 1. Write SQL Queries for CRUD (entries)

Create or edit `db/query/entry.sql` and add the following queries:

```sql
-- name: CreateEntry :one
INSERT INTO entries (
  account_id,
  amount
) VALUES (
  $1, $2
) RETURNING *;

-- name: GetEntry :one
SELECT * FROM entries WHERE id = $1 LIMIT 1;

-- name: ListEntries :many
SELECT * FROM entries
ORDER BY id
LIMIT $1
OFFSET $2;

-- name: UpdateEntry :one
UPDATE entries
SET amount = $2
WHERE id = $1
RETURNING *;

-- name: DeleteEntry :exec
DELETE FROM entries
WHERE id = $1;
```

### Line-by-Line Explanation

#### CreateEntry
- `-- name: CreateEntry :one` — Tells sqlc to generate a Go method named `CreateEntry` that returns a single row.
- `INSERT INTO entries (...) VALUES (...)` — Adds a new entry with the given account ID and amount.
- `account_id, amount` — Specifies the columns to insert values for. `account_id` links to the account, `amount` is the transaction value.
- `VALUES ($1, $2)` — Uses parameters for safe, dynamic input from Go code.
- `RETURNING *;` — Returns the full new row, including auto-generated fields like id and created_at.

#### GetEntry
- `-- name: GetEntry :one` — Tells sqlc to generate a Go method named `GetEntry` that returns a single row.
- `SELECT * FROM entries WHERE id = $1 LIMIT 1;` — Fetches the entry with the given id. LIMIT 1 ensures only one row is returned.

#### ListEntries
- `-- name: ListEntries :many` — Tells sqlc to generate a Go method named `ListEntries` that returns multiple rows.
- `SELECT * FROM entries` — Fetches all columns from the entries table.
- `ORDER BY id` — Sorts the results by id for consistency.
- `LIMIT $1 OFFSET $2` — Supports pagination: LIMIT is the max number of rows, OFFSET is how many to skip.

#### UpdateEntry
- `-- name: UpdateEntry :one` — Tells sqlc to generate a Go method named `UpdateEntry` that returns a single row.
- `UPDATE entries SET amount = $2 WHERE id = $1` — Updates the amount for the entry with the given id.
- `RETURNING *;` — Returns the updated row.

#### DeleteEntry
- `-- name: DeleteEntry :exec` — Tells sqlc to generate a Go method named `DeleteEntry` that just executes (no rows returned).
- `DELETE FROM entries WHERE id = $1;` — Deletes the entry with the given id.

**Why:**
- Named queries let sqlc generate Go methods for you.
- Placeholders (`$1`, `$2`) keep your queries safe from SQL injection.
- Pagination is best practice for listing many records.

---

## 2. Generate Go Code with sqlc (entries)

Run:
```sh
make sqlc
# or
sqlc generate
```
This will generate new Go methods for all your entries queries in the `db/sqlc/` directory.

---

## 3. Use the Generated Go Code (entries)

Example usage in Go:

```go
// Create an entry
params := db.CreateEntryParams{
    AccountID: 1,
    Amount:    500,
}
entry, err := queries.CreateEntry(ctx, params)

// Get an entry
entry, err := queries.GetEntry(ctx, entryID)

// List entries
entries, err := queries.ListEntries(ctx, db.ListEntriesParams{Limit: 10, Offset: 0})

// Update an entry
updated, err := queries.UpdateEntry(ctx, db.UpdateEntryParams{ID: entryID, Amount: 1000})

// Delete an entry
err := queries.DeleteEntry(ctx, entryID)
```

**Notes:**
- The process is almost identical to accounts, but the fields and business logic may differ (e.g., `account_id` is a foreign key).
- Always check for errors and handle them appropriately in your application.

---

## 4. Test and Commit

Test your new methods, then commit your changes:
```sh
git add .
git commit -m "feat: add full CRUD for entries table and generate sqlc code"
```

---


---

# Guide: Implementing Full CRUD for Transfers Table with sqlc

## 1. Write SQL Queries for CRUD (transfers)

Create or edit `db/query/transfer.sql` and add the following queries:

```sql
-- name: CreateTransfer :one
INSERT INTO transfers (
  from_account_id,
  to_account_id,
  amount,
  status,
  reason
) VALUES (
  $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetTransfer :one
SELECT * FROM transfers WHERE id = $1 LIMIT 1;

-- name: ListTransfers :many
SELECT * FROM transfers
ORDER BY id
LIMIT $1
OFFSET $2;

-- name: UpdateTransfer :one
UPDATE transfers
SET status = $2, reason = $3
WHERE id = $1
RETURNING *;

-- name: DeleteTransfer :exec
DELETE FROM transfers WHERE id = $1;
```

### Line-by-Line Explanation

#### CreateTransfer
- `-- name: CreateTransfer :one` — Tells sqlc to generate a Go method named `CreateTransfer` that returns a single row.
- `INSERT INTO transfers (...) VALUES (...)` — Adds a new transfer with the given from_account_id, to_account_id, amount, status, and reason.
- `from_account_id, to_account_id, amount, status, reason` — Specifies the columns to insert values for. These represent the source and destination accounts, the amount, the transfer status, and an optional reason.
- `VALUES ($1, $2, $3, $4, $5)` — Uses parameters for safe, dynamic input from Go code.
- `RETURNING *;` — Returns the full new row, including auto-generated fields like id and created_at.

#### GetTransfer
- `-- name: GetTransfer :one` — Tells sqlc to generate a Go method named `GetTransfer` that returns a single row.
- `SELECT * FROM transfers WHERE id = $1 LIMIT 1;` — Fetches the transfer with the given id. LIMIT 1 ensures only one row is returned.

#### ListTransfers
- `-- name: ListTransfers :many` — Tells sqlc to generate a Go method named `ListTransfers` that returns multiple rows.
- `SELECT * FROM transfers` — Fetches all columns from the transfers table.
- `ORDER BY id` — Sorts the results by id for consistency.
- `LIMIT $1 OFFSET $2` — Supports pagination: LIMIT is the max number of rows, OFFSET is how many to skip.

#### UpdateTransfer
- `-- name: UpdateTransfer :one` — Tells sqlc to generate a Go method named `UpdateTransfer` that returns a single row.
- `UPDATE transfers SET status = $2, reason = $3 WHERE id = $1` — Updates the status and reason for the transfer with the given id.
- `RETURNING *;` — Returns the updated row.

#### DeleteTransfer
- `-- name: DeleteTransfer :exec` — Tells sqlc to generate a Go method named `DeleteTransfer` that just executes (no rows returned).
- `DELETE FROM transfers WHERE id = $1;` — Deletes the transfer with the given id.

**Why:**
- Named queries let sqlc generate Go methods for you.
- Placeholders (`$1`, `$2`, etc.) keep your queries safe from SQL injection.
- Pagination is best practice for listing many records.
- `status` and `reason` are included in updates for flexibility (e.g., marking as completed, failed, or adding a reason).

---

## 2. Generate Go Code with sqlc (transfers)

Run:
```sh
make sqlc
# or
sqlc generate
```
This will generate new Go methods for all your transfers queries in the `db/sqlc/` directory.

---

## 3. Use the Generated Go Code (transfers)

Example usage in Go:

```go
// Create a transfer
params := db.CreateTransferParams{
    FromAccountID: 1,
    ToAccountID:   2,
    Amount:        1000,
    Status:        db.TransferStatusPending,
    Reason:        "Payment for invoice #123",
}
transfer, err := queries.CreateTransfer(ctx, params)

// Get a transfer
transfer, err := queries.GetTransfer(ctx, transferID)

// List transfers
transfers, err := queries.ListTransfers(ctx, db.ListTransfersParams{Limit: 10, Offset: 0})

// Update a transfer
updated, err := queries.UpdateTransfer(ctx, db.UpdateTransferParams{ID: transferID, Status: db.TransferStatusCompleted, Reason: "Completed by admin"})

// Delete a transfer
err := queries.DeleteTransfer(ctx, transferID)
```

**Notes:**
- The process is almost identical to accounts and entries, but the fields and business logic may differ (e.g., two account IDs, status, and reason).
- Always check for errors and handle them appropriately in your application.
- You can extend the queries for more advanced filtering (e.g., by account, status, or date).

---

## 4. Test and Commit

Test your new methods, then commit your changes:
```sh
git add .
git commit -m "feat: add full CRUD for transfers table and generate sqlc code"
```

---





