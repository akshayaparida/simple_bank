# Database Migration Guide - Simple Bank Project

## Overview
This document provides a step-by-step guide for setting up and managing database migrations in the Simple Bank project using `golang-migrate` with PostgreSQL.

## Prerequisites
- Docker installed and running
- golang-migrate installed (`/usr/local/bin/migrate`)
- PostgreSQL container setup

## Project Structure
```
simple_bank/
├── db/
│   ├── migration/
│   │   ├── 000001_init_schema.up.sql
│   │   └── 000001_init_schema.down.sql
│   └── schema.sql
├── .env
├── Makefile
└── DATABASE_MIGRATION_GUIDE.md
```

## Step-by-Step Migration Process

### 1. Initial Setup and Configuration

#### Database Configuration (.env file)
```env
DB_USER=your_db_user
DB_PASSWORD=your_secure_password
DB_NAME=your_database_name
DB_PORT=5432
DB_HOST=localhost
```

**SECURITY WARNING**: 
- Never commit the actual `.env` file to version control
- Add `.env` to your `.gitignore` file
- Use strong, unique passwords in production
- Consider using environment variables or secrets management in production

#### Makefile Migration Commands Added
```makefile
# Run database migrations up (apply schema changes)
migrateup:
	migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" -verbose up

# Run database migrations down (rollback schema changes)
migratedown:
	migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" -verbose down

# Apply only 1 migration up
migrateup1:
	migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" -verbose up 1

# Rollback only 1 migration down
migratedown1:
	migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" -verbose down 1

# Check current migration version
migrateversion:
	migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" version

# Force migration to specific version (use with caution)
migrateforce:
	migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" force $(VERSION)
```

### 2. Database Setup Process

#### Step 2.1: Start PostgreSQL Container
```bash
make postgres
```
**What it does**: Starts PostgreSQL container with configured credentials

#### Step 2.2: Create Database
```bash
make createdb
```
**What it does**: Creates the database specified in your `.env` file inside the container

### 3. Migration Execution Process

#### Step 3.1: Apply Migrations (Up)
```bash
make migrateup
```
**What it does**:
- Executes `000001_init_schema.up.sql`
- Creates tables: `accounts`, `entries`, `transfers`
- Creates custom types: `currency_enum`, `transfer_status`
- Creates indexes for performance
- Updates `schema_migrations` table to version 1

**Expected Output**:
```
Tables created:
- accounts (user account information)
- entries (transaction entries)
- transfers (money transfer records)
- schema_migrations (migration tracking)

Custom types created:
- currency_enum (USD, EUR, INR, GBP, JPY)
- transfer_status (pending, completed, failed, reversed)
```

#### Step 3.2: Verify Migration Success
```bash
# Check database tables
docker exec -it simplebankcont psql -U username -d dbname -c "\dt"

# Check migration version
make migrateversion
```

### 4. Migration Rollback Process

#### Step 4.1: Initial Rollback Attempt (Failed)
```bash
make migratedown
```
**Problem**: The `000001_init_schema.down.sql` file was empty, so tables remained but migration tracking was reset.

**Result**: 
- Migration version: 0 (no migration)
- Tables: Still existed (accounts, entries, transfers)
- Status: Inconsistent state

#### Step 4.2: Fix Down Migration File
**Original content**: Empty file
**Fixed content**:
```sql
-- Reverse the init schema migration
-- Drop tables in reverse order (due to foreign key dependencies)
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS entries;
DROP TABLE IF EXISTS accounts;

-- Drop custom types
DROP TYPE IF EXISTS transfer_status;
DROP TYPE IF EXISTS currency_enum;
```

#### Step 4.3: Resolve Inconsistent State
```bash
# Force migration tracker to version 1
make migrateforce VERSION=1

# Verify version is set
make migrateversion
# Output: 1
```

#### Step 4.4: Proper Rollback
```bash
make migratedown
```
**What it does**:
- Asks for confirmation: "Are you sure you want to apply all down migrations? [y/N]"
- Executes DROP statements in correct order
- Removes all tables and custom types
- Resets migration version to 0

**Final Result**:
- Only `schema_migrations` table remains
- All business tables removed
- All custom types removed
- Migration version: 0 (clean state)

### 5. Database Inspection Commands

#### Connect to Database
```bash
docker exec -it simplebankcont psql -U username -d dbname
```

#### Common psql Commands
```sql
-- List all tables
\dt

-- Show table structure
\d accounts
\d entries
\d transfers

-- List custom types
SELECT typname FROM pg_type WHERE typname IN ('currency_enum', 'transfer_status');

-- Check migration history
SELECT * FROM schema_migrations;

-- Exit psql
\q
```

#### One-liner Database Inspection
```bash
docker exec -it simplebankcont psql -U username -d dbname -c "\dt; SELECT * FROM schema_migrations;"
```

### 6. Standard Migration Workflow

#### Development Workflow
1. **Start fresh**: `make postgres` → `make createdb`
2. **Apply migrations**: `make migrateup`
3. **Develop and test**: Make code changes
4. **Rollback if needed**: `make migratedown`
5. **Re-apply**: `make migrateup`

#### Production Workflow
1. **Incremental updates**: `make migrateup1` (apply one migration at a time)
2. **Verify each step**: `make migrateversion`
3. **Rollback single migration**: `make migratedown1` (if issues)

### 7. Migration Best Practices

#### Why These Practices Matter
- **Reversibility**: Every up migration must have a corresponding down migration
- **Order matters**: Foreign key dependencies require careful DROP order
- **Testing**: Always test up/down cycle in development
- **Version control**: Migration files should be committed to git

#### Down Migration Guidelines
- Drop tables in reverse order of creation
- Drop dependent objects before referenced objects
- Use `IF EXISTS` to prevent errors
- Test rollback process thoroughly

### 8. Troubleshooting

#### Common Issues and Solutions

**Issue**: Migration stuck or corrupted
**Solution**: 
```bash
make migrateforce VERSION=<target_version>
```

**Issue**: Database objects exist but migration shows "no migration"
**Solution**: 
1. Fix down migration file
2. Force to correct version
3. Run proper rollback

**Issue**: Foreign key constraint errors during rollback
**Solution**: Ensure tables are dropped in correct order in down migration

### 9. Emergency Recovery

#### Complete Reset (Development Only)
```bash
make dropdb      # WARNING: Destroys all data
make createdb
make migrateup
```

#### Partial Reset (Safer)
```bash
make migratedown  # Rollback all migrations
make migrateup    # Re-apply all migrations
```

## Security Best Practices

### ⚠️ CRITICAL: Never Commit Credentials

**What NOT to do:**
- Never put actual passwords in documentation
- Never commit `.env` files to version control
- Never hardcode database credentials in code

**What TO do:**
- Use placeholder values in documentation (e.g., `your_db_user`, `your_secure_password`)
- Add `.env` to `.gitignore`
- Use environment variables in production
- Use secrets management systems (AWS Secrets Manager, HashiCorp Vault)

### Production Security Checklist

#### Environment Variables
```bash
# Instead of .env file in production, use:
export DB_USER="actual_user"
export DB_PASSWORD="$(get_secret_from_vault)"
export DB_NAME="prod_database"
```

#### SSL/TLS Configuration
```bash
# For production, use SSL:
migrate -path db/migration -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=require" up
```

#### Network Security
- Use VPC/private networks
- Restrict database access to application servers only
- Use connection pooling
- Enable audit logging

### Example .gitignore
```gitignore
# Environment files
.env
.env.local
.env.production

# Database dumps
*.sql
*.dump

# Logs
*.log

# Build artifacts
bin/
dist/
```

## Summary

This guide demonstrates the complete lifecycle of database migrations in the Simple Bank project, from initial setup through troubleshooting and recovery. The key learning points are:

1. **Proper setup**: Makefile commands and environment configuration
2. **Complete migrations**: Both up and down files must be properly implemented
3. **State management**: Understanding migration version tracking
4. **Recovery procedures**: How to fix inconsistent migration states
5. **Best practices**: Standard workflows for development and production
6. **Security**: Never expose credentials in documentation or version control

The migration system is now fully functional and can be used for ongoing database schema management.
