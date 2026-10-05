# 02 – SELECT Basics

**Database:** `AdventureWorksENG`

Start by selecting the database used in the examples:

```sql
USE AdventureWorksENG;
GO
```

## Learning objectives

After this file, you should be able to:

- write a `SELECT` statement that returns specific columns;
- give a column a different name in the result using an alias;
- remove duplicate rows with `DISTINCT`;
- limit how many rows come back with `TOP`.

------------------------------------------------------------------------

## Section 1 – SELECT and FROM

Every query starts with two things: **what** you want to see, and
**where** it comes from.

```sql
SELECT column_list
FROM table_name;
```

To see every column, use `*`:

```sql
SELECT *
FROM Product;
```

In real queries, prefer listing the columns you actually need:

```sql
SELECT Name, Color, PriceWithoutVAT
FROM Product;
```

> **Why not always `*`?** Listing columns explicitly makes the query's
> intent clear, and it keeps working even if someone adds a column to the
> table later.

### Check your understanding

1. What does `SELECT *` do?
2. Name one downside of using `SELECT *` in real code.

<details>
<summary>Show answers</summary>

1. It returns every column of the table.
2. It can return more data than needed, and the result shape can silently
    change if the table structure changes later.

</details>

------------------------------------------------------------------------

## Section 2 – Column aliases

You can rename a column in the result using `AS`:

```sql
SELECT
    Name            AS ProductName,
    PriceWithoutVAT AS Price
FROM Product;
```

`AS` is optional but recommended — it makes the intent explicit:

```sql
SELECT Name ProductName   -- works, but easy to misread
FROM Product;
```

Aliases are especially useful for computed values, which otherwise get an
unreadable auto-generated column name:

```sql
SELECT
    Name,
    PriceWithoutVAT * 1.25 AS PriceWithVAT
FROM Product;
```

### Check your understanding

1. What keyword introduces a column alias?
2. Why are aliases especially useful for computed columns?

<details>
<summary>Show answers</summary>

1. `AS` (optional, but recommended for clarity).
2. A computed expression has no natural column name, so without an alias
    the result column name is unreadable or tool-generated.

</details>

------------------------------------------------------------------------

## Section 3 – DISTINCT

`DISTINCT` removes duplicate rows from the result:

```sql
SELECT DISTINCT Color
FROM Product;
```

Without `DISTINCT`, every row's `Color` would be listed, including repeats.
With it, each distinct color appears once.

`DISTINCT` applies to the whole row being selected, not to a single
column:

```sql
SELECT DISTINCT Color, SubcategoryID
FROM Product;
```

This returns each unique *combination* of `Color` and `SubcategoryID`, not
each unique color and each unique subcategory separately.

### Check your understanding

1. What does `SELECT DISTINCT Color, SubcategoryID` consider when deciding whether two rows are duplicates?

<details>
<summary>Show answers</summary>

1. The combination of both columns together — two rows are only removed as
    duplicates if `Color` and `SubcategoryID` match on both.

</details>

------------------------------------------------------------------------

## Section 4 – TOP

`TOP` limits how many rows are returned:

```sql
SELECT TOP 5 *
FROM Product;
```

This is useful while exploring a table, or when you only need a sample —
but on its own, `TOP` does not guarantee *which* 5 rows you get. (You will
fix that in the next file with `ORDER BY`.)

`TOP` can also take a percentage:

```sql
SELECT TOP 10 PERCENT *
FROM Product;
```

### Check your understanding

1. Does `SELECT TOP 5 * FROM Product` guarantee you get the 5 cheapest products?

<details>
<summary>Show answers</summary>

1. No. Without `ORDER BY`, SQL Server does not guarantee a specific row
    order, so `TOP` just returns *some* 5 rows.

</details>

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 2 –
SELECT Basics** before moving on.

------------------------------------------------------------------------

## What you should know after this file

```sql
-- Specific columns, with an alias
SELECT Name AS ProductName, PriceWithoutVAT AS Price
FROM Product;

-- Unique values
SELECT DISTINCT Color
FROM Product;

-- Limit the number of rows
SELECT TOP 5 *
FROM Product;
```

## Where to go next

Continue to [03 – Filtering and Sorting](03-filtering-and-sorting.md) to
control *which* rows come back and in *what order*.
