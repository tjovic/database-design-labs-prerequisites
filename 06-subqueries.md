# 06 – Subqueries

**Database:** `AdventureWorksENG`

## Learning objectives

After this file, you should be able to:

- write a scalar subquery and use it inside `WHERE`;
- filter rows using `IN` and `NOT IN` with a subquery;
- filter rows using `EXISTS`;
- use a subquery as a source table inside `FROM`;
- use a correlated subquery inside `SELECT` to compute a per-row value;
- use a subquery inside `HAVING` to filter groups against an aggregate.

A **subquery** is a `SELECT` statement nested inside another query.

------------------------------------------------------------------------

## Section 1 – Scalar subqueries

A **scalar subquery** returns exactly one value (one row, one column). It
can be used anywhere a single value is expected:

```sql
-- Products priced above the average price
SELECT Name, PriceWithoutVAT
FROM Product
WHERE PriceWithoutVAT > (
    SELECT AVG(PriceWithoutVAT)
    FROM Product
);
```

The subquery `(SELECT AVG(PriceWithoutVAT) FROM Product)` runs first,
producing a single number. The outer query then compares every product's
price against that number.

> If a scalar subquery unexpectedly returns more than one row, SQL Server
> raises an error at run time — it has no way to compare a value against
> several rows with `=` or `>`.

### Check your understanding

1. How many rows and columns must a scalar subquery return?
2. What happens if a scalar subquery used with `>` returns two rows?

<details>
<summary>Show answers</summary>

1. Exactly one row, one column.
2. SQL Server raises an error, because `>` needs a single value to compare
    against.

</details>

------------------------------------------------------------------------

## Section 2 – IN and NOT IN with a subquery

When the subquery can return **multiple** rows, compare against it with
`IN` instead of `=`:

```sql
-- Customers who live in Croatia (StateID from a subquery on State)
SELECT FirstName, LastName
FROM Customer
WHERE CityID IN (
    SELECT IDCity
    FROM City
    WHERE StateID = (SELECT IDState FROM State WHERE Name = 'Croatia')
);
```

`NOT IN` excludes matches:

```sql
-- Products that have never appeared on an invoice
SELECT Name
FROM Product
WHERE IDProduct NOT IN (
    SELECT ProductID
    FROM InvoiceItem
);
```

> **Careful with `NOT IN` and NULL:** if the subquery can return a `NULL`
> value, `NOT IN` can unexpectedly return **zero rows** for the entire
> query — a `NULL` in the list makes every comparison "unknown" rather than
> true or false. Prefer `NOT EXISTS` (next section) when the subquery
> column might contain `NULL`.

### Check your understanding

1. Why use `IN` instead of `=` when a subquery might return multiple rows?
2. What is the risk of using `NOT IN` with a subquery column that can contain `NULL`?

<details>
<summary>Show answers</summary>

1. `=` only compares against a single value; `IN` checks membership in a
    list of values.
2. If any value in the subquery's result is `NULL`, `NOT IN` can return no
    rows at all for the whole query, even when you expect matches.

</details>

------------------------------------------------------------------------

## Section 3 – EXISTS

`EXISTS` checks whether a subquery returns **any** rows at all — it does
not care about the actual values, only whether at least one row matches.

```sql
-- Customers who have placed at least one invoice
SELECT FirstName, LastName
FROM Customer AS c
WHERE EXISTS (
    SELECT 1
    FROM Invoice AS i
    WHERE i.CustomerID = c.IDCustomer
);
```

Notice the subquery references the outer query's `c.IDCustomer` — this is
called a **correlated subquery**: it runs (conceptually) once per outer
row, checking "does this specific customer have any invoices?"

`NOT EXISTS` is the safe way to express "has none" — it does not suffer
from the `NULL` trap that `NOT IN` does:

```sql
-- Customers who have never placed an invoice
SELECT FirstName, LastName
FROM Customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM Invoice AS i
    WHERE i.CustomerID = c.IDCustomer
);
```

### Check your understanding

1. What does `EXISTS` actually check — the values returned, or whether any row is returned?
2. What is a correlated subquery?
3. Why is `NOT EXISTS` generally safer than `NOT IN`?

<details>
<summary>Show answers</summary>

1. Whether any row is returned — the actual column values don't matter,
    which is why `SELECT 1` is a common convention inside `EXISTS`.
2. A subquery that references a column from the outer query, so its result
    can differ for each outer row.
3. `NOT EXISTS` is unaffected by `NULL` values in the inner query, unlike
    `NOT IN`.

</details>

------------------------------------------------------------------------

## Section 4 – Subqueries in FROM

A subquery can also act as a table, used directly inside `FROM`. This is
sometimes called a **derived table**. It must be given an alias.

```sql
SELECT
    ColorSummary.Color,
    ColorSummary.ProductCount
FROM (
    SELECT Color, COUNT(*) AS ProductCount
    FROM Product
    GROUP BY Color
) AS ColorSummary
WHERE ColorSummary.ProductCount > 10;
```

This is useful when you need to filter or join on the result of an
aggregation — something `HAVING` alone cannot do if you need to combine it
with other tables afterward.

### Check your understanding

1. What must every subquery inside `FROM` have?
2. Give one reason to use a derived table instead of `HAVING`.

<details>
<summary>Show answers</summary>

1. An alias.
2. A derived table's result can be joined to other tables or filtered
    again, which plain `HAVING` on its own cannot do.

</details>

------------------------------------------------------------------------

## Section 5 – Subqueries in SELECT

A correlated subquery can also sit directly in the `SELECT` list, to
compute one extra value per row.

```sql
-- For each customer, how many invoices do they have?
SELECT
    c.IDCustomer,
    c.FirstName,
    c.LastName,
    (
        SELECT COUNT(*)
        FROM Invoice AS i
        WHERE i.CustomerID = c.IDCustomer
    ) AS InvoiceCount
FROM Customer AS c
ORDER BY InvoiceCount DESC;
```

Just like the `EXISTS` example in the previous section, this subquery is
correlated — it references `c.IDCustomer` from the outer query, so it
conceptually runs once per customer row.

Because this subquery is used as a single value (a scalar), the same rule
from Section 1 applies: it must return exactly one row and one column for
every outer row.

```sql
-- For each invoice, how many line items does it have?
SELECT
    i.IDInvoice,
    i.InvoiceNumber,
    (
        SELECT COUNT(*)
        FROM InvoiceItem AS ii
        WHERE ii.InvoiceID = i.IDInvoice
    ) AS LineItemCount
FROM Invoice AS i
ORDER BY LineItemCount DESC;
```

### Check your understanding

1. Why must a subquery used in the `SELECT` list return exactly one value per outer row?
2. What makes the subqueries above "correlated" rather than independent?

<details>
<summary>Show answers</summary>

1. A `SELECT` list column holds one value per row — a subquery placed
    there is used as a scalar, so it's bound by the same one-row,
    one-column rule as a scalar subquery in `WHERE`.
2. Each subquery references a column from the outer row (`c.IDCustomer`,
    `i.IDInvoice`), so its result depends on which outer row is currently
    being processed.

</details>

------------------------------------------------------------------------

## Section 6 – Subqueries in HAVING

Recall from [05 – Aggregate Functions](05-aggregate-functions.md) that
`HAVING` filters groups after aggregation. A subquery in `HAVING` is
useful when the threshold itself is computed, rather than a fixed number.

```sql
-- Products sold in a total quantity above the average across all products
SELECT
    ProductID,
    SUM(Quantity) AS TotalSold
FROM InvoiceItem
GROUP BY ProductID
HAVING SUM(Quantity) > (
    SELECT AVG(ProductTotals.TotalSold)
    FROM (
        SELECT SUM(Quantity) AS TotalSold
        FROM InvoiceItem
        GROUP BY ProductID
    ) AS ProductTotals
)
ORDER BY TotalSold DESC;
```

The inner derived table computes a total per product first; the subquery
in `HAVING` then averages *those* totals, and the outer query keeps only
the products above that average.

> **Why not just `HAVING SUM(Quantity) > 100`?** A literal threshold
> works until the data changes — "above average" stays meaningful no
> matter how the numbers shift over time. The trade-off is a more complex
> query, so reach for this only when the threshold genuinely needs to be
> computed.

### Check your understanding

1. What does the inner derived table in the example compute?
2. Why would a subquery in `HAVING` be preferable to a hardcoded number?

<details>
<summary>Show answers</summary>

1. The total quantity sold, per product — one row per `ProductID`.
2. A hardcoded number goes stale as the data changes; a subquery
    recomputes the threshold (here, the average total across products)
    every time the query runs.

</details>

------------------------------------------------------------------------

## Section 7 – Subquery or JOIN?

Many subqueries can be rewritten as joins, and vice versa. As a rough
guide:

- Use a **join** when you need columns from both tables in the result.
- Use `EXISTS` / `NOT EXISTS` when you only need to check for the
  **presence or absence** of a related row, and don't need any of its
  columns.
- Use a **scalar subquery** when you need a single summary value (an
  average, a max) to compare against.

```sql
-- JOIN: needs columns from both tables
SELECT c.FirstName, i.InvoiceDate
FROM Customer AS c
INNER JOIN Invoice AS i ON i.CustomerID = c.IDCustomer;

-- EXISTS: only needs to know "has at least one invoice", no Invoice columns used
SELECT c.FirstName
FROM Customer AS c
WHERE EXISTS (SELECT 1 FROM Invoice AS i WHERE i.CustomerID = c.IDCustomer);
```

### Check your understanding

1. If you need both the customer's name and their invoice date in the result, should you use a join or `EXISTS`?

<details>
<summary>Show answers</summary>

1. A join — `EXISTS` cannot return columns from the inner query.

</details>

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 6 –
Subqueries**.

------------------------------------------------------------------------

## What you should know after this file

```sql
-- Scalar subquery
SELECT Name FROM Product
WHERE PriceWithoutVAT > (SELECT AVG(PriceWithoutVAT) FROM Product);

-- IN with a subquery
SELECT Name FROM Product
WHERE IDProduct NOT IN (SELECT ProductID FROM InvoiceItem);

-- Correlated EXISTS
SELECT FirstName FROM Customer AS c
WHERE EXISTS (SELECT 1 FROM Invoice AS i WHERE i.CustomerID = c.IDCustomer);

-- Derived table
SELECT * FROM (
    SELECT Color, COUNT(*) AS ProductCount
    FROM Product
    GROUP BY Color
) AS ColorSummary
WHERE ProductCount > 10;

-- Correlated subquery in SELECT
SELECT c.FirstName,
    (SELECT COUNT(*) FROM Invoice AS i WHERE i.CustomerID = c.IDCustomer) AS InvoiceCount
FROM Customer AS c;

-- Subquery in HAVING
SELECT ProductID, SUM(Quantity) AS TotalSold
FROM InvoiceItem
GROUP BY ProductID
HAVING SUM(Quantity) > (SELECT AVG(Quantity) FROM InvoiceItem);
```

## Where to go next

Continue to [07 – INSERT, UPDATE, DELETE](07-insert-update-delete.md) to
start modifying data, not just reading it.
