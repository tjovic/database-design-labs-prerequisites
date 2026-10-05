# 05 – Aggregate Functions

**Database:** `AdventureWorksENG`

## Learning objectives

After this file, you should be able to:

- use `COUNT`, `SUM`, `AVG`, `MIN`, and `MAX` to summarize rows;
- group rows with `GROUP BY` and compute one aggregate per group;
- group by several columns at once, including across a chain of joins;
- filter groups with `HAVING`, and explain how it differs from `WHERE`;
- combine `TOP` with `GROUP BY` and `ORDER BY` to answer "top N groups" questions;
- recognize the most common `GROUP BY` mistakes.

------------------------------------------------------------------------

## Section 1 – Aggregate functions over the whole table

An **aggregate function** takes many rows and produces one value.

```sql
-- How many products are there in total?
SELECT COUNT(*) AS ProductCount
FROM Product;

-- What is the most expensive product?
SELECT MAX(PriceWithoutVAT) AS HighestPrice
FROM Product;

-- Average price
SELECT AVG(PriceWithoutVAT) AS AveragePrice
FROM Product;
```

Common aggregate functions:

| Function | Returns |
|---|---|
| `COUNT(*)` | number of rows |
| `COUNT(column)` | number of **non-NULL** values in that column |
| `SUM(column)` | total of all values |
| `AVG(column)` | average of all values |
| `MIN(column)` | smallest value |
| `MAX(column)` | largest value |

> **`COUNT(*)` vs `COUNT(column)`:** `COUNT(*)` counts rows regardless of
> `NULL`s. `COUNT(SubcategoryID)` counts only the rows where
> `SubcategoryID` is not `NULL` — useful when you specifically want to know
> how many values are actually present.

### Check your understanding

1. What is the difference between `COUNT(*)` and `COUNT(SubcategoryID)`?
2. Which aggregate function would you use to find the cheapest product?

<details>
<summary>Show answers</summary>

1. `COUNT(*)` counts every row. `COUNT(SubcategoryID)` counts only rows
    where `SubcategoryID` is not `NULL`.
2. `MIN(PriceWithoutVAT)`.

</details>

------------------------------------------------------------------------

## Section 2 – GROUP BY

Aggregates become far more useful when computed **per group** instead of
over the whole table.

```sql
-- Number of products per color
SELECT
    Color,
    COUNT(*) AS ProductCount
FROM Product
GROUP BY Color;
```

This produces one row per distinct `Color`, with the count of products in
that color.

**Rule:** every column in `SELECT` that is not inside an aggregate
function must also appear in `GROUP BY`.

```sql
-- Average price per color, per subcategory
SELECT
    Color,
    SubcategoryID,
    AVG(PriceWithoutVAT) AS AveragePrice
FROM Product
GROUP BY Color, SubcategoryID;
```

### Combining with JOIN

```sql
-- Total revenue per customer
SELECT
    c.IDCustomer,
    c.FirstName,
    c.LastName,
    SUM(ii.TotalPrice) AS TotalSpent
FROM Customer AS c
INNER JOIN Invoice AS i
    ON i.CustomerID = c.IDCustomer
INNER JOIN InvoiceItem AS ii
    ON ii.InvoiceID = i.IDInvoice
GROUP BY c.IDCustomer, c.FirstName, c.LastName;
```

### Grouping across a chain of joins

`GROUP BY` works the same way no matter how many tables you joined to
get there — it groups the final combined rows, not any one table on its
own.

```sql
-- Number of products per category, going through Subcategory
SELECT
    cat.Name AS CategoryName,
    COUNT(p.IDProduct) AS ProductCount
FROM Category AS cat
INNER JOIN Subcategory AS sc
    ON sc.CategoryID = cat.IDCategory
INNER JOIN Product AS p
    ON p.SubcategoryID = sc.IDSubcategory
GROUP BY cat.Name
ORDER BY ProductCount DESC;
```

> **Count the right thing after a join.** Here we count
> `p.IDProduct` — the product's own key — not `cat.IDCategory` or
> `sc.IDSubcategory`. `COUNT(*)` would also work and give the same
> answer, but naming the column you actually mean makes the intent
> explicit, especially once `LEFT JOIN` is involved (see the mistakes
> list below).

### Check your understanding

1. Why must `Color` appear in `GROUP BY` if it also appears in `SELECT` next to `COUNT(*)`?
2. What does `GROUP BY Color, SubcategoryID` produce one row per?

<details>
<summary>Show answers</summary>

1. Because `Color` is not inside an aggregate function — SQL Server needs
    to know how to collapse multiple rows per `Color` value into one, and
    `GROUP BY` is what defines that collapsing.
2. One row per distinct combination of `Color` and `SubcategoryID`.

</details>

------------------------------------------------------------------------

## Section 3 – HAVING vs WHERE

`WHERE` filters rows **before** grouping. `HAVING` filters groups **after**
aggregation.

```sql
-- WHERE: only consider products over 50 before grouping
SELECT Color, COUNT(*) AS ProductCount
FROM Product
WHERE PriceWithoutVAT > 50
GROUP BY Color;

-- HAVING: show only colors with more than 10 products
SELECT Color, COUNT(*) AS ProductCount
FROM Product
GROUP BY Color
HAVING COUNT(*) > 10;
```

You can use both together:

```sql
SELECT Color, COUNT(*) AS ProductCount
FROM Product
WHERE PriceWithoutVAT > 50
GROUP BY Color
HAVING COUNT(*) > 10;
```

> **Why `HAVING` exists:** `WHERE` runs before groups are formed, so it
> cannot reference an aggregate like `COUNT(*)` — that value doesn't exist
> yet at that point. `HAVING` runs after grouping, so it can.

### Check your understanding

1. Can `WHERE COUNT(*) > 10` be used instead of `HAVING COUNT(*) > 10`?
2. In what order does SQL Server conceptually apply `WHERE`, `GROUP BY`, and `HAVING`?

<details>
<summary>Show answers</summary>

1. No — `WHERE` is evaluated before grouping happens, so the aggregate
    does not exist yet at that point. This raises an error.
2. `WHERE` first (filter rows), then `GROUP BY` (form groups and compute
    aggregates), then `HAVING` (filter groups).

</details>

------------------------------------------------------------------------

## Section 4 – TOP with GROUP BY

Combine `TOP` with `GROUP BY` and `ORDER BY` to answer "top N groups"
questions — for example, the 5 best-selling products by quantity sold.

```sql
SELECT TOP 5
    p.Name,
    SUM(ii.Quantity) AS QuantitySold
FROM Product AS p
INNER JOIN InvoiceItem AS ii
    ON ii.ProductID = p.IDProduct
GROUP BY p.Name
ORDER BY QuantitySold DESC;
```

`GROUP BY` and the aggregate run first, producing one row per product;
`ORDER BY` sorts those group results; `TOP 5` then keeps only the first
five. Without `ORDER BY`, `TOP` would return five arbitrary groups,
exactly as with a plain `SELECT` (see
[02 – SELECT Basics](02-select-basics.md#section-4--top)).

### Check your understanding

1. In what order do `GROUP BY`, `ORDER BY`, and `TOP` conceptually apply here?

<details>
<summary>Show answer</summary>

1. `GROUP BY` forms the groups and computes the aggregate first, then
    `ORDER BY` sorts the resulting one-row-per-group output, and `TOP`
    takes the first N rows of that sorted result.

</details>

------------------------------------------------------------------------

## Section 5 – Common GROUP BY mistakes

**1. A plain column in `SELECT` that's missing from `GROUP BY`.**

```sql
-- Fails: Color is not aggregated and not grouped
SELECT Color, COUNT(*)
FROM Product;
```

```sql
-- Fixed
SELECT Color, COUNT(*)
FROM Product
GROUP BY Color;
```

**2. Using `WHERE` instead of `HAVING` to filter on an aggregate.**

```sql
-- Fails: WHERE can't see COUNT(*), it runs before grouping
SELECT Color, COUNT(*)
FROM Product
WHERE COUNT(*) > 10
GROUP BY Color;
```

```sql
-- Fixed
SELECT Color, COUNT(*)
FROM Product
GROUP BY Color
HAVING COUNT(*) > 10;
```

**3. Counting the wrong table's column after a join.**

If you want "products per subcategory," count a `Product` column — not a
`Subcategory` column, which only counts subcategory rows themselves:

```sql
-- Wrong idea: this counts Subcategory rows, not Product rows
SELECT s.Name, COUNT(s.IDSubcategory)
FROM Subcategory AS s
INNER JOIN Product AS p ON p.SubcategoryID = s.IDSubcategory
GROUP BY s.Name;

-- Correct: count the Product side
SELECT s.Name, COUNT(p.IDProduct) AS ProductCount
FROM Subcategory AS s
INNER JOIN Product AS p ON p.SubcategoryID = s.IDSubcategory
GROUP BY s.Name;
```

> With `INNER JOIN` both versions happen to return the same numbers here,
> because every matched row has both a `Subcategory` and a `Product` id.
> The distinction becomes real with `LEFT JOIN`: `COUNT(s.IDSubcategory)`
> and `COUNT(p.IDProduct)` can then disagree, because `COUNT(column)`
> ignores `NULL`s (see [05 – Aggregate Functions, Section 1](#section-1--aggregate-functions-over-the-whole-table)) —
> a subcategory with no matching product leaves `p.IDProduct` `NULL`, but
> not `s.IDSubcategory`.

**4. Forgetting `GROUP BY` entirely when mixing aggregates and detail columns.**

```sql
-- Fails: Name is a per-row column, SUM(...) is a whole-group value
SELECT Name, SUM(PriceWithoutVAT)
FROM Product;
```

Decide what one output row should represent — one product, or one group
— and make sure every non-aggregated column matches that.

### Check your understanding

1. Why does mixing a plain column with an aggregate function in `SELECT`, with no `GROUP BY` at all, fail?

<details>
<summary>Show answer</summary>

1. SQL Server can't reconcile a per-row value (the plain column) with a
    whole-group value (the aggregate) without being told how to form the
    groups — that's exactly what `GROUP BY` specifies.

</details>

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 5 –
Aggregate Functions**.

------------------------------------------------------------------------

## What you should know after this file

```sql
SELECT
    c.LastName,
    COUNT(*) AS InvoiceCount,
    SUM(ii.TotalPrice) AS TotalSpent
FROM Customer AS c
INNER JOIN Invoice AS i ON i.CustomerID = c.IDCustomer
INNER JOIN InvoiceItem AS ii ON ii.InvoiceID = i.IDInvoice
GROUP BY c.LastName
HAVING SUM(ii.TotalPrice) > 1000
ORDER BY TotalSpent DESC;
```

## Where to go next

Continue to [06 – Subqueries](06-subqueries.md) to nest one query inside
another.
