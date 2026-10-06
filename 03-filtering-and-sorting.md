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

A single `WHERE` condition is often not enough. SQL combines several
conditions using three logical operators: `AND`, `OR`, and `NOT`. Each
one takes conditions that are each `TRUE` or `FALSE`, and produces a new
`TRUE`/`FALSE` result — exactly like the logical AND/OR/NOT you may
already know from programming.

### AND — every condition must hold

```sql
SELECT Name, Color, PriceWithoutVAT
FROM Product
WHERE Color = 'Crna' AND PriceWithoutVAT < 50;
```

A row is included only if **both** conditions are `TRUE`. If either one
is `FALSE`, the row is excluded.

| `A` | `B` | `A AND B` |
|---|---|---|
| TRUE  | TRUE  | **TRUE**  |
| TRUE  | FALSE | FALSE |
| FALSE | TRUE  | FALSE |
| FALSE | FALSE | FALSE |

Only one row in the table has `TRUE` on both sides — `AND` is "picky":
adding more conditions with `AND` can only keep the same rows or narrow
the result further, never widen it.

### OR — at least one condition must hold

```sql
SELECT Name, Color
FROM Product
WHERE Color = 'Crna' OR Color = 'Crvena';
```

A row is included if **at least one** condition is `TRUE`. It only takes
one `FALSE AND FALSE` row to exclude a row.

| `A` | `B` | `A OR B` |
|---|---|---|
| TRUE  | TRUE  | **TRUE** |
| TRUE  | FALSE | **TRUE** |
| FALSE | TRUE  | **TRUE** |
| FALSE | FALSE | FALSE |

Three rows out of four are `TRUE` — `OR` is "generous": adding more
conditions with `OR` can only keep the same rows or widen the result
further, never narrow it. That's the opposite of `AND`.

### NOT — flips a condition

```sql
SELECT Name, Color
FROM Product
WHERE NOT Color = 'Crna';
```

`NOT` simply reverses the condition's result:

| `A` | `NOT A` |
|---|---|
| TRUE  | FALSE |
| FALSE | TRUE  |

> **Forward reference:** these tables only have two outcomes, `TRUE` and
> `FALSE`, because they assume every condition can be cleanly answered.
> Once a column can be `NULL`, SQL gets a third outcome — `UNKNOWN` — and
> these same operators behave a little differently. That's covered in
> [Section 5 – NULL](#section-5--null).

When `AND` and `OR` appear in the same condition, SQL doesn't just
evaluate them left to right — it follows **operator precedence**, the
same idea as `*` being evaluated before `+` in arithmetic. Each
operator has a fixed rank, and higher-ranked operators are evaluated
first regardless of where they appear:

1. comparisons (`=`, `<>`, `<`, `>`, ...) — evaluated first, producing a `TRUE`/`FALSE`/`UNKNOWN` for each condition;
2. `NOT`;
3. `AND`;
4. `OR` — evaluated last.

So `AND` has higher precedence than `OR`: wherever both appear without
parentheses, the `AND` part is grouped first, as if it already had
parentheses around it. This is exactly the kind of thing operator
precedence causes people to get wrong, because it doesn't match reading
the condition left to right. Use parentheses to make the intended
grouping explicit instead of relying on people remembering this order:

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

1. Using the `AND` truth table, what is `TRUE AND FALSE`?
2. Using the `OR` truth table, what is `FALSE OR FALSE`?
3. Why can adding another condition with `AND` never return *more* rows than before?
4. What is the name of the general rule that makes `AND` get grouped before `OR` when there are no parentheses?
5. Without parentheses, does `AND` or `OR` get evaluated first?
6. Rewrite `WHERE NOT Color = 'Crna'` using `<>` instead.

<details>
<summary>Show answers</summary>

1. `FALSE`.
2. `FALSE` — `OR` is only `TRUE` when at least one side is `TRUE`.
3. `AND` requires every condition to be `TRUE`. A row that already fails
    one condition stays excluded, and a row that passes all conditions so
    far can still be knocked out by the new one — it can never let in a
    row that didn't already satisfy everything before it.
4. Operator precedence — the same general rule that makes `*` evaluate
    before `+` in arithmetic.
5. `AND` — it has higher precedence than `OR`.
6. `WHERE Color <> 'Crna'`.

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

### NULL with AND, OR, NOT

This is the forward reference promised back in
[Section 2](#section-2--combining-conditions-and-or-not). The truth
tables there only had `TRUE` and `FALSE`. Once a comparison involves
`NULL`, it evaluates to a third outcome, `UNKNOWN` — and `WHERE` keeps a
row only when the overall condition comes out `TRUE`. `FALSE` and
`UNKNOWN` are both excluded, which is exactly what trips people up.

| `AND` | TRUE | FALSE | UNKNOWN |
|---|---|---|---|
| **TRUE** | TRUE | FALSE | UNKNOWN |
| **FALSE** | FALSE | FALSE | FALSE |
| **UNKNOWN** | UNKNOWN | FALSE | UNKNOWN |

| `OR` | TRUE | FALSE | UNKNOWN |
|---|---|---|---|
| **TRUE** | TRUE | TRUE | TRUE |
| **FALSE** | TRUE | FALSE | UNKNOWN |
| **UNKNOWN** | TRUE | UNKNOWN | UNKNOWN |

| `A` | `NOT A` |
|---|---|
| TRUE | FALSE |
| FALSE | TRUE |
| UNKNOWN | UNKNOWN |

Two things worth noticing:

- `FALSE AND UNKNOWN` is `FALSE` — one solid `FALSE` is enough to decide
  the whole `AND`, even without knowing the other side.
- `TRUE OR UNKNOWN` is `TRUE` — one solid `TRUE` is enough to decide the
  whole `OR`, for the same reason. But `UNKNOWN` combined with anything
  less certain than that stays `UNKNOWN` — and `UNKNOWN` never makes it
  into the result.

### The classic pitfall: NOT and <> silently drop NULL rows

```sql
-- Looks like "every non-black product" — but isn't
SELECT Name, Color
FROM Product
WHERE Color <> 'Crna';
```

For a row where `Color IS NULL`, the comparison `Color <> 'Crna'`
evaluates to `UNKNOWN`, not `TRUE` — so that row is silently excluded,
even though "no color recorded" is certainly not "Crna".

To include those rows too, say so explicitly:

```sql
SELECT Name, Color
FROM Product
WHERE Color <> 'Crna'
   OR Color IS NULL;
```

> **Rule of thumb:** any time you write `<>`, `NOT`, or a negated `IN` /
> `LIKE` on a nullable column, ask yourself whether rows with `NULL`
> should be included — and if so, add `OR column IS NULL` explicitly.
> SQL Server will never add it for you.

### Check your understanding

1. Why does `WHERE SubcategoryID = NULL` return no rows, even if some products have no subcategory?
2. Which two operators correctly test for `NULL`?
3. What does `FALSE AND UNKNOWN` evaluate to?
4. Why does `WHERE Color <> 'Crna'` exclude products with no color recorded, instead of including them?

<details>
<summary>Show answers</summary>

1. Because `NULL` means "unknown", and comparing anything to an unknown
    value with `=` never evaluates to true.
2. `IS NULL` and `IS NOT NULL`.
3. `FALSE` — one definite `FALSE` is enough to decide an `AND`, regardless
    of the other side.
4. For those rows, `Color <> 'Crna'` evaluates to `UNKNOWN`, not `TRUE` —
    and `WHERE` only keeps rows where the condition is `TRUE`. `UNKNOWN`
    is excluded just like `FALSE` is.

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
