---
name: python-best-practices
description: Use when writing, reviewing, or refactoring FastAPI/Python backend code. Triggers on FastAPI endpoints, Pydantic models, SQLAlchemy queries, async Python code, or Python API architecture. Contains 38 architectural rules across 8 categories.
user-invocable: true
---

# Python & FastAPI Best Practices

Architectural patterns and performance guide for FastAPI, Pydantic v2, and SQLAlchemy 2.0 applications. Contains 38 rules across 8 categories, prioritized by impact. Focuses on patterns that linters cannot catch — async correctness, dependency injection, session management, schema design.

## When to Apply

Reference these guidelines when:
- Writing new FastAPI endpoints or routers
- Designing Pydantic request/response models
- Implementing SQLAlchemy database queries or sessions
- Reviewing async Python code for correctness
- Refactoring existing FastAPI applications
- Setting up project structure for a new Python API

## Target Versions

- Python 3.11+
- FastAPI 0.104+
- Pydantic 2.x
- SQLAlchemy 2.0+
- Alembic 1.12+

## Rule Categories by Priority

| Priority | Category | Impact | Prefix | Rules |
|----------|----------|--------|--------|-------|
| 1 | Async Correctness | CRITICAL | `async-` | 5 |
| 2 | Dependency Injection | CRITICAL | `di-` | 5 |
| 3 | Database Patterns | HIGH | `db-` | 6 |
| 4 | Pydantic Models | HIGH | `pydantic-` | 5 |
| 5 | Error Handling | MEDIUM-HIGH | `error-` | 4 |
| 6 | API Design | MEDIUM | `api-` | 5 |
| 7 | Testing Patterns | MEDIUM | `test-` | 4 |
| 8 | Project Structure | LOW-MEDIUM | `structure-` | 4 |

## Quick Reference

### 1. Async Correctness (CRITICAL)

- `async-no-blocking` - Never call blocking I/O in async endpoints
- `async-gather-parallel` - Use asyncio.gather for independent async calls
- `async-taskgroup` - Use TaskGroup for structured concurrency with error handling
- `async-connection-pool` - Configure async connection pools, don't create per-request
- `async-sync-in-threadpool` - Run sync code in threadpool when unavoidable

### 2. Dependency Injection (CRITICAL)

- `di-yield-dependencies` - Use yield for setup/teardown lifecycle
- `di-annotated-depends` - Use Annotated[T, Depends()] for reusable type aliases
- `di-caching` - Understand use_cache behavior for request-scoped singletons
- `di-class-dependencies` - Group related dependencies in injectable classes
- `di-no-global-state` - Never use module-level mutable state, inject instead

### 3. Database Patterns (HIGH)

- `db-session-dependency` - Provide sessions via DI with proper commit/rollback
- `db-n-plus-one` - Prevent N+1 with selectinload/joinedload
- `db-async-session` - Use AsyncSession with async engine
- `db-transaction-boundaries` - Explicit transaction scoping per operation
- `db-reversible-migrations` - Every Alembic migration must have a downgrade
- `db-select-api` - Use select() API, not legacy Query

### 4. Pydantic Models (HIGH)

- `pydantic-separate-schemas` - Separate Create/Read/Update schemas per resource
- `pydantic-field-validators` - Use field_validator and model_validator correctly
- `pydantic-base-settings` - Use BaseSettings for environment configuration
- `pydantic-model-config` - Use model_config dict, not inner class Config
- `pydantic-v2-serialization` - Use model_dump/model_validate, not dict/parse_obj

### 5. Error Handling (MEDIUM-HIGH)

- `error-exception-handlers` - Register app-wide exception handlers
- `error-structured-responses` - Consistent error response schema
- `error-http-exception` - Use HTTPException with appropriate status codes
- `error-validation-errors` - Customize Pydantic validation error format

### 6. API Design (MEDIUM)

- `api-router-organization` - One router per domain with tags and prefixes
- `api-response-model` - Always declare response_model on endpoints
- `api-lifespan` - Use lifespan context manager, not on_event
- `api-middleware-order` - Understand middleware execution order (LIFO)
- `api-versioning` - Version APIs via URL prefix

### 7. Testing Patterns (MEDIUM)

- `test-async-client` - Use httpx.AsyncClient with ASGITransport
- `test-dependency-overrides` - Override dependencies for isolated testing
- `test-factories` - Use factory functions or factory_boy for test data
- `test-db-isolation` - Transaction rollback between tests for isolation

### 8. Project Structure (LOW-MEDIUM)

- `structure-domain-packages` - Organize by domain, not by layer
- `structure-config-module` - Centralize configuration in a settings module
- `structure-init-exports` - Use __init__.py for clean public APIs
- `structure-alembic-setup` - Configure Alembic with async support and naming conventions

## Linting & Formatting

For Ruff, mypy, Black, and other tooling configuration, see the **code-quality** skill. This skill covers architectural patterns only.

## Full Compiled Document

For the complete guide with all rules expanded and code examples: `AGENTS.md`
