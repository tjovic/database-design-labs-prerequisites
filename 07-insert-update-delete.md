# 07 – INSERT, UPDATE, DELETE

**Database:** `AdventureWorksENG`

Everything so far only read data. This file covers changing it.
`INSERT`, `UPDATE`, and `DELETE` are, together with `SELECT`, the core of
SQL's **DML** (Data Manipulation Language) — see
[01, Section 1](01-relational-database-basics.md#section-1--what-is-sql).

## Learning objectives

After this file, you should be able to:

- add new rows with `INSERT`;
- change existing rows with `UPDATE`;
- remove rows with `DELETE`;
- explain why `WHERE` is critical for `UPDATE` and `DELETE`, and how to check your `WHERE` before running either;
- use a transaction as a safety net while practicing `UPDATE`/`DELETE`;
- recognize when a constraint blocks an `UPDATE` or `DELETE`, not just an `INSERT`.

------------------------------------------------------------------------

## Section 1 – INSERT

```sql
INSERT INTO State (Name)
VALUES ('Narnia');
```

Always list the columns you are providing values for, in the same order
as the values. You do not need to supply a value for an identity column
(like a primary key) — SQL Server generates it automatically.

You can insert several rows in one statement:

```sql
INSERT INTO State (Name)
VALUES
    ('Narnia'),
    ('Wakanda'),
    ('Atlantis');
```

```sql
-- Cleanup for the examples above
DELETE FROM State
WHERE Name IN ('Narnia', 'Wakanda', 'Atlantis');
```

> **Note:** if you omit the column list (`INSERT INTO State VALUES (...)`),
> SQL Server matches values to columns by position, including the identity
> column, which usually fails or is fragile. Always specify the column
> list explicitly.

### Check your understanding

1. Do you need to provide a value for an identity (auto-generated) primary key column?
2. Why is it safer to always specify the column list in `INSERT INTO`?

<details>
<summary>Show answers</summary>

1. No — SQL Server generates it automatically.
2. Without an explicit column list, values are matched to columns purely
    by position, which breaks silently if the table structure changes or
    if you miscount values.

</details>

------------------------------------------------------------------------

## Section 2 – UPDATE

```sql
UPDATE Product
SET PriceWithoutVAT = 59.99
WHERE IDProduct = 999999;
```

`SET` lists the columns to change and their new values. `WHERE` decides
*which* rows are affected.

You can update several columns at once:

```sql
UPDATE Product
SET
    PriceWithoutVAT = 59.99,
    Color = 'Plava'
WHERE IDProduct = 999999;
```

### The danger of a missing WHERE

```sql
-- DO NOT RUN — this changes EVERY row in the table.
-- UPDATE Product
-- SET PriceWithoutVAT = 59.99;
```

Without `WHERE`, `UPDATE` applies to every single row. This is one of the
most common and most damaging mistakes in SQL — damaging enough that the
example above is commented out. Don't uncomment and run it, even against
a practice database; get in the habit of never typing out a working
`UPDATE`/`DELETE` without its `WHERE` already in place.

> **Safety habit:** before running an `UPDATE`, run a `SELECT` with the
> exact same `WHERE` clause first, to see precisely which rows would be
> affected:
>
> ```sql
> -- Check first
> SELECT * FROM Product WHERE IDProduct = 999999;
>
> -- Then update, reusing the same WHERE
> UPDATE Product SET PriceWithoutVAT = 59.99 WHERE IDProduct = 999999;
> ```

### Check your understanding

1. What happens if you run an `UPDATE` statement without a `WHERE` clause?
2. What is a safe habit to adopt before running an `UPDATE`?

<details>
<summary>Show answers</summary>

1. Every row in the table is updated.
2. Run a `SELECT` with the same `WHERE` clause first, to confirm exactly
    which rows will be affected.

</details>

------------------------------------------------------------------------

## Section 3 – DELETE

```sql
DELETE FROM State
WHERE Name = 'Narnia';
```

Just like `UPDATE`, `WHERE` decides which rows are removed — and just like
`UPDATE`, omitting it is dangerous:

```sql
-- DO NOT RUN — this deletes EVERY row in the table.
-- DELETE FROM State;
```

The same safety habit applies: `SELECT` with the same `WHERE` first to
confirm what you're about to remove.

### Foreign keys can block a DELETE

If a row is referenced by a foreign key elsewhere, SQL Server refuses to
delete it until the referencing rows are handled first:

```sql
-- Fails if this state still has cities pointing at it
DELETE FROM State
WHERE IDState = 1;
```

This is not a bug — it is the database protecting you from leaving
`City` rows that point at a `State` that no longer exists (an
**orphaned row**).

### Check your understanding

1. What happens if you run `DELETE FROM State` with no `WHERE` clause?
2. Why might SQL Server refuse to delete a row from `State`?

<details>
<summary>Show answers</summary>

1. Every row in `State` is deleted.
2. Because another table (`City`) has a foreign key referencing it, and
    deleting the row would leave those referencing rows pointing at
    nothing.

</details>

------------------------------------------------------------------------

## Section 4 – Putting it together: insert, use, clean up

A pattern you'll use constantly in these exercises: insert temporary data,
query it, then remove it so the database is left exactly as you found it.

```sql
INSERT INTO State (Name)
VALUES ('Narnia');

SELECT *
FROM State
WHERE Name = 'Narnia';

-- Cleanup
DELETE FROM State
WHERE Name = 'Narnia';
```

### Check your understanding

1. Why clean up test data after running an exercise?

<details>
<summary>Show answers</summary>

1. So the database stays in the state other exercises (and other
    students, if the database is shared) expect it to be in.

</details>

------------------------------------------------------------------------

## Section 5 – A safety net: transactions

`UPDATE` and `DELETE` take effect immediately. A transaction lets you try
a change, look at the result, and undo it if it's not what you expected.

```sql
BEGIN TRAN;

UPDATE Product
SET PriceWithoutVAT = PriceWithoutVAT * 1.1
WHERE SubcategoryID = 1;

SELECT Name, PriceWithoutVAT
FROM Product
WHERE SubcategoryID = 1;

ROLLBACK;
```

- `BEGIN TRAN` starts the transaction.
- `ROLLBACK` undoes everything done since `BEGIN TRAN` — as if it never happened.
- `COMMIT` makes the changes permanent instead.

Run the `SELECT` again after the `ROLLBACK` and you'll see the original
prices are back.

> **Practice habit:** while learning `UPDATE`/`DELETE`, wrap your attempt
> in `BEGIN TRAN` ... `ROLLBACK`. You get to see the real result of your
> statement without any risk of leaving the data changed.

### Don't leave a transaction open

A transaction that's still open can hold locks on the rows (sometimes the
pages or the table) it touched, which can make other users' queries wait.
Keep transactions short: prepare and check your `SELECT` first, then open
the transaction, make the change, and immediately `COMMIT` or `ROLLBACK`.

### Check your understanding

1. What does `ROLLBACK` do?
2. Why shouldn't a transaction stay open for a long time?

<details>
<summary>Show answers</summary>

1. It undoes every change made since the transaction began, as if those
    statements never ran.
2. An open transaction can hold locks on the data it touched, which can
    make other users' queries wait or slow down the application.

</details>

------------------------------------------------------------------------

## Section 6 – UPDATE, DELETE, and constraints

The constraints covered in
[08 – Database Integrity & Constraints](08-database-integrity-and-constraints.md)
don't just block a bad `INSERT` — they apply to `UPDATE` and `DELETE`
too.

**A `NOT NULL` column blocks an `UPDATE` that would clear it:**

```sql
-- Fails: Name is NOT NULL
UPDATE Product
SET Name = NULL
WHERE IDProduct = 2;
```

**A `FOREIGN KEY` blocks a `DELETE` that would orphan child rows:**

```sql
-- Fails: this product appears on thousands of InvoiceItem rows
DELETE FROM Product
WHERE IDProduct = 870;
```

**A primary key that's also an `IDENTITY` column can't be updated at all:**

```sql
-- Fails — not because of a duplicate, but because IDProduct is IDENTITY
UPDATE Product
SET IDProduct = 999999
WHERE IDProduct = 870;
```

SQL Server refuses this outright with *Cannot update identity column
'IDProduct'* — a stricter rule than just "no duplicates," specific to
identity columns. If a primary key were an ordinary (non-identity)
column instead, the same kind of `UPDATE` would still be blocked, but for
one of the two reasons you've already seen: a `PRIMARY KEY` violation if
the new value duplicates another row, or a `FOREIGN KEY` violation if
something else still references the old value.

None of this is the database being difficult — it's the same integrity
guarantee working in both directions: a constraint that stops bad data
from going in also stops good data from being broken on the way out.

### Check your understanding

1. Besides `INSERT`, which other two statements can a `FOREIGN KEY` constraint block?
2. Why does a `NOT NULL` constraint reject `UPDATE ... SET Name = NULL`, not just `INSERT ... VALUES (..., NULL, ...)`?

<details>
<summary>Show answers</summary>

1. `UPDATE` (of the referenced key) and `DELETE` (of a referenced row
    that still has children).
2. `NOT NULL` is a rule about the column's current value at all times,
    not just at the moment a row is created — `UPDATE` is just as capable
    of introducing a `NULL` as `INSERT` is.

</details>

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 7 –
INSERT, UPDATE, DELETE**.

------------------------------------------------------------------------

## What you should know after this file

```sql
-- Insert
INSERT INTO State (Name)
VALUES ('Example');

-- Update, always with WHERE
UPDATE State
SET Name = 'Example Updated'
WHERE Name = 'Example';

-- Delete, always with WHERE
DELETE FROM State
WHERE Name = 'Example Updated';

-- Try a change safely before committing to it
BEGIN TRAN;
UPDATE State SET Name = 'Example Updated' WHERE Name = 'Example';
SELECT * FROM State WHERE Name = 'Example Updated';
ROLLBACK;
```

## Where to go next

Continue to [08 – Database Integrity & Constraints](08-database-integrity-and-constraints.md)
to see how a table enforces its own rules — required values, uniqueness,
valid ranges, and valid references to other tables — so that incorrect
data can't be inserted, changed into, or left behind by a delete.
