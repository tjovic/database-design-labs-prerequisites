# 04 – Joins

**Database:** `AdventureWorksENG`

## Learning objectives

After this file, you should be able to:

- explain why queries need to combine data from more than one table;
- write an `INNER JOIN`;
- write a `LEFT JOIN`, a `RIGHT JOIN`, and a `FULL OUTER JOIN`, and explain how each differs;
- join more than two tables in a single query;
- join a table to itself, both for a hierarchy and for a table used in two different roles;
- write a `CROSS JOIN` and explain when it's actually useful;
- avoid the most common join mistakes.

------------------------------------------------------------------------

## Section 1 – Why joins?

Recall from [01 – Relational Database Basics](01-relational-database-basics.md)
that related data lives in separate tables connected by foreign keys. A
customer's name lives in `Customer`; their invoices live in `Invoice`,
linked by `Invoice.CustomerID`.

If you want "each invoice, with the customer's name", you need to combine
rows from both tables. That is what a **join** does.

------------------------------------------------------------------------

## Section 2 – INNER JOIN

```sql
SELECT
    i.IDInvoice,
    i.InvoiceDate,
    c.FirstName,
    c.LastName
FROM Invoice AS i
INNER JOIN Customer AS c
    ON i.CustomerID = c.IDCustomer;
```

Read this as: "for each row in `Invoice`, find the row in `Customer` whose
`IDCustomer` matches `CustomerID`, and combine them into one result row."

- `i` and `c` are **table aliases** — short names used instead of repeating
  the full table name on every column.
- The `ON` clause states the join condition — which columns must match.

`INNER JOIN` only returns rows where a match is found on **both** sides.
If an invoice somehow had a `CustomerID` that didn't exist in `Customer`,
that invoice would be silently excluded.

### Check your understanding

1. What does the `ON` clause specify?
2. What happens to a row in `Invoice` if its `CustomerID` does not match any row in `Customer`?

<details>
<summary>Show answers</summary>

1. The condition used to match rows between the two tables.
2. With `INNER JOIN`, that invoice is excluded from the result.

</details>

------------------------------------------------------------------------

## Section 3 – LEFT JOIN

Some foreign keys are optional. `Invoice.SalesmanID` can be `NULL` — a
sale does not always have a salesman on record.

If you use `INNER JOIN` here, invoices with no salesman disappear from the
result entirely:

```sql
-- Invoices WITHOUT a salesman are silently dropped
SELECT i.IDInvoice, s.FirstName, s.LastName
FROM Invoice AS i
INNER JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman;
```

`LEFT JOIN` keeps every row from the left table, even if there is no
match on the right — the right-side columns are simply `NULL`:

```sql
SELECT i.IDInvoice, s.FirstName, s.LastName
FROM Invoice AS i
LEFT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman;
```

Now every invoice appears. For invoices with no salesman, `FirstName` and
`LastName` come back as `NULL`.

> **Rule of thumb:** if a foreign key column is nullable, think carefully
> about whether you want `INNER JOIN` (match required) or `LEFT JOIN`
> (match optional) before you write the query.

### Common mistake: filtering a LEFT JOIN in WHERE

```sql
-- This silently turns the LEFT JOIN back into an INNER JOIN!
SELECT i.IDInvoice, s.FirstName
FROM Invoice AS i
LEFT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
WHERE s.FirstName = 'Ana';
```

If you then add a condition on `WHERE SalesmanID IS NULL` to find
invoices *without* a salesman, put it in the `WHERE` clause — that is the
correct, intentional use:

```sql
SELECT i.IDInvoice
FROM Invoice AS i
LEFT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
WHERE s.IDSalesman IS NULL;
```

The difference: filtering on a real value (`s.FirstName = 'Ana'`) discards
the `NULL` rows a `LEFT JOIN` was meant to keep. Filtering on
`IS NULL`/`IS NOT NULL` is how you deliberately ask "which rows had no
match?".

### Check your understanding

1. What is the key difference between `INNER JOIN` and `LEFT JOIN`?
2. Why can adding an ordinary `WHERE` condition on the right-hand table silently undo a `LEFT JOIN`?

<details>
<summary>Show answers</summary>

1. `INNER JOIN` only keeps rows with a match on both sides. `LEFT JOIN`
    keeps every row from the left table regardless of a match, filling
    unmatched right-side columns with `NULL`.
2. Because `NULL` fails ordinary comparisons (see
    [03 – Filtering and Sorting](03-filtering-and-sorting.md#section-5--null)),
    a condition like `s.FirstName = 'Ana'` eliminates the very rows where
    `s.FirstName` is `NULL` — which are exactly the rows `LEFT JOIN` was
    meant to preserve.

</details>

------------------------------------------------------------------------

## Section 4 – RIGHT JOIN

`RIGHT JOIN` is the mirror image of `LEFT JOIN`: it keeps every row from
the **right** table, filling in `NULL` on the left side when there's no
match.

```sql
SELECT
    i.IDInvoice,
    s.IDSalesman,
    s.FirstName,
    s.LastName
FROM Invoice AS i
RIGHT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
ORDER BY s.IDSalesman;
```

This keeps every salesman, even one who hasn't closed any invoice yet.

In practice, `RIGHT JOIN` is used less often than `LEFT JOIN`, because the
same result can always be written as a `LEFT JOIN` by swapping which
table comes first — many people find that reads more naturally ("give me
every salesman, and their invoices if any"):

```sql
SELECT
    s.IDSalesman,
    s.FirstName,
    s.LastName,
    i.IDInvoice
FROM Salesman AS s
LEFT JOIN Invoice AS i
    ON i.SalesmanID = s.IDSalesman
ORDER BY s.IDSalesman;
```

### Check your understanding

1. Rewrite `A RIGHT JOIN B` as an equivalent `LEFT JOIN`.

<details>
<summary>Show answer</summary>

1. `B LEFT JOIN A` (with the same `ON` condition) — swap which table is
    written first.

</details>

------------------------------------------------------------------------

## Section 5 – FULL OUTER JOIN

`FULL OUTER JOIN` keeps every row from **both** tables: rows that match
on both sides, rows from the left with no match on the right, and rows
from the right with no match on the left.

```sql
SELECT
    i.IDInvoice,
    i.SalesmanID AS SalesmanIDOnInvoice,
    s.IDSalesman AS SalesmanIDInSalesmanTable,
    s.LastName
FROM Invoice AS i
FULL OUTER JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
ORDER BY i.IDInvoice, s.IDSalesman;
```

This is useful when you're comparing two tables and want to see
*everything* — both matches and mismatches on either side.

To see **only** the mismatches (invoices with no salesman, and salesmen
with no invoices), add a `WHERE` that requires one side to be missing:

```sql
SELECT
    i.IDInvoice,
    s.IDSalesman,
    s.LastName
FROM Invoice AS i
FULL OUTER JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
WHERE i.IDInvoice IS NULL
   OR s.IDSalesman IS NULL;
```

### Check your understanding

1. What does `FULL OUTER JOIN` return that `LEFT JOIN` alone does not?

<details>
<summary>Show answer</summary>

1. Rows from the right table that have no match in the left table —
    `LEFT JOIN` would drop those, since it only guarantees every row from
    the left table is kept.

</details>

------------------------------------------------------------------------

## Section 6 – Seeing all four side by side

The difference between `INNER`, `LEFT`, `RIGHT`, and `FULL OUTER` is
easiest to see on one small, intuitive example instead of four separate
ones. Let's build two tiny tables and run all four joins against the
exact same data.

> **Forward reference:** `CREATE TABLE` is formally covered in
> [08 – Database Integrity & Constraints](08-database-integrity-and-constraints.md).
> Just copy the statements below as-is — the point here is the `JOIN`.

```sql
CREATE TABLE Club (
    IDClub   INT PRIMARY KEY,
    ClubName NVARCHAR(50) NOT NULL
);

CREATE TABLE Student (
    IDStudent INT PRIMARY KEY,
    Name      NVARCHAR(50) NOT NULL,
    ClubID    INT NULL REFERENCES Club(IDClub)
);

INSERT INTO Club (IDClub, ClubName) VALUES
(10, 'Chess Club'),
(20, 'Art Club');

INSERT INTO Student (IDStudent, Name, ClubID) VALUES
(1, 'Ana',  10),
(2, 'Ivan', 10),
(3, 'Mia',  NULL);
```

```text
Student                       Club
+-----+------+--------+       +-------+------------+
| IDStudent | Name | ClubID|  | IDClub| ClubName   |
+-----+------+--------+       +-------+------------+
| 1   | Ana  | 10     |       | 10    | Chess Club |
| 2   | Ivan | 10     |       | 20    | Art Club   |
| 3   | Mia  | NULL   |       +-------+------------+
+-----+------+--------+
```

Ana and Ivan are both in the Chess Club. **Mia isn't in any club** —
her `ClubID` is `NULL`. The **Art Club has no members** — no `Student`
row points at it. That mismatch on both sides is exactly what makes this
example useful.

### INNER JOIN — only rows that match on both sides

```sql
SELECT s.Name, c.ClubName
FROM Student AS s
INNER JOIN Club AS c
    ON s.ClubID = c.IDClub;
```

| Name | ClubName |
|---|---|
| Ana | Chess Club |
| Ivan | Chess Club |

**2 rows.** Mia drops out (no club to match), and the Art Club drops out
(no student to match).

### LEFT JOIN — every Student, matched Club or not

```sql
SELECT s.Name, c.ClubName
FROM Student AS s
LEFT JOIN Club AS c
    ON s.ClubID = c.IDClub;
```

| Name | ClubName |
|---|---|
| Ana | Chess Club |
| Ivan | Chess Club |
| Mia | NULL |

**3 rows.** Every `Student` row survives — Mia is kept, with `NULL` where
her club would be. The Art Club still doesn't appear: `LEFT JOIN` only
guarantees rows from the left table (`Student`), not the right one.

### RIGHT JOIN — every Club, matched Student or not

```sql
SELECT s.Name, c.ClubName
FROM Student AS s
RIGHT JOIN Club AS c
    ON s.ClubID = c.IDClub;
```

| Name | ClubName |
|---|---|
| Ana | Chess Club |
| Ivan | Chess Club |
| NULL | Art Club |

**3 rows.** Mirror image of `LEFT JOIN`: every `Club` row survives — the
Art Club is kept, with `NULL` where its student would be. Mia disappears
this time, because she isn't part of the right table.

### FULL OUTER JOIN — everything, matched or not

```sql
SELECT s.Name, c.ClubName
FROM Student AS s
FULL OUTER JOIN Club AS c
    ON s.ClubID = c.IDClub;
```

| Name | ClubName |
|---|---|
| Ana | Chess Club |
| Ivan | Chess Club |
| Mia | NULL |
| NULL | Art Club |

**4 rows.** Nothing is lost from either side — the matched pair, Mia on
her own, and the Art Club on its own, all appear.

```sql
-- Cleanup
DROP TABLE Student;
DROP TABLE Club;
```

### Side by side

| Join type | Keeps | Rows here |
|---|---|---|
| `INNER JOIN` | only rows matched on both sides | 2 |
| `LEFT JOIN` | all of `Student`, matched `Club` or not | 3 |
| `RIGHT JOIN` | all of `Club`, matched `Student` or not | 3 |
| `FULL OUTER JOIN` | all of `Student` **and** all of `Club` | 4 |

Same six source rows (three `Student`, two `Club`, one of each
unmatched) — four different answers to "which rows belong together?",
depending on which side you refuse to lose.

### Check your understanding

1. If a fourth student, Boris, were added with `ClubID = NULL`, how many rows would `INNER JOIN` return? How many would `FULL OUTER JOIN` return?
2. Which join would you use to find every club, including ones with no members yet, without caring which students (if any) are in them?

<details>
<summary>Show answers</summary>

1. `INNER JOIN` still returns 2 — Boris has no club, so he can never
    match. `FULL OUTER JOIN` returns 5 — Boris is another unmatched row
    from the left side that must still be kept.
2. `RIGHT JOIN` with `Student` on the left and `Club` on the right (or
    equivalently, `LEFT JOIN` with `Club` written first) — it keeps every
    `Club` row regardless of whether any student matches it.

</details>

------------------------------------------------------------------------

## Section 7 – Joining more than two tables

Joins chain together. To list each invoice line with the product name and
the customer name:

```sql
SELECT
    c.FirstName,
    c.LastName,
    p.Name AS ProductName,
    ii.Quantity,
    ii.TotalPrice
FROM Invoice AS i
INNER JOIN Customer AS c
    ON i.CustomerID = c.IDCustomer
INNER JOIN InvoiceItem AS ii
    ON ii.InvoiceID = i.IDInvoice
INNER JOIN Product AS p
    ON p.IDProduct = ii.ProductID;
```

Each `JOIN` adds one more table to the combined result. Order usually
follows how the tables connect to each other, but SQL Server is free to
execute them in whatever order is fastest — the result is the same either
way.

### Check your understanding

1. How many `JOIN` clauses do you need to combine four tables?
2. In the query above, which table connects `Invoice` to `Product`?

<details>
<summary>Show answers</summary>

1. Three — each `JOIN` adds one additional table.
2. `InvoiceItem`.

</details>

------------------------------------------------------------------------

## Section 8 – Joining a table to itself

Sometimes the table you need to join is the **same** table — in two
different roles.

### Hierarchies: a self join

A classic case: every employee could have a manager, and a manager is
just another employee. The foreign key points back at its own table's
primary key.

`AdventureWorksENG` doesn't have a ready-made hierarchy table, so — just
like in [Section 6](#section-6--seeing-all-four-side-by-side) — let's
build a small scratch table and actually run a self join against it.

```sql
CREATE TABLE Staff (
    IDStaff   INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName  NVARCHAR(50) NOT NULL,
    Salary    DECIMAL(10,2) NOT NULL,
    ManagerID INT NULL,
    CONSTRAINT FK_Staff_Manager FOREIGN KEY (ManagerID) REFERENCES Staff(IDStaff)
);

INSERT INTO Staff (IDStaff, FirstName, LastName, Salary, ManagerID) VALUES
(1, 'Ana',   'Novak',   6000.00, NULL), -- top of the hierarchy, no manager
(2, 'Ivan',  'Kovac',   4200.00, 1),
(3, 'Mia',   'Peric',   6100.00, 1),
(4, 'Boris', 'Matic',   3000.00, 2),
(5, 'Tea',   'Vukovic', 3200.00, 2),
(6, 'Roko',  'Juric',   4500.00, 2),
(7, 'Lana',  'Horvat',  2800.00, 3);

SELECT * FROM Staff;
```

`ManagerID` is a foreign key to `Staff.IDStaff` — the same table. Ana's
`ManagerID` is `NULL`: she's the director, at the top of the hierarchy.
Everyone else points at the `IDStaff` of the person they report to:

```text
Ana (no manager)
├── Ivan
│   ├── Boris
│   ├── Tea
│   └── Roko
└── Mia
    └── Lana
```

Now the self join — list every staff member next to their manager's name:

```sql
SELECT
    emp.FirstName AS EmployeeFirstName,
    emp.LastName  AS EmployeeLastName,
    mgr.FirstName AS ManagerFirstName,
    mgr.LastName  AS ManagerLastName
FROM Staff AS emp
LEFT JOIN Staff AS mgr
    ON emp.ManagerID = mgr.IDStaff
ORDER BY emp.IDStaff;
```

`emp` and `mgr` are both aliases for `Staff` — the same table, joined to
itself. `LEFT JOIN` is required here: Ana has no manager, so an
`INNER JOIN` would silently drop her row entirely (see
[Section 3 – LEFT JOIN](#section-3--left-join) for why).

### A question only a self join answers directly: who out-earns their manager?

```sql
SELECT
    emp.FirstName + ' ' + emp.LastName AS Employee,
    emp.Salary AS EmployeeSalary,
    mgr.FirstName + ' ' + mgr.LastName AS Manager,
    mgr.Salary AS ManagerSalary
FROM Staff AS emp
INNER JOIN Staff AS mgr
    ON emp.ManagerID = mgr.IDStaff
WHERE emp.Salary > mgr.Salary;
```

This returns Mia (who out-earns Ana) and Roko (who out-earns Ivan). Here
`INNER JOIN` is the right choice, not `LEFT JOIN`: Ana has no manager to
compare her salary against, so it's correct for her to drop out of this
particular question.

This pattern — a foreign key pointing back at its own table's primary
key — is how hierarchies are usually modeled: employee → manager,
category → parent category, organizational unit → parent unit.

```sql
-- Cleanup
DROP TABLE Staff;
```

### Check your understanding

1. Why does the first query need `LEFT JOIN`, while the "out-earns their
    manager" query works fine with `INNER JOIN`?
2. What does a `NULL` in `ManagerID` mean for a row in `Staff`?
3. Could `emp` and `mgr` both be dropped in favor of just writing `Staff`
    twice in the `FROM` clause without aliases? Why or why not?

<details>
<summary>Show answers</summary>

1. `LEFT JOIN` is needed to keep rows with no manager (Ana) in the
    result. The salary comparison only makes sense for employees who
    *have* a manager, so `INNER JOIN` correctly excludes Ana there instead
    of comparing her against a `NULL`.
2. That row is at the top of the hierarchy — it has no manager.
3. No. Both occurrences in `FROM` refer to the same table name, so
    without aliases neither SQL Server nor the reader could tell which
    occurrence a column like `FirstName` belongs to.

</details>

------------------------------------------------------------------------

### The same table in two unrelated roles

A different situation: one row has **two** foreign keys to the *same*
table, in two unrelated roles. `AdventureWorksENG` already has a `City`
table, so we only need one small scratch table to see this for real: a
`Person` with both a `BirthCityID` and a `CurrentCityID`, each pointing
at `City`.

```sql
CREATE TABLE Person (
    IDPerson      INT PRIMARY KEY,
    FirstName     NVARCHAR(50) NOT NULL,
    LastName      NVARCHAR(50) NOT NULL,
    BirthCityID   INT NOT NULL REFERENCES City(IDCity),
    CurrentCityID INT NOT NULL REFERENCES City(IDCity)
);

INSERT INTO Person (IDPerson, FirstName, LastName, BirthCityID, CurrentCityID) VALUES
(1, 'Ana',   'Novak', 1, 6),  -- born in Zagreb (1), now lives in Berlin (6)
(2, 'Ivan',  'Kovac', 5, 5),  -- born and still living in Split (5)
(3, 'Marko', 'Peric', 4, 10); -- born in Rijeka (4), now lives in Rome (10)

SELECT * FROM Person;
```

Now join `City` twice — once for each role:

```sql
SELECT
    p.FirstName,
    p.LastName,
    birthCity.Name    AS BirthCity,
    currentCity.Name  AS CurrentCity
FROM Person AS p
INNER JOIN City AS birthCity
    ON p.BirthCityID = birthCity.IDCity
INNER JOIN City AS currentCity
    ON p.CurrentCityID = currentCity.IDCity;
```

| FirstName | LastName | BirthCity | CurrentCity |
|---|---|---|---|
| Ana | Novak | Zagreb | Berlin |
| Ivan | Kovac | Split | Split |
| Marko | Peric | Rijeka | Rome |

`City` appears twice in `FROM` — once per role — each time under a
different alias. Without the aliases, SQL Server wouldn't know which
`City` row you meant in the `SELECT` list.

### Common mistake: one alias for both roles

```sql
-- Mistake: a single alias can't serve two roles at once
SELECT
    p.FirstName,
    p.LastName,
    city.Name AS CityName
FROM Person AS p
INNER JOIN City AS city
    ON p.BirthCityID = city.IDCity
   AND p.CurrentCityID = city.IDCity;
```

| FirstName | LastName | CityName |
|---|---|---|
| Ivan | Kovac | Split |

Only Ivan survives. One joined `City` row now has to satisfy **both**
conditions at the same time, which only works when `BirthCityID` and
`CurrentCityID` happen to be equal — true for Ivan, false for Ana and
Marko. Ana and Marko are both perfectly valid rows; they just silently
vanish. No error, no warning — exactly what makes this mistake dangerous.

```sql
-- Cleanup
DROP TABLE Person;
```

### Check your understanding

1. Why does joining a table to itself (or to the same related table
    twice) require aliases, when some joins technically work without them?
2. In the broken, single-alias version, why does Ivan survive while Ana and Marko don't?

<details>
<summary>Show answers</summary>

1. Both occurrences refer to the same table name, so without aliases
    neither SQL Server nor the reader could tell which occurrence a
    column reference like `FirstName` belongs to.
2. The single `city` alias has to match both `BirthCityID` and
    `CurrentCityID` against the *same* joined row. That's only possible
    when the two foreign keys already point at the same city — which is
    true for Ivan (born and still living in Split) but not for Ana or
    Marko, who moved.

</details>

------------------------------------------------------------------------

## Section 9 – CROSS JOIN

`CROSS JOIN` returns the Cartesian product: every row from the first
table paired with every row from the second. If the first table has 2
rows and the second has 3, the result has 6 rows.

```sql
SELECT
    cat.Name AS CategoryName,
    s.Name   AS StateName
FROM Category AS cat
CROSS JOIN State AS s;
```

This is almost never what you want by accident — but it's exactly what
you want when you deliberately need every combination of two sets: every
product with every available size, every day with every time slot, every
test scenario with every parameter.

### Check your understanding

1. If table `A` has 4 rows and table `B` has 5 rows, how many rows does `A CROSS JOIN B` return?
2. Name one legitimate use case for `CROSS JOIN`.

<details>
<summary>Show answers</summary>

1. 20 (4 × 5).
2. Generating every combination of two independent sets on purpose — for
    example, every product paired with every available size.

</details>

------------------------------------------------------------------------

## Section 10 – A common pitfall: the missing ON

Forgetting the `ON` clause (or using a comma instead of `JOIN`) produces a
**cross join** — every row from the first table paired with every row
from the second. You can see this safely on two small tables:

```sql
-- Mistake: no join condition
SELECT *
FROM Category, Subcategory;
```

`Category` has 4 rows and `Subcategory` has 37, so this returns **148**
rows — every category paired with every subcategory, including the ones
that don't actually belong to it. Run it and count the rows yourself.

> **Don't try this on the big tables.** `Invoice` and `Customer` each have
> tens of thousands of rows in `AdventureWorksENG`. The same mistake
> there — `SELECT * FROM Invoice, Customer;` — doesn't return a
> few hundred extra rows, it returns their row counts *multiplied
> together*: tens of thousands times tens of thousands is **hundreds of
> billions of rows**. That query won't finish in any reasonable time, and
> it's a real way to make SSMS or the server unresponsive. This is exactly
> why the missing-`ON` mistake is dangerous in a real database, not just
> an inconvenience in a toy one. Always double-check that every `JOIN`
> has a matching `ON` before you run it.

> **Recognizing old code:** older SQL sometimes lists tables
> comma-separated in `FROM` and puts the join condition in `WHERE`
> instead of using explicit `JOIN ... ON`:
>
> ```sql
> -- Old style — avoid writing this yourself
> SELECT *
> FROM Invoice AS i, Customer AS c
> WHERE i.CustomerID = c.IDCustomer;
> ```
>
> This produces the same result as an explicit `INNER JOIN`, but mixes
> the join logic into the filter logic, and it's exactly one forgotten
> `WHERE` clause away from silently becoming the cross join above. You
> may see it in older code — recognize it, but write `JOIN ... ON`
> yourself.

### Check your understanding

1. What is it called when two tables are combined without a join condition?
2. `Category` has 4 rows and `Subcategory` has 37. How many rows does `SELECT * FROM Category, Subcategory` produce?
3. Why is the same mistake far more dangerous on `Invoice` and `Customer` than on `Category` and `Subcategory`?

<details>
<summary>Show answers</summary>

1. A cross join.
2. 148 (4 × 37).
3. Because the row counts involved are vastly larger — multiplying two
    tables with tens of thousands of rows each produces hundreds of
    billions of result rows, instead of a few hundred.

</details>

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 4 –
Joins**.

------------------------------------------------------------------------

## What you should know after this file

```sql
-- INNER JOIN: match required
SELECT i.IDInvoice, c.FirstName, c.LastName
FROM Invoice AS i
INNER JOIN Customer AS c
    ON i.CustomerID = c.IDCustomer;

-- LEFT JOIN: match optional, NULL when missing
SELECT i.IDInvoice, s.FirstName
FROM Invoice AS i
LEFT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman;

-- Chaining joins across more than two tables
SELECT c.LastName, p.Name, ii.Quantity
FROM Invoice AS i
INNER JOIN Customer AS c ON i.CustomerID = c.IDCustomer
INNER JOIN InvoiceItem AS ii ON ii.InvoiceID = i.IDInvoice
INNER JOIN Product AS p ON p.IDProduct = ii.ProductID;

-- RIGHT JOIN and FULL OUTER JOIN: keep unmatched rows from the right, or both sides
SELECT s.IDSalesman, i.IDInvoice
FROM Invoice AS i
RIGHT JOIN Salesman AS s ON i.SalesmanID = s.IDSalesman;

SELECT i.IDInvoice, s.IDSalesman
FROM Invoice AS i
FULL OUTER JOIN Salesman AS s ON i.SalesmanID = s.IDSalesman;

-- Self join: same table, two roles, two aliases
-- (uses the scratch Staff table from Section 7 — ManagerID points back at Staff.IDStaff)
SELECT emp.LastName, mgr.LastName AS ManagerLastName
FROM Staff AS emp
LEFT JOIN Staff AS mgr ON emp.ManagerID = mgr.IDStaff;

-- CROSS JOIN: every combination of both tables
SELECT cat.Name, s.Name
FROM Category AS cat
CROSS JOIN State AS s;
```

## Where to go next

Continue to [05 – Aggregate Functions](05-aggregate-functions.md) to
summarize data across many rows.
