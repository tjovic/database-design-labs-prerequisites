# 08 – Database Integrity & Constraints

> Examples are written in **SQL Server** style (`IDENTITY`, `NVARCHAR`, `CHECK`, `ALTER TABLE`).
> Some details differ on other database systems.

**Database:** this file builds its own example tables (`Teacher`, `Student`,
`Subject`, `Exam`) from scratch. It does not use `AdventureWorksENG`.

`CREATE TABLE` and `ALTER TABLE` are SQL's **DDL** (Data Definition
Language) — see [01, Section 1](01-relational-database-basics.md#section-1--what-is-sql).
This file is where DDL is covered in depth.

## Learning objectives

After this file, you should be able to:

- explain what database integrity means, and why it can't be left to the application alone;
- distinguish entity integrity, key integrity, domain integrity, `NULL` constraints, and referential integrity;
- use `NOT NULL`, `DEFAULT`, `PRIMARY KEY`, `UNIQUE`, `CHECK`, and `FOREIGN KEY`;
- explain the difference between `DELETE`, `TRUNCATE`, and `DROP`;
- define single-column and composite keys, and choose between a natural key and a surrogate key;
- modify an existing table's definition with `ALTER TABLE`, including adding a constraint after the table already has data.

> **Tip:** several sections below start with `DROP TABLE IF EXISTS ...` and
> redefine a table from scratch. This file is meant to be run top to bottom —
> each redefinition builds on the lesson from the previous one.

------------------------------------------------------------------------

## Section 1 – What is database integrity?

### The idea

**Database integrity** refers to the consistency and correctness of the
data held in a database.

Integrity can be broken by:

- an accidental mistake by a user entering or changing data;
- a bug in the application or in some other system that writes to the database.

### Kinds of integrity

This file works through the following kinds, one at a time:

- entity integrity
- key integrity
- domain integrity
- `NULL` constraints
- referential integrity
- general integrity constraints

### Why does this matter?

Without integrity constraints, a database would let you:

- save incomplete data;
- save contradictory data;
- link a record to a record that doesn't exist in another table;
- insert several rows that were supposed to be unique.

### Check your understanding

Why isn't it enough for the *application* to validate data — why does the
database itself need to enforce it too?

<details>
<summary>Show answer</summary>

The application is rarely the only way data enters the database: other
applications, ad-hoc queries, migrations, or a bug can all write to the
table directly. A constraint defined in the database applies no matter
which path the data came through, so integrity doesn't depend on every
client getting its validation right, every time.

</details>

------------------------------------------------------------------------

## Section 2 – NULL constraints, and removing data

### The idea

A `NOT NULL` constraint is written right after the data type in a column
definition. It means the column **must have a value** — it can never be
left unknown (`NULL`).

### Example table

```sql
CREATE TABLE Teacher (
    TeacherID  INT NOT NULL,
    NationalID CHAR(11) NOT NULL,
    LastName   NVARCHAR(40)
);
```

### Inserting test data

```sql
INSERT INTO Teacher VALUES
(1111, '06382780091', N'Pascal'),
(3333, '91643023865', N'Newton'),
(2222, '51843144239', NULL);

SELECT * FROM Teacher;
```

The table definition allows `NULL` in `LastName`.

### Inserting NULL where NOT NULL is defined

```sql
INSERT INTO Teacher VALUES (4444, NULL, N'Gauss');
```

**Expect:** SQL Server returns an error similar to *Cannot insert the
value NULL into column 'NationalID'...*

### Trying to insert the same row again

```sql
INSERT INTO Teacher VALUES (1111, '06382780091', N'Pascal');

SELECT * FROM Teacher;
```

### What to notice here

Even though `TeacherID` and `NationalID` are marked `NOT NULL`, that does
**not** make them unique automatically.

In other words, `NOT NULL` only guarantees that a value exists — it
**does not prevent duplicates**.

### Removing rows and tables

```sql
DELETE FROM Teacher;
```
```sql
TRUNCATE TABLE Teacher;
```
```sql
DROP TABLE Teacher;
```

### What each one does

- `DELETE` without a `WHERE` clause also removes every row from the table;
- `TRUNCATE` empties the table — removes every row;
- `DROP` removes the entire table — both its structure and its data.

The important difference between `DELETE` and `TRUNCATE`:

- `DELETE` logs every removed row in the transaction log, which makes it possible to roll it back;
- `TRUNCATE` uses minimal logging, which makes it faster.

### Rule of thumb

- use `DELETE` when removing specific rows, usually with `WHERE`;
- use `TRUNCATE` when you want to quickly empty an entire table;
- use `DROP` when you no longer need the table at all.

### Check your understanding

1. Does `NOT NULL` prevent duplicate values?
2. Is `NULL` the same thing as an empty string?
3. When you `DROP` a table, are only the rows removed, or the table's structure too?

<details>
<summary>Show answers</summary>

1. No — `NOT NULL` only guarantees a value exists, not that it is unique.
2. No. `NULL` means "no value at all"; an empty string (`''`) is still a
    value — a zero-length piece of text.
3. Both. `DROP` removes the structure and the data.

</details>

------------------------------------------------------------------------

## Section 3 – DEFAULT

### The idea

- `NOT NULL` → the column must have a value.
- `DEFAULT` → the database assigns a value automatically if none is provided.

### Example

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT NOT NULL,
    NationalID CHAR(11) NOT NULL,
    LastName   NVARCHAR(40) NOT NULL,
    Active     BIT DEFAULT 1
);
```

### Inserting without mentioning the Active column

```sql
INSERT INTO Teacher (TeacherID, NationalID, LastName)
VALUES (1001, '06382780091', N'Newton');

SELECT * FROM Teacher;
```

Result: `Active = 1` (set by `DEFAULT`).

### Inserting an explicit value

```sql
INSERT INTO Teacher (TeacherID, NationalID, LastName, Active)
VALUES (1002, '91643023865', N'Maxwell', 0);

SELECT * FROM Teacher;
```

### Note

`DEFAULT` only supplies a starting value on insert. Full integrity is only
achieved together with `NOT NULL`, because `DEFAULT` alone does not stop
someone from explicitly inserting an invalid `NULL`.

For example, if the column is only defined as `Active BIT DEFAULT 1`, we
lose full control over its integrity. `DEFAULT` suggests teachers will be
active by default, but the database still allows this:

```sql
INSERT INTO Teacher (TeacherID, NationalID, LastName, Active)
VALUES (1003, '63743552278', N'Leibniz', NULL);

SELECT * FROM Teacher;
```

So the `Active` column should really be defined as `BIT NOT NULL DEFAULT 1`.

------------------------------------------------------------------------

## Section 4 – Primary key (PRIMARY KEY)

### Theory

- **Entity integrity**: no attribute of the primary key may ever be `NULL`.
- **Key integrity**: no two rows in a table may have the same key value.

> We will mostly say **row** below, even though relational theory often
> uses the term **tuple**.

### Example definition

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT PRIMARY KEY,
    NationalID CHAR(11) NOT NULL,
    LastName   NVARCHAR(40)
);
```

When a constraint applies to a single column, it can be written directly
next to that column's definition.

### Inserting data

```sql
INSERT INTO Teacher VALUES
(1111, '06382780091', N'Pascal'),
(3333, '91643023865', N'Newton'),
(2222, '51843144239', N'Cantor');

SELECT * FROM Teacher;
```

> `PRIMARY KEY` always guarantees both entity integrity and key integrity
> for the primary key.

### Correct behavior

Each row has a different `TeacherID`, so every insert succeeds.

### What happens with a duplicate?

Let's try inserting a row whose key already exists:

```sql
INSERT INTO Teacher VALUES (1111, '06382780091', N'Pascal');
```

**Expect:** SQL Server returns an error similar to *Violation of PRIMARY
KEY constraint...*

### Important note

`PRIMARY KEY` automatically means:

- the value must exist (`NOT NULL`);
- the value must be unique.

That's why `PRIMARY KEY` is more than a plain `NOT NULL`.

### Check your understanding

1. Why doesn't `PRIMARY KEY` allow `NULL`?
2. Can a table have two primary keys?
3. What is the difference between `NOT NULL` and `PRIMARY KEY`?

<details>
<summary>Show answers</summary>

1. Because entity integrity requires every row to be identifiable — a
    `NULL` key value couldn't reliably distinguish one row from another.
2. No — a table has exactly one primary key, though it can span several
    columns (a composite key, covered in Section 8).
3. `NOT NULL` only guarantees a value exists. `PRIMARY KEY` guarantees
    both that a value exists **and** that it's unique.

</details>

------------------------------------------------------------------------

## Section 5 – UNIQUE constraint

### The idea

`UNIQUE` protects an **alternate key**.

The primary key is a row's main identifier; an alternate key is another
column (or set of columns) that must also be unique.

### Example: the Teacher table

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT PRIMARY KEY,
    NationalID CHAR(11) UNIQUE,
    LastName   NVARCHAR(40)
);
```

> Every alternate key should be protected with a `UNIQUE` constraint.

### Example inserts

```sql
INSERT INTO Teacher VALUES (1000, '06382780091', N'Newton');
INSERT INTO Teacher VALUES (1000, '63743552278', N'Leibniz'); -- fails: PRIMARY KEY
INSERT INTO Teacher VALUES (1001, '06382780091', N'Codd');    -- fails: UNIQUE
SELECT * FROM Teacher;
```

### What to notice here

- the first `INSERT` succeeds;
- the second fails because `TeacherID` is duplicated;
- the third fails because `NationalID` is duplicated.

So:

- `PRIMARY KEY` protects the main identifier;
- `UNIQUE` protects an alternate identifier.

### An important note about UNIQUE and NULL

In SQL Server, a `UNIQUE` constraint does **not** allow more than one
`NULL` value. This differs from some other database systems, such as
Oracle or PostgreSQL.

```sql
INSERT INTO Teacher VALUES (1006, NULL, N'Moore');
SELECT * FROM Teacher;
```

```sql
INSERT INTO Teacher VALUES (1007, NULL, N'Kepler'); -- fails: SQL Server does not allow a second NULL here
SELECT * FROM Teacher;
```

**Expect:** SQL Server returns an error similar to *Violation of UNIQUE
KEY constraint...*

### Check your understanding

1. What is `UNIQUE` used for?
2. How does `UNIQUE` differ from `PRIMARY KEY`?
3. How does SQL Server behave when a `UNIQUE` column already contains a `NULL` and a second `NULL` is inserted?

<details>
<summary>Show answers</summary>

1. To enforce uniqueness on an alternate key.
2. A table can have several `UNIQUE` constraints but only one
    `PRIMARY KEY`; `UNIQUE` columns may allow `NULL` (at most one in SQL
    Server), while `PRIMARY KEY` never allows `NULL` at all.
3. SQL Server rejects it — it treats a second `NULL` as a duplicate under
    a `UNIQUE` constraint.

</details>

------------------------------------------------------------------------

## Section 6 – UNIQUE + NOT NULL

### The idea

If we want to guarantee that a national ID:

- always exists, and
- is always unique,

we combine `NOT NULL` and `UNIQUE`.

### Example

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT PRIMARY KEY,
    NationalID CHAR(11) NOT NULL UNIQUE,
    LastName   NVARCHAR(40)
);

INSERT INTO Teacher VALUES (1001, '06382780091', N'Newton');
SELECT * FROM Teacher;

INSERT INTO Teacher VALUES (1005, NULL, N'Gauss');
```

### What to expect

The second `INSERT` fails because `NationalID` is defined as `NOT NULL`,
so a value must be present.

### Check your understanding

Why does the second `INSERT` fail here, when the previous example allowed
one `NULL`?

<details>
<summary>Show answer</summary>

Because `NOT NULL` was added this time. `UNIQUE` alone allowed a single
`NULL`; `NOT NULL` forbids `NULL` outright, regardless of how many other
`NULL`s exist elsewhere.

</details>

------------------------------------------------------------------------

## Section 7 – Auto-generating keys with IDENTITY

### The idea

Sometimes we don't want to type the primary key by hand — we want the
database to generate it automatically.

### Table definition

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT IDENTITY(5001, 1) PRIMARY KEY,
    NationalID CHAR(11) NOT NULL UNIQUE,
    LastName   NVARCHAR(40)
);
```

### Explanation

`IDENTITY` is a column property that automatically generates a unique
numeric value for every new row.

Examples:

- `IDENTITY(1, 1)` → the first row starts at 1, each next one increases by 1;
- `IDENTITY(100, 10)` → the first row starts at 100, each next one increases by 10;
- `IDENTITY(5001, 1)` → the first row starts at 5001, each next one increases by 1.

### Inserting data

> When inserting, we do **not** provide `TeacherID` — it is generated automatically.

```sql
INSERT INTO Teacher VALUES
('06382780091', N'Newton'),
('91643023865', N'Maxwell');

SELECT * FROM Teacher;
```

### DELETE vs TRUNCATE and the identity counter

`DELETE` removes rows but does **not** reset the `IDENTITY` counter.

```sql
DELETE FROM Teacher;

INSERT INTO Teacher VALUES ('06382780091', N'Newton');

SELECT * FROM Teacher;
```

`TRUNCATE` removes all rows **and** resets the `IDENTITY` counter back to
its starting value.

```sql
TRUNCATE TABLE Teacher;

INSERT INTO Teacher VALUES ('06382780091', N'Newton');

SELECT * FROM Teacher;
```

### Check your understanding

1. Why do we no longer specify a value for `TeacherID` once it's an `IDENTITY` column?
2. Which one resets the `IDENTITY` counter — `DELETE` or `TRUNCATE`?
3. What is an advantage of a surrogate key like this?

<details>
<summary>Show answers</summary>

1. SQL Server generates it automatically; supplying a value yourself
    would conflict with that (unless you explicitly override it, which is
    outside the scope of this file).
2. `TRUNCATE`.
3. It never needs to change for business reasons (unlike a natural key,
    which might), and it's a simple, compact value to use as a foreign key
    elsewhere.

</details>

------------------------------------------------------------------------

## Section 8 – Composite primary key

### The idea

So far, every constraint was attached to a single column. That works when
the key is one column.

When a key is made up of **several** columns together, it's called a
**composite key**.

### An incorrect attempt

```sql
CREATE TABLE Exam (
    StudentID  CHAR(10) PRIMARY KEY,
    SubjectID  INT PRIMARY KEY,
    ExamDate   DATE PRIMARY KEY,
    Grade      TINYINT NOT NULL,
    TeacherID  INT
);
```

> This does **not** define a composite key.

### Why is this wrong?

A table can only have **one** primary key. If the key is made of several
columns, they must be listed together in a single constraint definition.

### The correct way

```sql
CREATE TABLE Exam (
    StudentID CHAR(10),
    SubjectID INT,
    ExamDate  DATE,
    Grade     TINYINT NOT NULL,
    TeacherID INT,
    CONSTRAINT PK_Exam PRIMARY KEY (StudentID, SubjectID, ExamDate)
);
```

### What is a table-level constraint?

A **table-level** constraint is defined after all the columns, in its own
part of the `CREATE TABLE` statement.

Advantages:

- it lets you name the constraint with `CONSTRAINT name`;
- it is required for any constraint spanning more than one column;
- it reads more clearly for more complex rules.

### Example inserts

```sql
INSERT INTO Exam VALUES
('0555004388', 1001, '2022-01-29', 1, 1111),
('0555004388', 1001, '2022-02-05', 3, 1111),
('0555004388', 1003, '2021-06-28', 2, 3333),
('0555004388', 1002, '2021-06-27', 2, 2222),
('2902984555', 1001, '2022-01-29', 3, 2222);

SELECT * FROM Exam;
```

### Trying to insert a key value that already exists

```sql
INSERT INTO Exam VALUES ('0555004388', 1001, '2022-01-29', 1, 1111);
```

### What to expect

SQL Server returns an error similar to: *Violation of **PRIMARY KEY**
constraint 'PK_Exam'. Cannot insert duplicate key in object 'dbo.Exam'.
The duplicate key value is (0555004388, 1001, 2022-01-29).*

---

### Surrogate key + protecting the alternate key

When we have a composite key, we often introduce a **surrogate key**
instead, and protect the natural key with `UNIQUE`.

```sql
DROP TABLE IF EXISTS Exam;

CREATE TABLE Exam
(
    ExamID    INT IDENTITY(1000,1) PRIMARY KEY, -- surrogate, self-numbering key
    StudentID CHAR(10) NOT NULL,
    SubjectID INT NOT NULL,
    ExamDate  DATE NOT NULL,
    Grade     TINYINT NOT NULL,
    TeacherID INT,
    CONSTRAINT UQ_Exam UNIQUE (StudentID, SubjectID, ExamDate) -- protects the alternate key
);

-- Test data
INSERT INTO Exam (StudentID, SubjectID, ExamDate, Grade, TeacherID) VALUES
('0555004388', 1001, '2022-01-29', 1, 1111),
('0555004388', 1001, '2022-02-05', 3, 1111),
('0555004388', 1003, '2021-06-28', 2, 3333),
('0555004388', 1002, '2021-06-27', 2, 2222),
('2902984555', 1001, '2022-01-29', 3, 2222);

SELECT * FROM Exam;
```

### Why is this useful?

- `ExamID` is simple to reference elsewhere (for example, as a foreign key);
- the natural combination (`StudentID`, `SubjectID`, `ExamDate`) is still protected from duplicates.

### Trying to insert a key value that already exists

```sql
INSERT INTO Exam (StudentID, SubjectID, ExamDate, Grade, TeacherID)
VALUES ('0555004388', 1001, '2022-01-29', 1, 1111);
```

### What to expect

SQL Server returns an error similar to: *Violation of **UNIQUE KEY**
constraint 'UQ_Exam'. Cannot insert duplicate key in object 'dbo.Exam'.
The duplicate key value is (0555004388, 1001, 2022-01-29).*

### Check your understanding

What could go wrong if we did **not** protect the alternate key with `UNIQUE`?

<details>
<summary>Show answer</summary>

The surrogate key (`ExamID`) is always unique by construction, but it
does nothing to stop the *same* exam attempt — the same student, subject,
and date — from being recorded twice by mistake. Protecting the natural
key with `UNIQUE` is what actually prevents that duplicate.

</details>

------------------------------------------------------------------------

## Section 9 – CHECK constraint

### The idea

Domain integrity is already partly enforced by the data type itself.

Example:

- `SMALLINT` only allows whole numbers from `-32768` to `32767`.

Sometimes we want to narrow the allowed values further. That's what
`CHECK` is for.

### Example

```sql
DROP TABLE IF EXISTS Exam;

CREATE TABLE Exam
(
    ExamID    INT IDENTITY(1000,1) PRIMARY KEY,
    StudentID CHAR(10) NOT NULL,
    SubjectID INT NOT NULL,
    ExamDate  DATE NOT NULL,
    Grade     TINYINT CHECK (Grade BETWEEN 1 AND 5) NOT NULL,
    TeacherID INT,
    CONSTRAINT UQ_Exam UNIQUE (StudentID, SubjectID, ExamDate)
);
```

This guarantees the grade is always between 1 and 5.

### Checking it

```sql
INSERT INTO Exam (StudentID, SubjectID, ExamDate, Grade, TeacherID) VALUES
('0555004388', 1001, '2022-01-29', 1, 1111),
('2902984555', 1001, '2022-01-29', 6, 2222); -- notice the grade of 6

SELECT * FROM Exam;
```

### What to expect

SQL Server returns an error similar to *The INSERT statement conflicted
with the CHECK constraint...*

### Important note

If a single `INSERT` statement tries to insert several rows and one of
them violates a `CHECK` constraint, the entire statement can be rejected.

### Check your understanding

1. Why does `CHECK` belong to domain integrity?
2. What other business rule could be expressed using `CHECK`?

<details>
<summary>Show answers</summary>

1. Domain integrity is about restricting which values are valid for a
    column, and `CHECK` directly narrows the set of allowed values beyond
    what the data type alone enforces.
2. For example, `CHECK (ExamDate <= GETDATE())` to forbid recording an
    exam dated in the future, or `CHECK (Grade <> 2)` if a particular
    grading scheme skips a value.

</details>

------------------------------------------------------------------------

## Section 10 – Modifying a table definition later (ALTER TABLE)

### The idea

A table doesn't have to be fully defined the moment it's created. Later,
we can add columns, change types, and add new constraints.

### Starting table

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT IDENTITY(5001, 1) PRIMARY KEY,
    NationalID CHAR(11) NOT NULL UNIQUE,
    LastName   NVARCHAR(10)
);

INSERT INTO Teacher VALUES
('06382780091', N'Newton'),
('91643023865', N'Maxwell');

SELECT * FROM Teacher;
```

### Changing a column's type

Will the following insert succeed?

```sql
INSERT INTO Teacher VALUES ('75114131579', N'Mohorovičić');
```

SQL Server returns an error similar to: *String or binary data would be
truncated.*

That's because we're trying to store 11 characters in `LastName`, which
is defined as `NVARCHAR(10)`.

> **Depending on your database's compatibility level**, you may instead
> see a more specific version of this error: *String or binary data would
> be truncated in table 'dbo.Teacher', column 'LastName'. Truncated
> value: 'Mohoroviči'.* The detailed version (naming the table, column,
> and the value as it would have been truncated) requires database
> compatibility level 150 (SQL Server 2019) or higher. Either way, the
> cause is the same: the value doesn't fit in the column.

How do we fix the definition?

```sql
ALTER TABLE Teacher
ALTER COLUMN LastName NVARCHAR(20);
```

Try again:

```sql
INSERT INTO Teacher VALUES ('75114131579', N'Mohorovičić');

SELECT * FROM Teacher;
```

### Adding a NOT NULL constraint

```sql
ALTER TABLE Teacher
ALTER COLUMN LastName NVARCHAR(20) NOT NULL;
```

### Important note

Before `NOT NULL` can be added, every existing row must already have a
value in that column.

> **Rule:** a new constraint can only be added, or tightened, if all
> existing data already satisfies it.

### Adding a column

```sql
ALTER TABLE Teacher
ADD FirstName NVARCHAR(10);

SELECT * FROM Teacher;
```

### Inserting data

```sql
INSERT INTO Teacher VALUES ('60440865410', N'Einstein', 'Albert');

SELECT * FROM Teacher;
```

### Dropping a column

```sql
ALTER TABLE Teacher
DROP COLUMN FirstName;

SELECT * FROM Teacher;
```

### Check your understanding

1. What kinds of things can `ALTER TABLE` change?
2. Why does `ALTER COLUMN ... NOT NULL` sometimes fail?
3. Does the database have to check existing data before applying a new constraint?

<details>
<summary>Show answers</summary>

1. A column's data type, nullability, adding or dropping columns, and
    adding or dropping constraints.
2. It fails if any existing row currently has `NULL` in that column —
    the new rule would already be violated by data that's there.
3. Yes — a constraint can only be added if the existing data already
    satisfies it.

</details>

------------------------------------------------------------------------

## Section 11 – Adding constraints after the table already has data

### The idea

Constraints don't always have to be defined at `CREATE TABLE` time. They
can be added later too — but only if the existing data already follows
the new rule.

### A new version of the table

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher (
    TeacherID  INT,
    NationalID CHAR(11) NOT NULL,
    LastName   NVARCHAR(40)
);

INSERT INTO Teacher VALUES (1000, '06382780091', N'Newton');
INSERT INTO Teacher VALUES (1000, '91643023865', N'Maxwell'); -- same TeacherID both times

SELECT * FROM Teacher;
```

### Adding a UNIQUE constraint

```sql
ALTER TABLE Teacher
ADD CONSTRAINT UQ_Teacher_NationalID UNIQUE (NationalID);
```

### Explanation

SQL Server tries to apply a `UNIQUE` constraint on `NationalID`. Since the
national IDs are all different, the statement succeeds.

> A constraint can only be added if all existing data already satisfies it.

### Adding a primary key

```sql
ALTER TABLE Teacher
ADD CONSTRAINT PK_Teacher PRIMARY KEY (TeacherID);
```

SQL Server returns an error: *Cannot define PRIMARY KEY constraint on a
**nullable column** in table 'Teacher'.*

### What's going on?

This fails because:

- `PRIMARY KEY` doesn't allow `NULL`;
- `PRIMARY KEY` doesn't allow duplicates.

Our data has a duplicate `TeacherID` value (`1000`), so adding the key
doesn't succeed yet — and SQL Server flags the nullability problem first.

### Fixing it step by step

First, make sure the column disallows `NULL`:

```sql
ALTER TABLE Teacher
ALTER COLUMN TeacherID INT NOT NULL;
```

Try adding the primary key again:

```sql
ALTER TABLE Teacher
ADD CONSTRAINT PK_Teacher PRIMARY KEY (TeacherID);
```

Now SQL Server returns a different error: *The CREATE UNIQUE INDEX
statement terminated because a **duplicate key** was found for the object
name 'dbo.Teacher' and the index name 'PK_Teacher'. The duplicate key
value is (1000).*

Resolve the duplicate:

```sql
-- give the teacher with national ID 91643023865 a different TeacherID
UPDATE Teacher
SET TeacherID = 1001
WHERE NationalID = '91643023865';

-- no more duplicate values
SELECT * FROM Teacher;
```

Now try again:

```sql
ALTER TABLE Teacher
ADD CONSTRAINT PK_Teacher PRIMARY KEY (TeacherID);
```

### Check your understanding

1. Why can adding `UNIQUE` succeed while adding `PRIMARY KEY` fails on the same table?
2. What two conditions must a column meet before it can become a `PRIMARY KEY`?
3. Why does the database check existing data before adding a new constraint?

<details>
<summary>Show answers</summary>

1. `UNIQUE` only needs the existing values to be distinct, and it can
    permit `NULL`. `PRIMARY KEY` additionally requires that no value is
    `NULL`, which is a stricter condition the data might not yet satisfy.
2. It must contain no `NULL` values, and no duplicate values.
3. Because a constraint is a promise the database enforces going forward
    — it can't make that promise if data already on disk breaks it.

</details>

------------------------------------------------------------------------

## Section 12 – Foreign key (FOREIGN KEY)

### The idea

**Referential integrity** means a row in one table may reference a row in
another table only if that row actually exists.

In other words:

- you cannot insert a related record if the parent record doesn't exist;
- you cannot delete a parent record if related records still point to it — unless a special action is defined.

### Preparing the tables

Let's create `Teacher`, `Student`, and `Subject`:

```sql
DROP TABLE IF EXISTS Teacher;

CREATE TABLE Teacher(
    TeacherID  INT PRIMARY KEY,
    NationalID CHAR(11) NOT NULL UNIQUE,
    LastName   NVARCHAR(40)
);

CREATE TABLE Student(
    StudentID CHAR(10) PRIMARY KEY,
    LastName  NVARCHAR(20),
    FirstName NVARCHAR(20)
);

CREATE TABLE Subject(
    SubjectID   INT PRIMARY KEY,
    SubjectName NVARCHAR(20)
);
```

### Creating the Exam table

```sql
DROP TABLE IF EXISTS Exam;

CREATE TABLE Exam
(
    ExamID    INT IDENTITY(1000,1) PRIMARY KEY,
    StudentID CHAR(10) NOT NULL,
    SubjectID INT NOT NULL,
    ExamDate  DATE NOT NULL,
    Grade     TINYINT NOT NULL CHECK (Grade BETWEEN 1 AND 5),
    TeacherID INT,
    CONSTRAINT UQ_Exam UNIQUE (StudentID, SubjectID, ExamDate),
    CONSTRAINT FK_Exam_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Exam_Subject FOREIGN KEY (SubjectID) REFERENCES Subject(SubjectID),
    CONSTRAINT FK_Exam_Teacher FOREIGN KEY (TeacherID) REFERENCES Teacher(TeacherID)
);
```

### Inserting test data

```sql
INSERT INTO Teacher VALUES
(1111, '06382780091', N'Pascal'),
(3333, '91643023865', N'Newton'),
(2222, '51843144239', N'Cantor');

INSERT INTO Student VALUES
('0555004388', N'Smith', N'John'),
('2902984555', N'Baker', N'Peter');

INSERT INTO Subject VALUES
(1001, N'Math-1'),
(1002, N'Math-2'),
(1003, N'Physics-1');

INSERT INTO Exam (StudentID, SubjectID, ExamDate, Grade, TeacherID) VALUES
('0555004388', 1001, '2022-01-29', 1, 1111),
('0555004388', 1001, '2022-02-05', 3, 1111),
('0555004388', 1003, '2021-06-28', 2, 3333),
('0555004388', 1002, '2021-06-27', 2, 2222),
('2902984555', 1001, '2022-01-29', 3, 2222);
```

### Trying to delete a parent record

```sql
-- Check the current state of Student and Exam
SELECT * FROM Student;
SELECT * FROM Exam;
```

```sql
-- Try to delete the student with StudentID 0555004388
DELETE FROM Student WHERE StudentID = '0555004388';
```

**Expect:** SQL Server refuses the delete with an error similar to *The
DELETE statement conflicted with the REFERENCE constraint
"FK_Exam_Student"...*

### Why?

Because rows in `Exam` reference this student. If the database allowed
the delete, those `Exam` rows would be left pointing at a parent that no
longer exists.

### Trying to insert an exam for a subject that doesn't exist

```sql
INSERT INTO Exam (StudentID, SubjectID, ExamDate, Grade, TeacherID) VALUES
('0555004388', 9999, '2024-01-20', 1, 1111);
```

**Expect:** SQL Server rejects the insert with an error similar to *The
INSERT statement conflicted with the FOREIGN KEY constraint
"FK_Exam_Subject"...*

### Important note

`FOREIGN KEY` guarantees that a record can never reference a record that
doesn't exist in the related table.

### Check your understanding

1. Why can't we delete a student who already has exams on record?
2. Why can't we insert an exam for a subject that doesn't exist?
3. What is the role of a `FOREIGN KEY` constraint?

<details>
<summary>Show answers</summary>

1. Deleting the student would leave the student's `Exam` rows pointing at
    a parent record that no longer exists.
2. The `FK_Exam_Subject` constraint requires every `SubjectID` in `Exam`
    to match an existing row in `Subject`.
3. It enforces referential integrity: every reference from a child table
    to a parent table must point at a row that actually exists.

</details>

------------------------------------------------------------------------

## Section 13 – Bonus: cascading actions

### The idea

For a foreign key, you can define what happens if someone tries to delete
the parent record.

### Supported options

- `ON DELETE NO ACTION` — the default; the DBMS refuses to delete the parent record;
- `ON DELETE SET NULL` — sets the foreign key value to `NULL`;
- `ON DELETE SET DEFAULT` — sets the foreign key value to its default value;
- `ON DELETE CASCADE` — also deletes the related rows in the child table.

> **Careful:** `ON DELETE CASCADE` can remove a large number of related
> rows. Only use it when that behavior genuinely reflects a business rule.

### Example: adding ON DELETE CASCADE

```sql
DROP TABLE IF EXISTS Exam;

CREATE TABLE Exam
(
    ExamID    INT IDENTITY(1000,1) PRIMARY KEY,
    StudentID CHAR(10) NOT NULL,
    SubjectID INT NOT NULL,
    ExamDate  DATE NOT NULL,
    Grade     TINYINT NOT NULL CHECK (Grade BETWEEN 1 AND 5),
    TeacherID INT,
    CONSTRAINT UQ_Exam UNIQUE (StudentID, SubjectID, ExamDate),
    CONSTRAINT FK_Exam_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Exam_Subject FOREIGN KEY (SubjectID) REFERENCES Subject(SubjectID),
    CONSTRAINT FK_Exam_Teacher FOREIGN KEY (TeacherID) REFERENCES Teacher(TeacherID)
);

-- test data
INSERT INTO Exam (StudentID, SubjectID, ExamDate, Grade, TeacherID) VALUES
('0555004388', 1001, '2022-01-29', 1, 1111),
('0555004388', 1001, '2022-02-05', 3, 1111),
('0555004388', 1003, '2021-06-28', 2, 3333),
('0555004388', 1002, '2021-06-27', 2, 2222),
('2902984555', 1001, '2022-01-29', 3, 2222);
```

### Checking the behavior

```sql
-- before deleting
SELECT * FROM Student;
SELECT * FROM Exam;

-- this delete now succeeds!
DELETE FROM Student
WHERE StudentID = '0555004388';

-- after deleting
SELECT * FROM Student;
SELECT * FROM Exam;
```

### What to expect

After deleting the student with `StudentID = '0555004388'`, every related
row in `Exam` is automatically removed too.

### Check your understanding

1. What's the difference between `NO ACTION` and `CASCADE`?
2. When would `ON DELETE CASCADE` be the right choice?
3. Why can it be dangerous?

<details>
<summary>Show answers</summary>

1. `NO ACTION` blocks the delete while related rows exist. `CASCADE`
    allows the delete and automatically removes the related rows too.
2. When the child rows genuinely have no meaning without the parent — for
    example, invoice line items that only make sense attached to their
    invoice.
3. A single delete can silently remove a large, unreviewed set of related
    rows across the database, which is easy to underestimate in a system
    with several cascading relationships chained together.

</details>

------------------------------------------------------------------------

## Summary of constraints

| Constraint | Purpose | Allows `NULL` | Allows duplicates |
|---|---|---:|---:|
| `NOT NULL` | requires a value | no | yes |
| `PRIMARY KEY` | uniquely identifies a row | no | no |
| `UNIQUE` | enforces uniqueness of an alternate key | depends on the system | no |
| `CHECK` | restricts the allowed values | depends on the definition | yes |
| `FOREIGN KEY` | enforces referential integrity | yes, unless separately forbidden | yes |

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 8 –
Database Integrity and Constraints**.

------------------------------------------------------------------------

## What you should know after this file

- `NOT NULL` prevents unknown values in required columns.
- `DEFAULT` supplies a value automatically when none is given.
- `PRIMARY KEY` uniquely identifies each row and forbids `NULL`.
- `UNIQUE` protects alternate keys.
- `CHECK` restricts which values are allowed in a column.
- `FOREIGN KEY` enforces referential integrity between tables.
- `ALTER TABLE` lets you change a table's structure and constraints after it already exists and holds data.
- A composite key spans several columns; a surrogate key is often introduced to simplify references, with the natural key still protected by `UNIQUE`.

Continue to [09 – Built-in Functions](09-built-in-functions.md) to round
out your SQL toolkit with the math, string, date, and conversion
functions you'll use in almost every real query.
