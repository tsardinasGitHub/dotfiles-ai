---
name: python-antipatterns
description: >
  Prohibited patterns in Python FastAPI DDD projects.
  Trigger: When writing or reviewing Python code in any FastAPI project.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load alongside `python-fastapi-ddd`. Apply silently on every Python code review or write.

---

## Business Logic in API Routers — PROHIBITED

Routers must be thin: parse input, call use case, map Result to HTTP response. Nothing more.

```python
# NO — validation, queries, and business rules all inside router
@router.post("/students/{student_id}/goals")
async def create_goal(student_id: str, request: CreateGoalRequest, db: Session = Depends(get_db)):
    if not request.title or len(request.title) < 5:  # business rule in router
        raise HTTPException(400, "Title too short")
    student = db.query(Student).filter_by(id=student_id).first()  # direct query in router
    if student.active_goals >= 3:                                  # business rule in router
        raise HTTPException(400, "Maximum 3 active goals")
    goal = Goal(student_id=student_id, title=request.title)
    db.add(goal)
    db.commit()

# YES — router delegates entirely to use case
@router.post("/students/{student_id}/goals", response_model=GoalResponse)
async def create_goal(
    student_id: str,
    request: CreateGoalRequest,
    use_case: CreateGoalUseCase = Depends(),
) -> GoalResponse:
    result = await use_case.execute(student_id, request)
    match result:
        case Success(goal):                              return GoalResponse.from_entity(goal)
        case Failure(CreateGoalError.STUDENT_NOT_FOUND): raise HTTPException(404)
        case Failure(CreateGoalError.MAX_GOALS_REACHED): raise HTTPException(400, "Max 3 goals")
        case Failure(CreateGoalError.INVALID_TITLE):     raise HTTPException(422)
        case Failure(_):                                 raise HTTPException(500)
```

Rule: Router < 100 lines. No direct DB access. No business logic.

---

## Pydantic as Domain Entity — PROHIBITED

Pydantic is for API validation. Domain entities use `@dataclass`.

```python
# NO — domain entity inheriting from BaseModel (coupled to HTTP framework)
class Student(BaseModel):
    id: str
    level: int
    def advance_level(self) -> bool: ...  # business logic in HTTP model

# YES — domain entity as dataclass (no framework dependency)
from dataclasses import dataclass
from src.domain.value_objects import StudentId, Level

@dataclass
class Student:
    id: StudentId
    level: Level
    completed_goals: int

    def can_advance_level(self) -> bool:
        return self.level.value < 10 and self.completed_goals >= 5

    def advance_level(self) -> Result[None, AdvanceLevelError]:
        if not self.can_advance_level():
            return Failure(AdvanceLevelError.NOT_ELIGIBLE)
        self.level = Level(self.level.value + 1)
        return Success(None)

# YES — Pydantic only at API boundary
class CreateStudentRequest(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=3, max_length=100)

class StudentResponse(BaseModel):
    id: str
    level: int

    @classmethod
    def from_entity(cls, student: Student) -> "StudentResponse":
        return cls(id=str(student.id), level=student.level.value)
```

---

## Derived State Stored — PROHIBITED

Use Pydantic v2 `@computed_field` for derived values. Never store them as fields.

```python
# NO — manual calculation of derived fields (can get out of sync)
class GoalResponse(BaseModel):
    goals: list[Goal]
    total_goals: int      # len(goals)
    active_goals: int     # filter(is_active)
    completion_rate: float  # completed/total

# YES — computed on demand
from pydantic import BaseModel, computed_field, ConfigDict

class GoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    goals: list[Goal]

    @computed_field
    @property
    def total_goals(self) -> int:
        return len(self.goals)

    @computed_field
    @property
    def active_goals(self) -> int:
        return sum(1 for g in self.goals if g.is_active)

    @computed_field
    @property
    def completion_rate(self) -> float:
        if not self.goals:
            return 0.0
        completed = sum(1 for g in self.goals if g.is_completed)
        return completed / self.total_goals
```

---

## Unwrap Without Check — PROHIBITED

`.unwrap()` raises at runtime if called on `Failure`. Always use alternatives.

```python
# NO
user = user_result.unwrap()  # explodes if Failure

# YES — pattern matching (preferred)
match user_result:
    case Success(user): return Success({"name": user.name})
    case Failure(e):    return Failure(ProcessError.from_find_error(e))

# YES — map (for transformations that can't fail)
return user_result.map(lambda user: {"name": user.name})

# YES — value_or (when a safe default exists)
user = user_result.value_or(User.anonymous())
```

---

## Mixed Error Conventions — PROHIBITED

One module = one error convention. Use `Result` everywhere.

```python
# NO — three different conventions in the same class
class UserService:
    async def create(self, data) -> User:          # raises exceptions
    async def delete(self, id) -> bool:            # returns bool
    async def find(self, id) -> Optional[User]:    # returns None
    async def update(self, id, data) -> Result:    # Result

# YES — Result everywhere
class UserService:
    async def create(self, data) -> Result[User, CreateUserError]: ...
    async def delete(self, id)   -> Result[None, DeleteUserError]: ...
    async def find(self, id)     -> Result[User, FindUserError]:   ...
    async def update(self, id, data) -> Result[User, UpdateUserError]: ...
```

---

## Queries in Loops — PROHIBITED

```python
# NO — N queries inside a comprehension
scores = [
    await db.scalar(select(Score.value).where(Score.student_id == sid))
    for sid in student_ids
]

# YES — single query with IN
result = await db.execute(
    select(Score.value).where(Score.student_id.in_(student_ids))
)
scores = result.scalars().all()
```

---

## Await in Loops — PROHIBITED

Sequential awaits when operations are independent waste time proportionally.

```python
# NO — 10 students × 2s = 20s total
results = []
for student_id in student_ids:
    result = await process_student(student_id)  # serial
    results.append(result)

# YES — 10 students in parallel = 2s total
tasks = [process_student(sid) for sid in student_ids]
results = await asyncio.gather(*tasks)

# YES — with individual error handling
results = await asyncio.gather(*tasks, return_exceptions=True)
```

Rule: if operations don't depend on each other's output → `asyncio.gather`.

---

## Missing Indexes — PROHIBITED

Every column used in `WHERE`, `JOIN`, or frequent `ORDER BY` needs an index.

```python
# NO — email queried on every login but no index
class StudentModel(Base):
    email = Column(String, nullable=False)

# YES — explicit index
from sqlalchemy import Index

class StudentModel(Base):
    email = Column(String, nullable=False, unique=True)

    __table_args__ = (
        Index("ix_students_email", "email"),
    )

# Alembic migration
def upgrade():
    op.create_index("ix_students_email", "students", ["email"], unique=True)
```

---

## Circular Imports

```python
# NO — student.py imports goal.py, goal.py imports student.py → circular

# YES (option 1) — TYPE_CHECKING guard
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from src.domain.entities.goal import Goal

class Student:
    def add_goal(self, goal: "Goal") -> None: ...

# YES (option 2, better) — move shared logic to a service
# src/domain/services/goal_assignment_service.py
class GoalAssignmentService:
    def assign(self, goal: Goal, student: Student) -> Result: ...
```

---

## Testing Anti-Patterns

### Tests without isolation — shared DB state
```python
# NO — data persists across tests
@pytest.fixture
async def db_session():
    session = AsyncSession(engine)
    yield session
    # no cleanup → next test sees previous test's data

# YES — automatic rollback after each test
@pytest.fixture
async def db_session():
    async with engine.begin() as conn:
        nested = await conn.begin_nested()
        session = AsyncSession(bind=conn)
        yield session
        await nested.rollback()
        await session.close()
```

### Mocking implementation instead of behavior
```python
# NO — test breaks on any internal refactor
mock_repo.find_by_email.assert_called_once()
mock_repo.save.assert_called_once()
mock_event_bus.publish.assert_called_once()

# YES — test observable behavior (what the use case produces)
result = await use_case.execute(request)
assert result.is_ok()
student = result.unwrap()
assert student.email == "juan@example.com"
# verify persistence if relevant
found = await repo.find(student.id)
assert found.is_ok()
```

Rule: mock only external dependencies (third-party APIs, email, SMS). Never mock your own domain/application code.

---

## pyproject.toml — Recommended Config

```toml
[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W", "C90"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
python_files = "test_*.py"
python_functions = "test_*"

[tool.radon]
exclude = "tests/*,migrations/*"
show_complexity = true
min = "B"
```

---

## Pre-Commit Checklist

Before committing Python code, verify absence of:

- [ ] Business logic in routers
- [ ] Pydantic models as domain entities
- [ ] Stored derived state (use `@computed_field`)
- [ ] `.unwrap()` without check
- [ ] Mixed error conventions in the same module
- [ ] `await` inside loops when `asyncio.gather` applies
- [ ] Queries inside loops (use `.in_()`)
- [ ] Columns used in WHERE/JOIN without an index
- [ ] Circular imports (use TYPE_CHECKING or refactor to service)
- [ ] Tests without DB rollback isolation
- [ ] `mypy --strict` failures
