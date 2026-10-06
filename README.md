# SQL & Relational Database Prerequisites

This is catch-up material for students who have **not** taken an introductory
course on relational databases.

It covers the minimum you need before you can comfortably work with SQL:
what a relational database is, how to read and write basic queries, and how
to modify data safely.

> Each file contains explanations, SQL examples, short "Check your
> understanding" questions, and a pointer to hands-on exercises.

---

## Requirements

You will need:

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- the `AdventureWorksENG` database

Make sure you can connect to SQL Server and run a query against
`AdventureWorksENG` before starting.

---

## Contents

| # | Topic | What you will learn |
|---|---|---|
| 01 | [Relational Database Basics](01-relational-database-basics.md) | tables, rows, columns, primary keys, foreign keys, relationships |
| 02 | [SELECT Basics](02-select-basics.md) | `SELECT`, `FROM`, column aliases, `DISTINCT`, `TOP` |
| 03 | [Filtering and Sorting](03-filtering-and-sorting.md) | `WHERE`, comparison operators, `AND`/`OR`, `IN`, `BETWEEN`, `LIKE`, `NULL`, `ORDER BY` |
| 04 | [Joins](04-joins.md) | `INNER JOIN`, `LEFT JOIN`, joining more than two tables |
| 05 | [Aggregate Functions](05-aggregate-functions.md) | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING` |
| 06 | [Subqueries](06-subqueries.md) | scalar subqueries, `IN`, `EXISTS`, subqueries in `FROM` |
| 07 | [INSERT, UPDATE, DELETE](07-insert-update-delete.md) | adding, changing, and removing rows safely |
| 08 | [Creating Tables and Enforcing Integrity](08-creating-tables-and-enforcing-integrity.md) | `NOT NULL`, `DEFAULT`, `PRIMARY KEY`, `UNIQUE`, `CHECK`, `FOREIGN KEY`, composite/surrogate keys, `ALTER TABLE` |
| 09 | [Built-in Functions](09-built-in-functions.md) | math, string, date, conversion, and `NULL`-handling functions, used in `SELECT` and `WHERE` |

---

## How to use this material

For each file, in order:

1. read the explanation;
2. run the SQL examples yourself in SSMS;
3. answer the **Check your understanding** questions;
4. open [`sql/exercises.sql`](sql/exercises.sql), find the matching section, and complete the exercises before reading the solution.

Work through the files in order — each one assumes you are comfortable with
everything before it.

---

## About the database

The examples use `AdventureWorksENG`, a small sample retailer database: it
stores products, customers, and the invoices generated when a customer buys
something. Its schema is introduced in
[01 - Relational Database Basics](01-relational-database-basics.md).

Some exercises in `sql/exercises.sql` insert, update, or delete rows. Each
of those exercises includes its own cleanup statements so the database is
left unchanged once you are done.

The exception is [08 - Creating Tables and Enforcing Integrity](08-creating-tables-and-enforcing-integrity.md),
which creates its own standalone example tables (`Teacher`, `Student`,
`Subject`, `Exam`) instead of using `AdventureWorksENG`.

---

## Repository structure

```text
database-sql-prerequisites/
│
├── README.md
│
├── 01-relational-database-basics.md
├── 02-select-basics.md
├── 03-filtering-and-sorting.md
├── 04-joins.md
├── 05-aggregate-functions.md
├── 06-subqueries.md
├── 07-insert-update-delete.md
├── 08-creating-tables-and-enforcing-integrity.md
├── 09-built-in-functions.md
│
└── sql/
    └── exercises.sql
```
