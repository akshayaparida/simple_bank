# Makefile for simple_bank project

# Include environment variables if .env file exists
-include .env

# Database configuration - loaded from .env file
DB_CONTAINER=simplebankcont
DB_IMAGE=postgres:17.5-alpine

# Default target
all: build

# Build the application
build:
	go build -o bin/simple_bank ./...

# Run the application
run: build
	./bin/simple_bank

# Run tests
test:
	go test -v ./...

# Clean up generated files
clean:
	rm -rf bin/

# Start PostgreSQL container using Docker
postgres:
	docker run --name $(DB_CONTAINER) \
		-p $(DB_PORT):5432 \
		-e POSTGRES_USER=$(DB_USER) \
		-e POSTGRES_PASSWORD=$(DB_PASSWORD) \
		-d $(DB_IMAGE)

# Create the database inside the running container
createdb:
	docker exec -it $(DB_CONTAINER) \
		createdb --username=$(DB_USER) --owner=$(DB_USER) $(DB_NAME)

# Drop the database (dangerous!)
dropdb:
	docker exec -it $(DB_CONTAINER) \
		dropdb $(DB_NAME)

# Stop and remove the database container
stop-postgres:
	docker stop $(DB_CONTAINER)
	docker rm $(DB_CONTAINER)

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

# Generate Go code from SQL queries using sqlc
sqlc:
	sqlc generate

.PHONY: all build run test clean postgres createdb dropdb stop-postgres migrateup migratedown migrateup1 migratedown1 migrateversion migrateforce sqlc





