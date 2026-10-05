# 09 – Built-in Functions

**Database:** `AdventureWorksENG`

SQL Server ships with a large library of ready-made functions. This file
covers the ones you'll reach for constantly: math, text, dates, type
conversion, and `NULL` handling.

## Learning objectives

After this file, you should be able to:

- use common math functions: `ROUND`, `FLOOR`, `CEILING`, `ABS`, `SQUARE`, `SQRT`, `POWER`, `SIGN`;
- use common string functions: `LEN`, `UPPER`, `LOWER`, `LEFT`, `RIGHT`, `SUBSTRING`, `CHARINDEX`, `TRIM`, `REVERSE`, `REPLACE`;
- use common date functions: `GETDATE`, `DATEPART`, `YEAR`/`MONTH`/`DAY`, `DATEADD`, `DATEDIFF`;
- convert between data types with `CAST` and `CONVERT`, and validate values with `ISDATE`/`ISNUMERIC`/`TRY_CONVERT`/`TRY_CAST`;
- handle `NULL` values with `ISNULL` and `COALESCE`;
- use any of the above inside `WHERE`, not just `SELECT`.

------------------------------------------------------------------------

## Section 1 – Functions in a SELECT statement

A **scalar function** takes some input and returns a single value for
each row it's applied to.

```sql
SELECT
    Name,
    PriceWithoutVAT,
    ROUND(PriceWithoutVAT, 1) AS RoundedPrice
FROM Product
WHERE PriceWithoutVAT > 0;
```

Functions most often appear in `SELECT`, but they also work in `WHERE`,
`ORDER BY`, and nested inside other functions — you'll see all of these
below.

------------------------------------------------------------------------

## Section 2 – Math functions

### ROUND

`ROUND(expression, length)` rounds a number to a given number of decimal
places.

```sql
SELECT
    Name,
    PriceWithoutVAT,
    ROUND(PriceWithoutVAT, 1) AS RoundedToOneDecimal,
    ROUND(PriceWithoutVAT, 0) AS RoundedToWhole
FROM Product
WHERE PriceWithoutVAT > 0;
```

### FLOOR and CEILING

`FLOOR` returns the largest integer less than or equal to the value.
`CEILING` returns the smallest integer greater than or equal to it.

```sql
SELECT
    IDInvoiceItem,
    InitialPrice,
    FLOOR(InitialPrice)   AS RoundedDown,
    CEILING(InitialPrice) AS RoundedUp
FROM InvoiceItem;
```

### ABS, SQUARE, SQRT, POWER, SIGN

```sql
SELECT ABS(-91) AS AbsoluteValue;

SELECT
    IDInvoiceItem,
    SQUARE(IDInvoiceItem) AS Squared,
    SQRT(IDInvoiceItem)   AS SquareRoot
FROM InvoiceItem;

SELECT POWER(2, 10) AS TwoToThePowerOfTen;

SELECT
    SIGN(-10) AS NegativeNumber,
    SIGN(0)   AS Zero,
    SIGN(10)  AS PositiveNumber;
```

`SIGN` returns `-1` for a negative number, `0` for zero, and `1` for a
positive number.

### RAND

`RAND()` returns a random decimal between 0 and 1. Combine it with
`FLOOR` to get a random whole number in a range:

```sql
SELECT RAND() AS RandomBetweenZeroAndOne;

SELECT FLOOR(RAND() * 100) + 1 AS RandomIntegerFrom1To100;
```

### Check your understanding

1. What's the difference between `FLOOR(42.8)` and `CEILING(42.8)`?
2. What does `SIGN(0)` return?

<details>
<summary>Show answers</summary>

1. `FLOOR(42.8)` returns `42`; `CEILING(42.8)` returns `43`.
2. `0`.

</details>

------------------------------------------------------------------------

## Section 3 – String functions

### LEN

```sql
SELECT
    Name,
    LEN(Name) AS NameLength
FROM Product;
```

### UPPER and LOWER

```sql
SELECT
    Name,
    UPPER(Name) AS NameUpper,
    LOWER(Name) AS NameLower
FROM Product;
```

### LEFT and RIGHT

```sql
SELECT
    Name,
    LEFT(Name, 5)  AS FirstFiveChars,
    RIGHT(Name, 5) AS LastFiveChars
FROM Product;
```

### SUBSTRING

`SUBSTRING(string, start, length)` extracts part of a string starting at
a given position.

```sql
SELECT
    Name,
    SUBSTRING(Name, 1, 5)  AS FirstFiveChars,
    SUBSTRING(Name, 7, 10) AS MiddlePart
FROM Product;
```

### CHARINDEX

`CHARINDEX` searches for one string inside another and returns the
position where it was found — `0` if it wasn't found at all.

```sql
SELECT
    Email,
    CHARINDEX('@', Email) AS AtPosition
FROM Customer;
```

### Combining SUBSTRING and CHARINDEX

A common, practical pattern: extract the part of an email address before
the `@`.

```sql
SELECT
    Email,
    SUBSTRING(Email, 1, CHARINDEX('@', Email) - 1) AS Username
FROM Customer
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) > 0;
```

> **Why check `CHARINDEX(...) > 0` first?** If `@` isn't found,
> `CHARINDEX` returns `0`, and `SUBSTRING(Email, 1, -1)` would be asked
> for a negative length — an error. The guard keeps the expression safe.

### TRIM, LTRIM, RTRIM

`LTRIM` removes leading spaces, `RTRIM` removes trailing spaces, and
`TRIM` removes both at once.

```sql
SELECT
    '[' + LTRIM('   SQL Server   ') + ']' AS LTrimExample,
    '[' + RTRIM('   SQL Server   ') + ']' AS RTrimExample,
    '[' + TRIM('   SQL Server   ') + ']'  AS TrimExample;
```

The older pattern `LTRIM(RTRIM(text))` does the same thing as `TRIM(text)`
— prefer `TRIM`, it's clearer.

### REVERSE and REPLACE

```sql
SELECT
    Name,
    REVERSE(Name) AS ReversedName
FROM Product;

SELECT
    Name,
    REPLACE(Name, '-', ' ') AS NameWithoutDash
FROM Product
WHERE Name LIKE '%-%';
```

### Concatenating strings with +

```sql
SELECT
    FirstName + ' ' + LastName AS FullName
FROM Customer;
```

> **Careful:** if any part of a `+` expression is `NULL`, the whole
> result becomes `NULL` (see [03 – Filtering and Sorting](03-filtering-and-sorting.md#section-5--null)
> for why). `ISNULL`/`COALESCE`, covered later in this file, fix that.

### Check your understanding

1. What does `CHARINDEX` return when the search string isn't found?
2. Why guard a `SUBSTRING(..., CHARINDEX(...) - 1)` expression with `CHARINDEX(...) > 0`?
3. What happens to `FirstName + ' ' + LastName` if `LastName` is `NULL`?

<details>
<summary>Show answers</summary>

1. `0`.
2. Because if `CHARINDEX` returns `0` (not found), the length argument
    becomes `-1`, which `SUBSTRING` rejects with an error.
3. The entire expression evaluates to `NULL`.

</details>

------------------------------------------------------------------------

## Section 4 – Date and time functions

### GETDATE

```sql
SELECT GETDATE() AS RightNow;
```

### DATEPART, and the shorter YEAR/MONTH/DAY

`DATEPART` extracts a specific piece of a date — `year`, `quarter`,
`month`, `day`, `week`, `weekday`, `hour`, `minute`, `second`.

```sql
SELECT
    InvoiceNumber,
    InvoiceDate,
    DATEPART(year, InvoiceDate)  AS InvoiceYear,
    DATEPART(month, InvoiceDate) AS InvoiceMonth,
    DATEPART(day, InvoiceDate)   AS InvoiceDay
FROM Invoice;
```

`YEAR()`, `MONTH()`, and `DAY()` are shorthand for the three most common
cases:

```sql
SELECT
    InvoiceNumber,
    InvoiceDate,
    YEAR(InvoiceDate)  AS InvoiceYear,
    MONTH(InvoiceDate) AS InvoiceMonth,
    DAY(InvoiceDate)   AS InvoiceDay
FROM Invoice;
```

### DATEADD

`DATEADD(unit, amount, date)` adds (or, with a negative amount, subtracts)
an interval from a date.

```sql
SELECT
    InvoiceNumber,
    InvoiceDate,
    DATEADD(day, 30, InvoiceDate)   AS ThirtyDaysLater,
    DATEADD(month, 1, InvoiceDate)  AS OneMonthLater
FROM Invoice;
```

### DATEDIFF

`DATEDIFF(unit, startDate, endDate)` counts how many unit boundaries were
crossed between two dates.

```sql
SELECT
    InvoiceNumber,
    InvoiceDate,
    DATEDIFF(day, InvoiceDate, GETDATE())   AS DaysSinceInvoice,
    DATEDIFF(month, InvoiceDate, GETDATE()) AS MonthsSinceInvoice
FROM Invoice;
```

> **Careful:** `DATEDIFF(year, d1, d2)` doesn't mean "full years elapsed"
> — it counts how many January 1sts fall between the two dates. `DATEDIFF(year, '2025-12-31', '2026-01-01')`
> returns `1`, even though only one day passed.

### Check your understanding

1. What does `DATEPART(month, InvoiceDate)` return?
2. Does `DATEDIFF(year, '2025-12-31', '2026-01-01')` return a full year?

<details>
<summary>Show answers</summary>

1. The month number of `InvoiceDate` (1–12).
2. No — it returns `1`, because `DATEDIFF` counts how many year
    boundaries were crossed, not elapsed calendar time.

</details>

------------------------------------------------------------------------

## Section 5 – Converting and validating values

### CAST

```sql
SELECT
    Name,
    PriceWithoutVAT,
    CAST(PriceWithoutVAT AS INT)         AS AsInteger,
    CAST(PriceWithoutVAT AS VARCHAR(20)) AS AsText
FROM Product
WHERE PriceWithoutVAT > 0;
```

### CONVERT

`CONVERT(type, expression, style)` behaves like `CAST`, but accepts an
extra style code — most useful for formatting dates as text.

```sql
SELECT
    InvoiceNumber,
    InvoiceDate,
    CONVERT(VARCHAR(10), InvoiceDate, 104) AS DateDDMMYYYY,
    CONVERT(VARCHAR(10), InvoiceDate, 120) AS DateISO
FROM Invoice;
```

Common date styles: `103` = `dd/mm/yyyy`, `104` = `dd.mm.yyyy`,
`120` = `yyyy-mm-dd hh:mi:ss`.

### ISDATE and ISNUMERIC

```sql
SELECT
    ISDATE('today')      AS IsTodayADate,
    ISDATE('2011-08-15') AS IsIsoDateValid;

SELECT
    ISNUMERIC('abcd')  AS IsAbcdNumeric,
    ISNUMERIC('67.55') AS IsDotNumeric,
    ISNUMERIC('67,55') AS IsCommaNumeric;
```

> **Caution:** `ISDATE` can depend on SQL Server's regional settings, and
> `ISNUMERIC` accepts things that aren't valid numbers for most purposes
> (like a lone `+` sign). For real validation, prefer `TRY_CONVERT` /
> `TRY_CAST` with an explicit style.

### TRY_CONVERT and TRY_CAST

These behave like `CONVERT`/`CAST`, but return `NULL` instead of raising
an error when the conversion fails — safe to use directly on
unpredictable input.

```sql
SELECT TRY_CONVERT(DATE, '15.08.2011', 104) AS SafeDateConversion;

SELECT
    TRY_CAST('67.55' AS DECIMAL(10, 2)) AS ValidConversion,
    TRY_CAST('abcd' AS DECIMAL(10, 2))  AS InvalidConversion;
```

### Check your understanding

1. What does `CONVERT` do that `CAST` cannot?
2. What does `TRY_CAST` return when the conversion is invalid, instead of raising an error?

<details>
<summary>Show answers</summary>

1. `CONVERT` accepts an optional style code, useful for formatting dates
    as text in a specific layout. `CAST` has no style parameter.
2. `NULL`.

</details>

------------------------------------------------------------------------

## Section 6 – Handling NULL: ISNULL and COALESCE

### ISNULL

`ISNULL(expression, replacement)` returns `expression` if it isn't
`NULL`, and `replacement` otherwise.

```sql
SELECT
    Name,
    Color,
    ISNULL(Color, 'NOT SPECIFIED') AS ColorToDisplay
FROM Product;
```

### COALESCE

`ISNULL` is SQL Server–specific. `COALESCE` does the same job and is
supported across most database systems — and it accepts more than two
arguments, returning the first one that isn't `NULL`.

```sql
SELECT
    Name,
    ISNULL(Color, 'NOT SPECIFIED')   AS WithIsNull,
    COALESCE(Color, 'NOT SPECIFIED') AS WithCoalesce
FROM Product;
```

```sql
-- COALESCE can chain several fallbacks
SELECT
    i.InvoiceNumber,
    COALESCE(sm.FirstName + ' ' + sm.LastName, 'NO SALESMAN ON RECORD') AS Salesman
FROM Invoice AS i
LEFT JOIN Salesman AS sm
    ON sm.IDSalesman = i.SalesmanID;
```

### Check your understanding

1. Why might you prefer `COALESCE` over `ISNULL` in code meant to be portable across database systems?
2. What does `COALESCE(a, b, c)` return if `a` is `NULL` but `b` is not?

<details>
<summary>Show answers</summary>

1. `ISNULL` is SQL Server-specific, while `COALESCE` is part of the SQL
    standard and works the same way on other systems.
2. `b`.

</details>

------------------------------------------------------------------------

## Section 7 – Functions in WHERE

Everything above also works inside `WHERE` — functions aren't limited to
`SELECT`.

```sql
-- String functions in WHERE
SELECT Name
FROM Product
WHERE UPPER(Color) = 'CRNA';

SELECT Name
FROM Product
WHERE CHARINDEX('Road', Name) > 0;

-- Date functions in WHERE
SELECT InvoiceNumber, InvoiceDate
FROM Invoice
WHERE YEAR(InvoiceDate) = 2003;

-- ISNULL / COALESCE in WHERE
SELECT Name, Color
FROM Product
WHERE ISNULL(Color, 'NONE') = 'NONE';

-- CAST in WHERE
SELECT Name, PriceWithoutVAT
FROM Product
WHERE CAST(PriceWithoutVAT AS INT) > 1000;
```

> **Going further — SARGability:** wrapping an indexed column in a
> function (like `YEAR(InvoiceDate) = 2003` or `UPPER(Color) = 'CRNA'`)
> can stop SQL Server from using an index on that column efficiently,
> because it has to compute the function for every row before it can
> compare. A query that *can* use an index directly is called
> **SARGable** (from "Search ARGument"). This becomes relevant once your
> tables are large and you start caring about query performance — for
> now, just know the term exists.

### Check your understanding

1. Can a function like `YEAR()` be used in `WHERE`, not just `SELECT`?

<details>
<summary>Show answer</summary>

Yes — functions work the same way wherever an expression is allowed,
including `WHERE`, `ORDER BY`, and inside other functions.

</details>

------------------------------------------------------------------------

## Section 8 – A tour of the schema using functions

These combine several functions at once with joins from
[04 – Joins](04-joins.md) — a good way to see them used together the way
you actually would in practice.

```sql
-- Customer, email username, city, and state
SELECT
    c.IDCustomer,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    SUBSTRING(c.Email, 1, CHARINDEX('@', c.Email) - 1) AS Username,
    ci.Name AS City,
    s.Name  AS State
FROM Customer AS c
LEFT JOIN City AS ci
    ON ci.IDCity = c.CityID
LEFT JOIN State AS s
    ON s.IDState = ci.StateID
WHERE c.Email IS NOT NULL
  AND CHARINDEX('@', c.Email) > 0;

-- Product, subcategory, and category
SELECT
    p.IDProduct,
    UPPER(p.Name) AS ProductName,
    COALESCE(p.Color, 'NOT SPECIFIED') AS Color,
    ROUND(p.PriceWithoutVAT, 2) AS Price,
    sc.Name AS Subcategory,
    cat.Name AS Category
FROM Product AS p
LEFT JOIN Subcategory AS sc
    ON sc.IDSubcategory = p.SubcategoryID
LEFT JOIN Category AS cat
    ON cat.IDCategory = sc.CategoryID;

-- Invoice, customer, salesman, and credit card
SELECT
    i.InvoiceNumber,
    CONVERT(VARCHAR(10), i.InvoiceDate, 104) AS InvoiceDate,
    c.FirstName + ' ' + c.LastName AS Customer,
    COALESCE(sm.FirstName + ' ' + sm.LastName, 'NO SALESMAN ON RECORD') AS Salesman,
    COALESCE(cc.Type, 'NOT PAID BY CARD') AS CardType,
    COALESCE(i.Comment, 'NO COMMENT') AS Comment
FROM Invoice AS i
INNER JOIN Customer AS c
    ON c.IDCustomer = i.CustomerID
LEFT JOIN Salesman AS sm
    ON sm.IDSalesman = i.SalesmanID
LEFT JOIN CreditCard AS cc
    ON cc.IDCreditCard = i.CreditCardID;
```

------------------------------------------------------------------------

## Exercises

Open [`sql/exercises.sql`](sql/exercises.sql) and complete **Section 9 –
Built-in Functions**.

------------------------------------------------------------------------

## What you should know after this file

```sql
-- Math
ROUND(value, decimals)   FLOOR(value)   CEILING(value)   ABS(value)

-- Strings
LEN(text)   UPPER(text)   LOWER(text)   LEFT(text, n)   RIGHT(text, n)
SUBSTRING(text, start, length)   CHARINDEX(search, text)   TRIM(text)
REVERSE(text)   REPLACE(text, old, new)   text1 + text2

-- Dates
GETDATE()   YEAR(date)   MONTH(date)   DAY(date)
DATEADD(unit, amount, date)   DATEDIFF(unit, date1, date2)

-- Conversion
CAST(value AS type)   CONVERT(type, value, style)
TRY_CAST(value AS type)   TRY_CONVERT(type, value, style)

-- NULL handling
ISNULL(value, replacement)   COALESCE(value1, value2, ...)
```

A quick reminder of what's available even without internet access: in
SSMS, expand **Database → Programmability → Functions** in Object
Explorer to browse built-in functions, hover over a function name for a
short description, and expand an individual function to see its
parameters, their order, and their types.

This concludes the prerequisite material. You're now equipped with the
core building blocks — reading data, filtering, joining, aggregating,
subquerying, modifying data safely, enforcing integrity, and using
built-in functions — needed to work comfortably with a relational
database in SQL Server.
