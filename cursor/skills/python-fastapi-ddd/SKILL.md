---
name: python-fastapi-ddd
description: >
  Architecture patterns and conventions for Python FastAPI with DDD/Hexagonal architecture.
  Trigger: When writing or reviewing Python FastAPI code.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load when working in any Python / FastAPI project. Apply silently.

---

## Limits (Python-specific)

| Metric | Limit | Action if exceeded |
|--------|-------|--------------------|
| Module lines | 500L | LEGACY mode — extract, do not modify in place |
| Function lines | 25L | Split into smaller functions |
| Async pipeline steps | 4 | Extract intermediate step to helper |
| Cyclomatic complexity | 10 | Refactor before adding more branches |
| Nesting depth | 3 | Flatten with early returns |
| Test coverage | > 85% | Uncovered paths are unverified paths |

---

## Core Architecture: Pure vs Coordinator

Every module must be one of these two types. Never mix them.

**Pure function** — logic only, no I/O, always testable with no mocks:
```python
def calculate_discount(price: float, tier: str) -> Result[float, str]:
    """No I/O. Deterministic. Easily unit-tested."""
    if price <= 0:
        return Failure("invalid_price")
    factor = 0.2 if tier == "premium" else 0.0
    return Success(price * (1 - factor))
```

**Coordinator** — orchestrates I/O and calls Pure functions:
```python
class CheckoutService:
    """Coordinates: fetches data, calls pure logic, persists result."""
    def __init__(self, repo: ProductRepository, notifier: Notifier) -> None:
        self._repo = repo
        self._notifier = notifier

    async def process(self, order_id: str) -> Result[Order, CheckoutError]:
        product = await self._repo.get(order_id)  # I/O
        total = calculate_discount(product.price, product.tier)  # Pure
        if total.is_err():
            return total
        saved = await self._repo.save(total.unwrap())  # I/O
        await self._notifier.send(saved)              # I/O
        return Success(saved)
```

**Rule**: if a function does both logic AND I/O → split it. Pure functions live in `domain/`, coordinators in `application/`.

---

## Dependency Injection with Protocol

Define dependencies as Protocols, inject via constructor. Never import concrete implementations inside domain/application code.

```python
from typing import Protocol
from returns.result import Result

# Protocol in domain layer (no concrete dependency)
class UserRepository(Protocol):
    async def find_by_id(self, user_id: str) -> Result["User", "UserError"]: ...
    async def save(self, user: "User") -> Result["User", "UserError"]: ...

# Service receives the Protocol, not the SQLAlchemy implementation
class UserService:
    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo
```

---

## Error Handling — Result types (returns library)

Business errors are values, not exceptions. Exceptions are for unexpected failures only.

```python
from enum import Enum
from returns.result import Result, Success, Failure

class UserError(str, Enum):
    NOT_FOUND = "not_found"
    ALREADY_EXISTS = "already_exists"
    INVALID_INPUT = "invalid_input"

async def create_user(data: dict) -> Result[User, UserError]:
    if not data.get("email"):
        return Failure(UserError.INVALID_INPUT)
    existing = await repo.find_by_email(data["email"])
    if existing.is_ok():
        return Failure(UserError.ALREADY_EXISTS)
    return await repo.save(User(**data))

# At FastAPI boundary — unwrap the Result
@router.post("/users")
async def create(data: UserInput) -> UserResponse:
    match await create_user(data.model_dump()):
        case Success(user):  return UserResponse.from_domain(user)
        case Failure(UserError.INVALID_INPUT): raise HTTPException(422)
        case Failure(UserError.ALREADY_EXISTS): raise HTTPException(409)
```

---

## Anti-Patterns — PROHIBITED

```python
# NO — None as error signal
def find_user(id: str) -> User | None: ...

# YES — explicit Result
def find_user(id: str) -> Result[User, UserError]: ...

# NO — exception for business rule
def validate(data: dict):
    if not data["email"]:
        raise ValueError("invalid email")  # control flow via exception

# YES — return Failure
def validate(data: dict) -> Result[dict, UserError]:
    if not data.get("email"):
        return Failure(UserError.INVALID_INPUT)
    return Success(data)

# NO — blocking I/O inside async function
async def fetch(url: str) -> str:
    return requests.get(url).text   # blocks the event loop

# YES — async I/O
async def fetch(url: str) -> str:
    async with httpx.AsyncClient() as client:
        resp = await client.get(url)
        return resp.text

# NO — mutable default argument
def process(items: list = []) -> list: ...

# YES
def process(items: list | None = None) -> list:
    items = items or []
    ...

# NO — N+1 queries (same as Elixir/Ecto rule)
users = session.query(User).all()
for user in users:
    orders = session.query(Order).filter_by(user_id=user.id).all()  # N queries

# YES — eager load
users = session.query(User).options(selectinload(User.orders)).all()
```

---

## Module Structure (DDD/Hexagonal)

```
src/
  domain/           # Pure: entities, value objects, domain services, enums, errors
  application/      # Coordinators: use cases, services (orchestrate domain + infra)
  infrastructure/   # I/O: SQLAlchemy repos, HTTP clients, email services
  api/              # FastAPI routers, schemas (Pydantic), dependency injection

tests/
  unit/             # Mirror of src/ — pure functions, no real I/O
    domain/         # test_user.py mirrors src/domain/user.py
    application/    # uses pytest-mock for infra deps
  integration/      # Real DB, real HTTP
  e2e/              # Full stack flows (Playwright/httpx)
```

Test file mirror convention: `src/domain/user.py` → `tests/unit/domain/test_user.py`

---

## Module Template

```python
"""
Brief module purpose. DDD layer: domain | application | infrastructure.

Example:
    >>> service = UserService(repo=FakeUserRepo())
    >>> result = await service.create({"email": "x@x.com"})
    >>> assert result.is_ok()
"""
from dataclasses import dataclass
from enum import Enum
from typing import Protocol
from returns.result import Result, Success, Failure


class UserError(str, Enum):
    NOT_FOUND = "not_found"
    INVALID_INPUT = "invalid_input"


@dataclass(frozen=True)
class User:
    id: str
    email: str


class UserRepository(Protocol):
    async def save(self, user: User) -> Result[User, UserError]: ...


class UserService:
    """
    Responsibilities:
    - Validate user input
    - Coordinate persistence via UserRepository

    Example: see module docstring.
    """
    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo

    async def create(self, data: dict) -> Result[User, UserError]:
        """
        Create a new user.

        Args:
            data: dict with 'email' key

        Returns:
            Success(User) on valid input
            Failure(UserError.INVALID_INPUT) if email missing

        Raises:
            Never raises — all errors returned as Failure
        """
        if not data.get("email"):
            return Failure(UserError.INVALID_INPUT)
        return await self._repo.save(User(id="", email=data["email"]))
```

---

## Tooling

```bash
# Required tools
pip install returns ruff mypy radon pytest-asyncio pytest-mock nplusone

# Type checking (must pass before commit)
mypy --strict src/

# Linting + formatting
ruff check src/ && ruff format src/

# Complexity report (run to identify files near legacy threshold)
radon cc src/ --json > .complexity_results.json
radon mi src/  # Maintainability Index

# Tests with coverage
pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=85
```

Docstring style: **Google** (Args / Returns / Raises / Example).
