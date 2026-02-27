# Python & FastAPI Best Practices — Full Reference

Architectural patterns and performance guide for FastAPI, Pydantic v2, and SQLAlchemy 2.0 applications. 38 rules across 8 categories, prioritized by impact. Targets Python 3.11+, FastAPI 0.104+, Pydantic 2.x, SQLAlchemy 2.0+.

## Table of Contents

1. [Async Correctness (CRITICAL)](#1-async-correctness-critical)
2. [Dependency Injection (CRITICAL)](#2-dependency-injection-critical)
3. [Database Patterns (HIGH)](#3-database-patterns-high)
4. [Pydantic Models (HIGH)](#4-pydantic-models-high)
5. [Error Handling (MEDIUM-HIGH)](#5-error-handling-medium-high)
6. [API Design (MEDIUM)](#6-api-design-medium)
7. [Testing Patterns (MEDIUM)](#7-testing-patterns-medium)
8. [Project Structure (LOW-MEDIUM)](#8-project-structure-low-medium)

---

## 1. Async Correctness (CRITICAL)

FastAPI runs on an async event loop. Blocking it freezes all concurrent requests.

### `async-no-blocking`

**Impact: CRITICAL**

Never call blocking I/O (file reads, synchronous HTTP clients, `time.sleep`) inside async endpoints. This blocks the entire event loop and stalls all concurrent requests.

**Incorrect:**

```python
import time
import requests
from fastapi import FastAPI

app = FastAPI()

@app.get("/data")
async def get_data():
    # WRONG: requests is synchronous — blocks the event loop
    response = requests.get("https://api.example.com/data")
    time.sleep(1)  # WRONG: blocks the event loop
    return response.json()
```

**Correct:**

```python
import httpx
from fastapi import FastAPI, Request

app = FastAPI()

@app.get("/data")
async def get_data(request: Request):
    # Use a shared client from app.state — see async-connection-pool
    response = await request.app.state.http_client.get(
        "https://api.example.com/data"
    )
    return response.json()
```

**Context:** Use `httpx.AsyncClient` instead of `requests`. Use `asyncio.sleep` instead of `time.sleep`. Use `aiofiles` for file I/O. Create the client at startup and store it on `app.state` — see `async-connection-pool` for the full lifecycle pattern. If you must call a sync library, see `async-sync-in-threadpool`.

---

### `async-gather-parallel`

**Impact: CRITICAL**

Use `asyncio.gather()` to run independent async operations concurrently instead of awaiting them sequentially.

**Incorrect:**

```python
@app.get("/dashboard")
async def get_dashboard(user_id: int):
    # WRONG: sequential — total time = sum of all calls
    user = await get_user(user_id)
    orders = await get_orders(user_id)
    notifications = await get_notifications(user_id)
    return {"user": user, "orders": orders, "notifications": notifications}
```

**Correct:**

```python
@app.get("/dashboard")
async def get_dashboard(user_id: int):
    # RIGHT: parallel — total time = max of all calls
    user, orders, notifications = await asyncio.gather(
        get_user(user_id),
        get_orders(user_id),
        get_notifications(user_id),
    )
    return {"user": user, "orders": orders, "notifications": notifications}
```

**Context:** Only parallelize operations that are truly independent. If `get_orders` needs the `user` result, it must be sequential.

---

### `async-taskgroup`

**Impact: CRITICAL**

Use `asyncio.TaskGroup` (Python 3.11+) for structured concurrency. Unlike `gather()`, TaskGroup cancels remaining tasks when one fails.

**Incorrect:**

```python
@app.post("/batch")
async def process_batch(items: list[Item]):
    # WRONG: gather continues other tasks even when one fails,
    # potentially leaving partial state
    results = await asyncio.gather(
        *[process_item(item) for item in items],
        return_exceptions=True,
    )
    # Must manually check each result for exceptions
    errors = [r for r in results if isinstance(r, Exception)]
    if errors:
        raise HTTPException(500, detail="Partial failure")
    return results
```

**Correct:**

```python
@app.post("/batch")
async def process_batch(items: list[Item]):
    results = []
    try:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(process_item(item)) for item in items]
        results = [t.result() for t in tasks]
    except* ValueError as eg:
        raise HTTPException(422, detail=[str(e) for e in eg.exceptions])
    except* Exception as eg:
        raise HTTPException(500, detail="Batch processing failed")
    return results
```

**Context:** TaskGroup guarantees structured cleanup — if any task raises, all remaining tasks are cancelled and awaited. Use `gather()` for fire-and-forget parallelism where partial success is acceptable. Use TaskGroup when all-or-nothing semantics are needed.

---

### `async-connection-pool`

**Impact: CRITICAL**

Create HTTP clients and connection pools at application startup, not per-request. Per-request clients cause TCP connection churn and socket exhaustion.

**Incorrect:**

```python
@app.get("/weather/{city}")
async def get_weather(city: str):
    # WRONG: creates a new client (and TCP connection) per request
    async with httpx.AsyncClient() as client:
        response = await client.get(f"https://api.weather.com/v1/{city}")
    return response.json()
```

**Correct:**

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(
        base_url="https://api.weather.com/v1",
        timeout=30.0,
        limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
    )
    yield
    await app.state.http_client.aclose()

app = FastAPI(lifespan=lifespan)

@app.get("/weather/{city}")
async def get_weather(city: str, request: Request):
    response = await request.app.state.http_client.get(f"/{city}")
    return response.json()
```

**Context:** Store shared clients on `app.state` and initialize them in the lifespan handler. Use `base_url` to pin the downstream host — never accept arbitrary URLs from user input (SSRF risk). This applies to any reusable connection: HTTP clients, Redis clients, message queue connections.

---

### `async-sync-in-threadpool`

**Impact: HIGH**

When you must call synchronous blocking code from an async endpoint, run it in a thread pool to avoid blocking the event loop.

**Incorrect:**

```python
from PIL import Image

@app.post("/resize")
async def resize_image(file: UploadFile):
    contents = await file.read()
    # WRONG: PIL operations are CPU-bound and blocking
    img = Image.open(io.BytesIO(contents))
    img = img.resize((800, 600))
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return Response(content=buffer.getvalue(), media_type="image/png")
```

**Correct:**

```python
from PIL import Image
from starlette.concurrency import run_in_threadpool

def _resize_sync(contents: bytes) -> bytes:
    img = Image.open(io.BytesIO(contents))
    img = img.resize((800, 600))
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return buffer.getvalue()

MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB

@app.post("/resize")
async def resize_image(file: UploadFile):
    if file.content_type not in ("image/png", "image/jpeg"):
        raise HTTPException(415, detail="Unsupported media type")
    contents = await file.read(MAX_IMAGE_SIZE + 1)
    if len(contents) > MAX_IMAGE_SIZE:
        raise HTTPException(413, detail="File too large")
    result = await run_in_threadpool(_resize_sync, contents)
    return Response(content=result, media_type="image/png")
```

**Context:** Alternatively, define the endpoint as `def` (not `async def`) — FastAPI automatically runs sync endpoints in a threadpool. But if the endpoint mixes async and sync calls, use `run_in_threadpool` explicitly for the sync parts. Always validate file size and content-type before processing uploads. Set `PIL.Image.MAX_IMAGE_PIXELS` to guard against decompression bombs.

---

## 2. Dependency Injection (CRITICAL)

FastAPI's DI system is the backbone for managing resources. Misusing it leads to leaks, race conditions, and untestable code.

### `di-yield-dependencies`

**Impact: CRITICAL**

Use `yield` in dependencies for setup/teardown lifecycle. Code after `yield` always runs, even if the endpoint raises.

**Incorrect:**

```python
def get_db():
    # WRONG: no cleanup if the endpoint raises
    db = SessionLocal()
    return db
```

**Correct:**

```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

**Context:** The code after `yield` is FastAPI's equivalent of a `finally` block. Use it for database sessions, file handles, temporary resources, and anything that needs cleanup.

---

### `di-annotated-depends`

**Impact: HIGH**

Use `Annotated` with `Depends()` to create reusable dependency type aliases. This eliminates repetition and makes dependencies swappable.

**Incorrect:**

```python
@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ...

@app.get("/users/{user_id}/orders")
async def get_user_orders(
    user_id: int,
    db: AsyncSession = Depends(get_db),  # repeated everywhere
    current_user: User = Depends(get_current_user),  # repeated everywhere
):
    ...
```

**Correct:**

```python
from typing import Annotated

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]

@app.get("/users/{user_id}")
async def get_user(user_id: int, db: DB, current_user: CurrentUser):
    ...

@app.get("/users/{user_id}/orders")
async def get_user_orders(user_id: int, db: DB, current_user: CurrentUser):
    ...
```

**Context:** Define dependency aliases in a shared module (e.g., `app/deps.py`). This is the idiomatic FastAPI pattern as of v0.95+.

---

### `di-caching`

**Impact: HIGH**

Understand that `Depends()` caches results per-request by default. The same dependency function returns the same instance within a single request. Use `use_cache=False` only when you need a fresh instance.

**Incorrect:**

```python
async def get_db():
    async with async_session_maker() as session:
        yield session

@app.get("/example")
async def example(
    db1: Annotated[AsyncSession, Depends(get_db)],
    # WRONG assumption: this creates a second session
    # Actually returns the same session as db1 (cached)
    db2: Annotated[AsyncSession, Depends(get_db)],
):
    ...
```

**Correct:**

```python
@app.get("/example")
async def example(
    db: Annotated[AsyncSession, Depends(get_db)],
    # Same session is reused — this is correct and intentional
    service: Annotated[UserService, Depends(get_user_service)],
    # get_user_service also depends on get_db — gets the same session
):
    ...

# Only use use_cache=False when you genuinely need separate instances
@app.get("/compare")
async def compare(
    primary: Annotated[AsyncSession, Depends(get_db)],
    secondary: Annotated[AsyncSession, Depends(get_db, use_cache=False)],
):
    ...
```

**Context:** The default caching is usually what you want — it ensures all dependencies in a request share the same database session and transaction.

---

### `di-class-dependencies`

**Impact: MEDIUM**

Group related dependencies into injectable classes. FastAPI can inject classes directly when `__init__` parameters match request data.

**Incorrect:**

```python
@app.get("/items")
async def list_items(
    skip: int = 0,
    limit: int = 100,
    sort_by: str = "created_at",
    order: str = "desc",
    search: str | None = None,
):
    # Many query params repeated across endpoints
    ...
```

**Correct:**

```python
class PaginationParams:
    def __init__(
        self,
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=1000),
        sort_by: str = Query("created_at"),
        order: Literal["asc", "desc"] = Query("desc"),
    ):
        self.skip = skip
        self.limit = limit
        self.sort_by = sort_by
        self.order = order

Pagination = Annotated[PaginationParams, Depends()]

@app.get("/items")
async def list_items(pagination: Pagination, search: str | None = None):
    ...

@app.get("/orders")
async def list_orders(pagination: Pagination):
    ...
```

**Context:** `Depends()` with no argument on a class means FastAPI injects the class itself. This bundles related parameters and adds validation via `Query()`.

---

### `di-no-global-state`

**Impact: CRITICAL**

Never use module-level mutable state. It is shared across all requests and workers, causing race conditions. Inject state through dependencies.

**Incorrect:**

```python
# WRONG: module-level mutable state
_cache: dict[str, Any] = {}
_db_pool = None

@app.get("/cached/{key}")
async def get_cached(key: str):
    if key not in _cache:
        _cache[key] = await fetch_from_db(key)  # race condition
    return _cache[key]
```

**Correct:**

```python
from functools import lru_cache

class CacheService:
    def __init__(self):
        self._store: dict[str, Any] = {}

    async def get_or_fetch(self, key: str, fetcher) -> Any:
        if key not in self._store:
            self._store[key] = await fetcher(key)
        return self._store[key]

@lru_cache
def get_cache_service() -> CacheService:
    return CacheService()

Cache = Annotated[CacheService, Depends(get_cache_service)]

@app.get("/cached/{key}")
async def get_cached(key: str, cache: Cache):
    return await cache.get_or_fetch(key, fetch_from_db)
```

**Context:** Use `@lru_cache` on the dependency function for application-scoped singletons. For request-scoped state, use the default DI caching. For true shared state, use Redis or another external store.

---

## 3. Database Patterns (HIGH)

SQLAlchemy 2.0 introduced a new query API. Use `select()` style, not legacy `Query`.

### `db-session-dependency`

**Impact: HIGH**

Provide database sessions via FastAPI dependency injection with proper commit/rollback handling.

**Incorrect:**

```python
# WRONG: session created inline, no cleanup guarantee
@app.post("/users")
async def create_user(data: UserCreate):
    session = AsyncSession(engine)
    user = User(**data.model_dump())
    session.add(user)
    await session.commit()
    return user
```

**Correct:**

```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

DB = Annotated[AsyncSession, Depends(get_db)]

@app.post("/users")
async def create_user(data: UserCreate, db: DB):
    user = User(**data.model_dump())
    db.add(user)
    await db.flush()  # get generated ID without committing
    return user
    # commit happens automatically in the dependency teardown
```

**Context:** Use `flush()` in endpoints to get generated values (like auto-increment IDs) without committing. The dependency handles commit on success and rollback on failure.

---

### `db-n-plus-one`

**Impact: HIGH**

Prevent N+1 queries by eagerly loading relationships with `selectinload` or `joinedload`.

**Incorrect:**

```python
@app.get("/users")
async def list_users(db: DB):
    result = await db.execute(select(User))
    users = result.scalars().all()
    # WRONG: accessing user.orders triggers a lazy load query per user
    return [
        {"name": u.name, "order_count": len(u.orders)}
        for u in users
    ]
```

**Correct:**

```python
from sqlalchemy.orm import selectinload

@app.get("/users")
async def list_users(db: DB):
    result = await db.execute(
        select(User).options(selectinload(User.orders))
    )
    users = result.scalars().all()
    return [
        {"name": u.name, "order_count": len(u.orders)}
        for u in users
    ]
```

**Context:** Use `selectinload` for one-to-many (emits a second SELECT with IN clause). Use `joinedload` for many-to-one and one-to-one (uses JOIN). For deeply nested relationships, chain them: `selectinload(User.orders).selectinload(Order.items)`. In async SQLAlchemy, lazy loading raises `MissingGreenlet` — you must always eager load.

---

### `db-async-session`

**Impact: HIGH**

Use `AsyncSession` with `create_async_engine` for non-blocking database access.

**Incorrect:**

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

# WRONG: synchronous engine blocks the event loop
engine = create_engine("postgresql://user:password@localhost/db")  # Never hardcode credentials — use BaseSettings (see pydantic-base-settings)

def get_db():
    with Session(engine) as session:
        yield session
```

**Correct:**

```python
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    pool_size=20,
    max_overflow=10,
)

async_session_maker = async_sessionmaker(engine, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

**Context:** Use `asyncpg` driver for PostgreSQL (`postgresql+asyncpg://`), `aiosqlite` for SQLite. Set `expire_on_commit=False` to access attributes after commit without re-querying.

---

### `db-transaction-boundaries`

**Impact: MEDIUM-HIGH**

Use explicit transaction boundaries. Don't let transactions span entire request lifecycles when only part of the request needs transactional guarantees.

**Incorrect:**

```python
@app.post("/transfer")
async def transfer(data: TransferRequest, db: DB):
    # WRONG: the email send is inside the implicit transaction
    sender = await db.get(Account, data.sender_id)
    receiver = await db.get(Account, data.receiver_id)
    sender.balance -= data.amount
    receiver.balance += data.amount
    await send_email(sender.email, "Transfer complete")  # not transactional
    # commit happens in dependency teardown — after email
```

**Correct:**

```python
@app.post("/transfer")
async def transfer(data: TransferRequest, db: DB):
    async with db.begin_nested():
        sender = await db.get(Account, data.sender_id, with_for_update=True)
        receiver = await db.get(Account, data.receiver_id, with_for_update=True)
        if sender.balance < data.amount:
            raise HTTPException(400, detail="Insufficient funds")
        sender.balance -= data.amount
        receiver.balance += data.amount
    # Email is outside the nested transaction
    await send_email(sender.email, "Transfer complete")
```

**Context:** Use `begin_nested()` for savepoints within the request-scoped transaction. Use `with_for_update=True` (SELECT FOR UPDATE) to prevent concurrent modification of the same rows.

---

### `db-reversible-migrations`

**Impact: MEDIUM**

Every Alembic migration must have a working `downgrade()`. Never leave it as `pass`.

**Incorrect:**

```python
def upgrade():
    op.add_column("users", sa.Column("phone", sa.String(20)))

def downgrade():
    pass  # WRONG: can't roll back
```

**Correct:**

```python
def upgrade():
    op.add_column("users", sa.Column("phone", sa.String(20)))

def downgrade():
    op.drop_column("users", "phone")
```

**Context:** For destructive migrations (dropping columns with data), preserve data in the downgrade by recreating the column and restoring from a backup table or default value. Test downgrades in CI by running `alembic downgrade -1` after each `upgrade head`.

---

### `db-select-api`

**Impact: MEDIUM**

Use the SQLAlchemy 2.0 `select()` API, not the legacy `session.query()` pattern.

**Incorrect:**

```python
# WRONG: legacy Query API (SQLAlchemy 1.x style)
users = db.query(User).filter(User.active == True).all()
user = db.query(User).get(user_id)
count = db.query(User).count()
```

**Correct:**

```python
from sqlalchemy import select, func

# SQLAlchemy 2.0 select() API
result = await db.execute(select(User).where(User.active == True))
users = result.scalars().all()

user = await db.get(User, user_id)

result = await db.execute(select(func.count()).select_from(User))
count = result.scalar_one()
```

**Context:** The `select()` API works with both sync and async sessions. The legacy `Query` API does not support async. Always migrate to `select()` for forward compatibility.

---

## 4. Pydantic Models (HIGH)

Pydantic v2 has significant API changes from v1. Use v2 patterns exclusively.

### `pydantic-separate-schemas`

**Impact: HIGH**

Create separate schemas for Create, Read, and Update operations. Never use a single model for all three.

**Incorrect:**

```python
# WRONG: one model for everything
class User(BaseModel):
    id: int | None = None  # optional for create, required for read
    name: str
    email: str
    password: str | None = None  # needed for create, shouldn't appear in response
    created_at: datetime | None = None
```

**Correct:**

```python
class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserRead(UserBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class UserUpdate(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
    password: str | None = None
```

**Context:** `UserUpdate` makes all fields optional for PATCH semantics. `UserRead` uses `from_attributes=True` to serialize SQLAlchemy model instances. Never expose `password` in read schemas.

---

### `pydantic-field-validators`

**Impact: HIGH**

Use `field_validator` and `model_validator` with the v2 decorator syntax.

**Incorrect:**

```python
# WRONG: Pydantic v1 syntax
class UserCreate(BaseModel):
    name: str
    email: str

    @validator("name")
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError("Name cannot be empty")
        return v.strip()

    @root_validator
    def check_passwords_match(cls, values):
        ...
```

**Correct:**

```python
from pydantic import field_validator, model_validator

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    password_confirm: str

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Name cannot be empty")
        return v.strip()

    @model_validator(mode="after")
    def check_passwords_match(self) -> Self:
        if self.password != self.password_confirm:
            raise ValueError("Passwords do not match")
        return self
```

**Context:** `field_validator` replaces `@validator`. `model_validator(mode="after")` replaces `@root_validator`. Use `mode="before"` for validators that need to run on raw input data before field parsing.

---

### `pydantic-base-settings`

**Impact: HIGH**

Use `BaseSettings` from `pydantic-settings` for environment-based configuration.

**Incorrect:**

```python
import os

# WRONG: manual env parsing, no validation, no defaults
DATABASE_URL = os.environ["DATABASE_URL"]
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"
MAX_CONNECTIONS = int(os.environ.get("MAX_CONNECTIONS", "10"))
```

**Correct:**

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    database_url: str
    debug: bool = False
    max_connections: int = Field(10, ge=1, le=100)
    api_key: str = Field(..., min_length=1)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

settings = Settings()
```

**Context:** `BaseSettings` auto-reads from environment variables and `.env` files. Field names map to env vars (case-insensitive by default). Install with `pip install pydantic-settings` — it's a separate package in Pydantic v2.

---

### `pydantic-model-config`

**Impact: MEDIUM**

Use `model_config = ConfigDict(...)` instead of the legacy inner `class Config`.

**Incorrect:**

```python
# WRONG: Pydantic v1 style
class UserRead(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True
        json_schema_extra = {"example": {"id": 1, "name": "Alice"}}
```

**Correct:**

```python
from pydantic import ConfigDict

class UserRead(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(
        from_attributes=True,  # replaces orm_mode
        json_schema_extra={"examples": [{"id": 1, "name": "Alice"}]},
    )
```

**Context:** `from_attributes=True` replaces `orm_mode=True`. `ConfigDict` is a typed dict, so IDEs provide autocomplete.

---

### `pydantic-v2-serialization`

**Impact: MEDIUM**

Use v2 serialization methods: `model_dump()`, `model_validate()`, `model_dump_json()`.

**Incorrect:**

```python
# WRONG: Pydantic v1 methods
data = user.dict()
data_json = user.json()
user = User.parse_obj(raw_data)
user = User.parse_raw(json_string)
user = User.from_orm(db_user)
```

**Correct:**

```python
# Pydantic v2 methods
data = user.model_dump()
data = user.model_dump(exclude_unset=True)  # for PATCH operations
data_json = user.model_dump_json()
user = User.model_validate(raw_data)
user = User.model_validate_json(json_string)
user = User.model_validate(db_user, from_attributes=True)
```

**Context:** `exclude_unset=True` is essential for PATCH endpoints — it distinguishes between "field not provided" and "field explicitly set to None". All v1 methods still work but emit deprecation warnings.

---

## 5. Error Handling (MEDIUM-HIGH)

Consistent error handling makes APIs predictable and debuggable.

### `error-exception-handlers`

**Impact: HIGH**

Register application-wide exception handlers for common error types instead of catching exceptions in every endpoint.

**Incorrect:**

```python
@app.get("/users/{user_id}")
async def get_user(user_id: int, db: DB):
    try:
        user = await db.get(User, user_id)
        if not user:
            raise HTTPException(404, detail="User not found")
        return user
    except SQLAlchemyError as e:
        raise HTTPException(500, detail="Database error")
    except Exception as e:
        raise HTTPException(500, detail="Internal error")
```

**Correct:**

```python
# Register handlers once at app level
@app.exception_handler(EntityNotFoundError)
async def entity_not_found_handler(request: Request, exc: EntityNotFoundError):
    return JSONResponse(
        status_code=404,
        content={"error": "not_found", "message": str(exc)},
    )

@app.exception_handler(SQLAlchemyError)
async def database_error_handler(request: Request, exc: SQLAlchemyError):
    logger.error("Database error", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={"error": "database_error", "message": "A database error occurred"},
    )

# Endpoints stay clean
@app.get("/users/{user_id}")
async def get_user(user_id: int, db: DB):
    user = await db.get(User, user_id)
    if not user:
        raise EntityNotFoundError(f"User {user_id}")
    return user
```

**Context:** Define custom exception classes for your domain (e.g., `EntityNotFoundError`, `PermissionDeniedError`). Register handlers for each. This centralizes error formatting and logging.

---

### `error-structured-responses`

**Impact: HIGH**

Use a consistent error response schema across all endpoints.

**Incorrect:**

```python
# WRONG: inconsistent error shapes
raise HTTPException(400, detail="Bad request")
raise HTTPException(400, detail={"message": "Bad request"})
raise HTTPException(400, detail={"errors": ["field required"]})
return {"error": True, "msg": "Something went wrong"}
```

**Correct:**

```python
class ErrorResponse(BaseModel):
    error: str
    message: str
    details: list[str] | None = None

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error=exc.detail if isinstance(exc.detail, str) else "error",
            message=str(exc.detail),
        ).model_dump(),
    )
```

**Context:** Document the error schema in your OpenAPI spec. Clients should be able to parse every error response with the same model.

---

### `error-http-exception`

**Impact: MEDIUM**

Use `HTTPException` with semantically correct status codes. Don't overuse 400 or 500.

**Incorrect:**

```python
# WRONG: everything is 400
if not user:
    raise HTTPException(400, detail="User not found")  # should be 404
if not authorized:
    raise HTTPException(400, detail="Not allowed")  # should be 403
if duplicate:
    raise HTTPException(400, detail="Already exists")  # should be 409
```

**Correct:**

```python
if not user:
    raise HTTPException(status_code=404, detail="User not found")
if not authorized:
    raise HTTPException(status_code=403, detail="Insufficient permissions")
if duplicate:
    raise HTTPException(status_code=409, detail="User with this email already exists")
if rate_limited:
    raise HTTPException(
        status_code=429,
        detail="Rate limit exceeded",
        headers={"Retry-After": "60"},
    )
```

**Context:** Common status codes: 400 (validation/client error), 401 (unauthenticated), 403 (unauthorized), 404 (not found), 409 (conflict), 422 (validation error — FastAPI default for Pydantic failures), 429 (rate limited).

---

### `error-validation-errors`

**Impact: MEDIUM**

Customize Pydantic validation error responses for client-friendly messages.

**Incorrect:**

```python
# Default FastAPI validation errors look like:
# {"detail": [{"loc": ["body", "email"], "msg": "value is not a valid email address", "type": "value_error.email"}]}
# This is noisy and hard for frontend devs to parse
```

**Correct:**

```python
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
):
    errors = []
    for error in exc.errors():
        field = ".".join(str(loc) for loc in error["loc"] if loc != "body")
        errors.append({"field": field, "message": error["msg"]})
    return JSONResponse(
        status_code=422,
        content={
            "error": "validation_error",
            "message": "Request validation failed",
            "details": errors,
        },
    )
```

**Context:** Strip the "body" prefix from field locations since clients don't need to know about FastAPI's internal structure. Map technical error types to human-readable messages where possible.

---

## 6. API Design (MEDIUM)

Well-structured APIs are easier to maintain, document, and evolve.

### `api-router-organization`

**Impact: MEDIUM**

Organize endpoints into routers by domain, with consistent prefixes and tags.

**Incorrect:**

```python
# WRONG: all endpoints in one file on the app instance
app = FastAPI()

@app.get("/users")
async def list_users(): ...

@app.get("/users/{id}")
async def get_user(): ...

@app.get("/orders")
async def list_orders(): ...

@app.post("/orders")
async def create_order(): ...
```

**Correct:**

```python
# app/routers/users.py
router = APIRouter(prefix="/users", tags=["users"])

@router.get("/")
async def list_users(db: DB) -> list[UserRead]: ...

@router.get("/{user_id}")
async def get_user(user_id: int, db: DB) -> UserRead: ...

# app/main.py
app = FastAPI()
app.include_router(users.router)
app.include_router(orders.router)
```

**Context:** Tags group endpoints in the OpenAPI docs. Prefixes avoid repeating the resource name in every decorator. Keep one router per domain module.

---

### `api-response-model`

**Impact: MEDIUM**

Always declare `response_model` or return type annotation on endpoints. This enables automatic serialization, validation, and OpenAPI documentation.

**Incorrect:**

```python
@router.get("/users/{user_id}")
async def get_user(user_id: int, db: DB):
    # WRONG: returns SQLAlchemy model directly — exposes all fields
    return await db.get(User, user_id)
```

**Correct:**

```python
@router.get("/users/{user_id}")
async def get_user(user_id: int, db: DB) -> UserRead:
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="User not found")
    return user  # automatically serialized through UserRead

# Or with response_model for more control
@router.get("/users/{user_id}", response_model=UserRead)
async def get_user(user_id: int, db: DB):
    ...
```

**Context:** Return type annotations (FastAPI 0.95+) and `response_model` serve the same purpose. Use return annotations for simplicity. Use `response_model` when you need `response_model_exclude` or `response_model_by_alias`.

---

### `api-lifespan`

**Impact: MEDIUM**

Use the `lifespan` context manager for startup/shutdown logic. The `@app.on_event` decorator is deprecated.

**Incorrect:**

```python
# WRONG: deprecated event handlers
@app.on_event("startup")
async def startup():
    app.state.db_pool = await create_pool()

@app.on_event("shutdown")
async def shutdown():
    await app.state.db_pool.close()
```

**Correct:**

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.db_pool = await create_pool()
    app.state.http_client = httpx.AsyncClient()
    yield
    # Shutdown
    await app.state.http_client.aclose()
    await app.state.db_pool.close()

app = FastAPI(lifespan=lifespan)
```

**Context:** The lifespan handler guarantees shutdown code runs. It replaces both `on_event("startup")` and `on_event("shutdown")` with a single, clean context manager.

---

### `api-middleware-order`

**Impact: MEDIUM**

Understand that middleware executes in LIFO order (last added runs first on request, last on response). Order matters for authentication, CORS, and logging.

**Incorrect:**

```python
# WRONG: CORS middleware added after auth — auth rejects preflight requests
app.add_middleware(AuthMiddleware)
app.add_middleware(CORSMiddleware, allow_origins=["*"])
```

**Correct:**

```python
# RIGHT: CORS first (added last), then logging, then auth
# Execution order on request: CORS → Logging → Auth → endpoint
app.add_middleware(AuthMiddleware)  # runs third (closest to endpoint)
app.add_middleware(LoggingMiddleware)  # runs second
app.add_middleware(
    CORSMiddleware,  # runs first (outermost)
    allow_origins=["https://app.example.com"],
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

**Context:** Think of middleware as layers of an onion. The last `add_middleware` call is the outermost layer. CORS must be outermost so preflight requests never reach auth. Logging should be early to capture all requests. Enumerate allowed methods and headers explicitly — wildcards permit CONNECT/TRACE and expose all custom headers to cross-origin requests.

---

### `api-versioning`

**Impact: LOW-MEDIUM**

Version APIs via URL prefix. This is the simplest approach and works well with FastAPI routers.

**Incorrect:**

```python
# WRONG: no versioning — breaking changes affect all clients
@app.get("/users")
async def list_users(): ...
```

**Correct:**

```python
# app/api/v1/router.py
v1_router = APIRouter(prefix="/v1")
v1_router.include_router(users.router)
v1_router.include_router(orders.router)

# app/api/v2/router.py
v2_router = APIRouter(prefix="/v2")
v2_router.include_router(users_v2.router)
v2_router.include_router(orders.router)  # unchanged modules shared

# app/main.py
app.include_router(v1_router, prefix="/api")
app.include_router(v2_router, prefix="/api")
# Results in: /api/v1/users, /api/v2/users
```

**Context:** URL versioning is explicit and cacheable. Header-based versioning (`Accept: application/vnd.api+json;version=2`) is an alternative but harder to test and debug. Start with v1 even if you only have one version.

---

## 7. Testing Patterns (MEDIUM)

FastAPI's test infrastructure is built on httpx and pytest. Use async tests for async code.

### `test-async-client`

**Impact: HIGH**

Use `httpx.AsyncClient` with `ASGITransport` for testing async FastAPI applications.

**Incorrect:**

```python
from fastapi.testclient import TestClient

# WRONG: TestClient uses sync transport — async code runs in a thread
client = TestClient(app)

def test_get_users():
    response = client.get("/users")
    assert response.status_code == 200
```

**Correct:**

```python
import pytest
from httpx import ASGITransport, AsyncClient

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest.mark.anyio
async def test_get_users(client: AsyncClient):
    response = await client.get("/users")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
```

**Context:** Install `anyio` (includes the pytest plugin for `@pytest.mark.anyio`) or `pytest-asyncio` (for `@pytest.mark.asyncio`). Use `@pytest.mark.anyio` to mark async tests. The `ASGITransport` sends requests directly to the ASGI app without a real HTTP server. With `anyio`, async fixtures use standard `@pytest.fixture`. With `pytest-asyncio`, use `@pytest_asyncio.fixture` instead.

---

### `test-dependency-overrides`

**Impact: HIGH**

Use `app.dependency_overrides` to replace dependencies in tests. This is FastAPI's built-in mechanism for mocking.

**Incorrect:**

```python
# WRONG: patching internal functions with unittest.mock
from unittest.mock import patch

@pytest.mark.anyio
async def test_create_user(client):
    with patch("app.routers.users.get_db") as mock_db:
        mock_db.return_value = fake_session
        response = await client.post("/users", json={"name": "Alice"})
```

**Correct:**

```python
async def override_get_db():
    async with test_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

@pytest.fixture(autouse=True)
def override_dependencies():
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.clear()
```

**Context:** `dependency_overrides` is a dict mapping original dependency functions to their test replacements. Use `autouse=True` fixtures to apply overrides globally. Clear overrides in teardown to prevent leaks between tests.

---

### `test-factories`

**Impact: MEDIUM**

Use factory functions or `factory_boy` to generate test data. Never hardcode test data inline.

**Incorrect:**

```python
# WRONG: hardcoded test data repeated across tests
@pytest.mark.anyio
async def test_update_user(client, db):
    user = User(
        name="Test User",
        email="test@example.com",
        hashed_password="$2b$12...",  # never use plaintext — use bcrypt hash
        created_at=datetime(2024, 1, 1),
    )
    db.add(user)
    await db.flush()
    ...
```

**Correct:**

```python
from polyfactory.factories.pydantic_factory import ModelFactory

class UserCreateFactory(ModelFactory):
    __model__ = UserCreate

class UserFactory:
    @staticmethod
    async def create(db: AsyncSession, **overrides) -> User:
        data = UserCreateFactory.build(**overrides)
        user = User(**data.model_dump(), hashed_password=hash_password(data.password))
        db.add(user)
        await db.flush()
        return user

@pytest.mark.anyio
async def test_update_user(client, db):
    user = await UserFactory.create(db, name="Alice")
    response = await client.patch(f"/users/{user.id}", json={"name": "Bob"})
    assert response.status_code == 200
```

**Context:** `polyfactory` (successor to `pydantic-factories`) generates random valid data from Pydantic models. Override specific fields in tests for readability. For SQLAlchemy models, wrap factory creation in a helper that handles session operations. Use `passlib[bcrypt]` or the `bcrypt` library directly for password hashing. Never store plaintext or fast-hash (MD5/SHA-1) values.

---

### `test-db-isolation`

**Impact: HIGH**

Use transaction rollback between tests to ensure isolation. Each test should start with a clean database state.

**Incorrect:**

```python
# WRONG: tests share database state and depend on execution order
@pytest.mark.anyio
async def test_create_user(client):
    response = await client.post("/users", json={"name": "Alice"})
    assert response.status_code == 201

@pytest.mark.anyio
async def test_list_users(client):
    # WRONG: depends on test_create_user having run first
    response = await client.get("/users")
    assert len(response.json()) == 1
```

**Correct:**

```python
from sqlalchemy.ext.asyncio import async_sessionmaker

@pytest.fixture
async def db():
    async with engine.connect() as conn:
        await conn.begin()
        # Create a session bound to this connection
        test_session_maker = async_sessionmaker(bind=conn, expire_on_commit=False)
        session = test_session_maker()
        # Create a nested transaction (savepoint) — endpoint commit()
        # only commits this savepoint, not the outer transaction
        await session.begin_nested()

        @event.listens_for(session.sync_session, "after_transaction_end")
        def restart_savepoint(sync_session, transaction):
            if transaction.nested and not transaction._parent.nested:
                sync_session.begin_nested()

        try:
            yield session
        finally:
            await session.close()
            await conn.rollback()

@pytest.fixture
async def client(db):
    async def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
```

**Context:** The `begin_nested()` creates a savepoint. When endpoint code calls `session.commit()`, it commits the savepoint, not the outer transaction. The `after_transaction_end` listener automatically creates a new savepoint after each commit. The outer `conn.rollback()` in the fixture's `finally` block rolls back everything, leaving the database clean. Import `event` from `sqlalchemy`.

---

## 8. Project Structure (LOW-MEDIUM)

Good project structure makes codebases navigable and maintainable.

### `structure-domain-packages`

**Impact: MEDIUM**

Organize code by business domain (feature), not by technical layer.

**Incorrect:**

```
# WRONG: organized by layer — features spread across directories
app/
  models/
    user.py
    order.py
    product.py
  routers/
    user.py
    order.py
    product.py
  schemas/
    user.py
    order.py
    product.py
  services/
    user.py
    order.py
    product.py
```

**Correct:**

```
# RIGHT: organized by domain — feature code is colocated
app/
  users/
    router.py
    models.py
    schemas.py
    service.py
  orders/
    router.py
    models.py
    schemas.py
    service.py
  products/
    router.py
    models.py
    schemas.py
    service.py
  core/
    config.py
    database.py
    deps.py
    exceptions.py
  main.py
```

**Context:** Domain organization keeps related code together. When you work on the "users" feature, everything is in `app/users/`. Shared infrastructure goes in `app/core/`. This scales better as the codebase grows.

---

### `structure-config-module`

**Impact: MEDIUM**

Centralize all configuration in a single module using `BaseSettings`.

**Incorrect:**

```python
# WRONG: config scattered across modules
# database.py
DATABASE_URL = os.environ["DATABASE_URL"]

# auth.py
SECRET_KEY = os.environ["SECRET_KEY"]
TOKEN_EXPIRY = int(os.environ.get("TOKEN_EXPIRY", "3600"))

# main.py
DEBUG = os.environ.get("DEBUG", "false") == "true"
```

**Correct:**

```python
# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    # Database
    database_url: str
    db_pool_size: int = 20
    db_max_overflow: int = 10

    # Auth
    secret_key: str
    token_expiry_seconds: int = 3600

    # App
    debug: bool = False
    environment: Literal["development", "staging", "production"] = "development"

    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()

# Usage in other modules
from app.core.config import settings
engine = create_async_engine(settings.database_url, pool_size=settings.db_pool_size)
```

**Context:** A single settings module is the source of truth for all configuration. It validates at startup — if a required env var is missing, the app fails fast with a clear error instead of crashing later at runtime.

---

### `structure-init-exports`

**Impact: LOW-MEDIUM**

Use `__init__.py` to define clean public APIs for each package. Only export what other packages need.

**Incorrect:**

```python
# WRONG: importing from internal module paths
from app.users.models import User
from app.users.schemas import UserCreate, UserRead, UserUpdate
from app.users.service import UserService
from app.users.router import router as users_router
```

**Correct:**

```python
# app/users/__init__.py
from app.users.models import User
from app.users.schemas import UserCreate, UserRead, UserUpdate
from app.users.router import router

__all__ = ["User", "UserCreate", "UserRead", "UserUpdate", "router"]

# Usage in other modules
from app.users import User, UserCreate, router
```

**Context:** `__init__.py` exports define the package's public API. Internal implementation details (service classes, utilities) stay private. This makes refactoring internal module structure safe.

---

### `structure-alembic-setup`

**Impact: LOW-MEDIUM**

Configure Alembic with async support, a naming convention, and auto-generation from SQLAlchemy models.

**Incorrect:**

```python
# alembic/env.py — WRONG: no async, no naming convention
from alembic import context
from sqlalchemy import engine_from_config

def run_migrations_online():
    connectable = engine_from_config(config.get_section("alembic"))
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=metadata)
        with context.begin_transaction():
            context.run_migrations()
```

**Correct:**

```python
# alembic/env.py
from sqlalchemy.ext.asyncio import async_engine_from_config

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

target_metadata = Base.metadata
target_metadata.naming_convention = NAMING_CONVENTION

def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations():
    connectable = async_engine_from_config(
        config.get_section("alembic"),
        prefix="sqlalchemy.",
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()

def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    asyncio.run(run_async_migrations())
```

**Context:** The naming convention ensures all constraints have predictable names, which is required for reliable migration auto-generation and downgrade support. Without it, some databases generate random names that differ across environments.
