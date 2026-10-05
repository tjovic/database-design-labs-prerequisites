# 03 – Filtering and Sorting

**Database:** `AdventureWorksENG`

## Learning objectives

After this file, you should be able to:

- filter rows with `WHERE` using comparison operators;
- combine conditions with `AND`, `OR`, and `NOT`;
- use `IN`, `BETWEEN`, and `LIKE`;
- test for missing values with `IS NULL`;
- sort results with `ORDER BY`.

------------------------------------------------------------------------

## Section 1 – WHERE and comparison operators

`WHERE` filters which rows are returned:

```sql
SELECT Name, PriceWithoutVAT
FROM Product
WHERE PriceWithoutVAT > 100;
```

Standard comparison operators are available: `=`, `<>` (not equal), `<`,
`<=`, `>`, `>=`.

```sql
SELECT Name
FROM Product
WHERE Color = 'Crna';
```

> **Note:** Text values are wrapped in single quotes. Comparing text is
> usually case-insensitive in SQL Server's default configuration, so
> `'Crna'` and `'crna'` typically match the same rows.

### Check your understanding

1. Which operator means "not equal to"?
2. What happens if you forget the quotes around a text value?

<details>
<summary>Show answers</summary>

1. `<>` (some databases also accept `!=`).
2. SQL Server tries to interpret it as a column name or keyword, which
    usually raises an error.

</details>

------------------------------------------------------------------------

## Section 2 – Combining conditions: AND, OR, NOT

```sql
SELECT Name, Color, PriceWithoutVAT
FROM Product
WHERE Color = 'Crna' AND PriceWithoutVAT < 50;
```

```sql
SELECT Name, Color
FROM Product
WHERE Color = 'Crna' OR Color = 'Crvena';
```

`NOT` negates a condition:

```sql
SELECT Name, Color
FROM Product
WHERE NOT Color = 'Crna';
```

When mixing `AND` and `OR`, use parentheses to make the intended grouping
explicit — `AND` binds tighter than `OR`, which surprises people:

```sql
-- Ambiguous at a glance — what does this actually select?
SELECT Name
FROM Product
WHERE Color = 'Crna' OR Color = 'Crvena' AND PriceWithoutVAT < 50;

-- Explicit: Crna of any price, OR Crvena under 50
SELECT Name
FROM Product
WHERE Color = 'Crna' OR (Color = 'Crvena' AND PriceWithoutVAT < 50);
```

### Check your understanding

1. Without parentheses, does `AND` or `OR` get evaluated first?
2. Rewrite `WHERE NOT Color = 'Crna'` using `<>` instead.

<details>
<summary>Show answers</summary>

1. `AND` binds tighter than `OR`.
2. `WHERE Color <> 'Crna'`.

</details>

------------------------------------------------------------------------

## Section 3 – IN and BETWEEN

`IN` checks against a list of values — a shorter alternative to multiple
`OR` conditions:

```sql
SELECT Name, Color
FROM Product
WHERE Color IN ('Crna', 'Crvena', 'Plava');
```

`BETWEEN` checks an inclusive range:

```sql
SELECT Name, PriceWithoutVAT
FROM Product
WHERE PriceWithoutVAT BETWEEN 50 AND 100;
```

`BETWEEN 50 AND 100` includes both `50` and `100`.

### Check your understanding

1. Rewrite `WHERE Color = 'Crna' OR Color = 'Crvena' OR Color = 'Plava'` using `IN`.
2. Does `PriceWithoutVAT BETWEEN 50 AND 100` include a product priced at exactly 100?

<details>
<summary>Show answers</summary>

1. `WHERE Color IN ('Crna', 'Crvena', 'Plava')`.
2. Yes — `BETWEEN` is inclusive on both ends.

</details>

------------------------------------------------------------------------

## Section 4 – LIKE and wildcards

`LIKE` matches text patterns using two wildcards:

- `%` matches any number of characters (including zero);
- `_` matches exactly one character.

```sql
-- Names starting with "Mountain"
SELECT Name
FROM Product
WHERE Name LIKE 'Mountain%';

-- Names containing "Bike" anywhere
SELECT Name
FROM Product
WHERE Name LIKE '%Bike%';

-- Exactly 5 characters
SELECT Name
FROM Product
WHERE Name LIKE '_____';
```

### Check your understanding

1. What does `%` match that `_` does not?
2. Write a `LIKE` pattern that matches any product name ending in `"Helmet"`.

<details>
<summary>Show answers</summary>

1. `%` matches zero or more characters; `_` matches exactly one.
2. `LIKE '%Helmet'`.

</details>

------------------------------------------------------------------------

## Section 5 – NULL

`NULL` means "no value" — it is not the same as zero or an empty string.
You cannot compare it with `=`; you must use `IS NULL` or `IS NOT NULL`.

```sql
-- Products with no assigned subcategory
SELECT Name
FROM Product
WHERE SubcategoryID IS NULL;

-- Products that do have one
SELECT Name
FROM Product
WHERE SubcategoryID IS NOT NULL;
```

```sql
-- This never matches any row, even if SubcategoryID looks "empty"
SELECT Name
FROM Product
WHERE SubcategoryID = NULL;
```

> **Why `= NULL` fails:** `NULL` represents an unknown value, so SQL Server
> cannot say whether an unknown value equals another value — the comparison
> evaluates to "unknown", never to "true".

### Check your understanding

1. Why does `WHERE SubcategoryID = NULL` return no rows, even if some products have no subcategory?
2. Which two operators correctly test for `NULL`?

<details>
<summary>Show answers</summary>

1. Because `NULL` means "unknown", and comparing anything to an unknown
    value with `=` never evaluates to true.
2. `IS NULL` and `IS NOT NULL`.

</details>

------------------------------------------------------------------------

## Section 6 – ORDER BY

`ORDER BY` sorts the result. Default order is ascending (`ASC`); use
`DESC` for descending:

```sql
SELECT Name, PriceWithoutVAT
FROM Product
ORDER BY PriceWithoutVAT DESC;
```

You can sort by multiple columns — later columns break ties in earlier
ones:

```sql
SELECT Name, Color, PriceWithoutVAT
FROM Product
ORDER BY Color ASC, PriceWithoutVAT DESC;
```

This sorts by `Color` first; within each color, the most expensive
products come first.

Combine with `TOP` to answer "top N" questions precisely:

```sql
-- The 5 most expensive products
SELECT TOP 5 Name, PriceWithoutVAT
FROM Product
ORDER BY PriceWithoutVAT DESC;
```

### Check your understanding

1. What is the default sort direction if you don't specify `ASC` or `DESC`?
2. In `ORDER BY Color ASC, PriceWithoutVAT DESC`, which column is the primary sort key?

<details>
<summary>Show answers</summary>

1. Ascending (`ASC`).
2. `Color` — `PriceWithoutVAT` only breaks ties within the same color.

</details>

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 3 –
Filtering and Sorting**.

------------------------------------------------------------------------

## What you should know after this file

```sql
SELECT Name, Color, PriceWithoutVAT
FROM Product
WHERE Color IN ('Crna', 'Crvena')
  AND PriceWithoutVAT BETWEEN 20 AND 200
  AND Name LIKE '%Bike%'
  AND SubcategoryID IS NOT NULL
ORDER BY PriceWithoutVAT DESC;
```

## Where to go next

Continue to [04 – Joins](04-joins.md) to combine data from more than one
table.
