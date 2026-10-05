/*===========================================================================
  SQL & Relational Database Prerequisites — Exercises
  Database: AdventureWorksENG

  Work through each section after reading the matching numbered file in the
  parent folder. Try every exercise yourself before reading the solution
  that follows it.

  Exercises that insert, update, or delete rows include their own cleanup
  statements — run them so the database is left unchanged.
===========================================================================*/

USE AdventureWorksENG;
GO


/*===========================================================================
  SECTION 2 — SELECT Basics
  See: 02-select-basics.md
===========================================================================*/

-- Exercise 2.1
-- Select the Name and PriceWithoutVAT columns from Product,
-- aliasing PriceWithoutVAT as Price.

-- === Solution ===
SELECT
    Name,
    PriceWithoutVAT AS Price
FROM Product;
GO

-- Exercise 2.2
-- List every distinct Color used in Product.

-- === Solution ===
SELECT DISTINCT Color
FROM Product;
GO

-- Exercise 2.3
-- Return only the first 10 rows of Product, every column.

-- === Solution ===
SELECT TOP 10 *
FROM Product;
GO


/*===========================================================================
  SECTION 3 — Filtering and Sorting
  See: 03-filtering-and-sorting.md
===========================================================================*/

-- Exercise 3.1
-- Find all products priced strictly above 100.

-- === Solution ===
SELECT Name, PriceWithoutVAT
FROM Product
WHERE PriceWithoutVAT > 100;
GO

-- Exercise 3.2
-- Find all products that are Crna or Crvena AND cost less than 50.

-- === Solution ===
SELECT Name, Color, PriceWithoutVAT
FROM Product
WHERE (Color = 'Crna' OR Color = 'Crvena')
  AND PriceWithoutVAT < 50;
GO

-- Exercise 3.3
-- Rewrite Exercise 3.2's color condition using IN instead of OR.

-- === Solution ===
SELECT Name, Color, PriceWithoutVAT
FROM Product
WHERE Color IN ('Crna', 'Crvena')
  AND PriceWithoutVAT < 50;
GO

-- Exercise 3.4
-- Find all products whose name contains the word "Bike" (any position).

-- === Solution ===
SELECT Name
FROM Product
WHERE Name LIKE '%Bike%';
GO

-- Exercise 3.5
-- Find all products that have no assigned subcategory.

-- === Solution ===
SELECT Name
FROM Product
WHERE SubcategoryID IS NULL;
GO

-- Exercise 3.6
-- List the 5 cheapest products, cheapest first.

-- === Solution ===
SELECT TOP 5 Name, PriceWithoutVAT
FROM Product
ORDER BY PriceWithoutVAT ASC;
GO


/*===========================================================================
  SECTION 4 — Joins
  See: 04-joins.md
===========================================================================*/

-- Exercise 4.1
-- List each invoice's IDInvoice and InvoiceDate together with the
-- customer's FirstName and LastName. Only include invoices with a
-- valid customer (there always is one, but write it as an INNER JOIN).

-- === Solution ===
SELECT
    i.IDInvoice,
    i.InvoiceDate,
    c.FirstName,
    c.LastName
FROM Invoice AS i
INNER JOIN Customer AS c
    ON i.CustomerID = c.IDCustomer;
GO

-- Exercise 4.2
-- List every invoice with the salesman's FirstName and LastName if one is
-- recorded, keeping invoices that have no salesman on record.

-- === Solution ===
SELECT
    i.IDInvoice,
    s.FirstName,
    s.LastName
FROM Invoice AS i
LEFT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman;
GO

-- Exercise 4.3
-- Find every invoice that has NO salesman on record.

-- === Solution ===
SELECT i.IDInvoice
FROM Invoice AS i
LEFT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
WHERE s.IDSalesman IS NULL;
GO

-- Exercise 4.4
-- List each invoice line: customer last name, product name, quantity,
-- and the line's TotalPrice.

-- === Solution ===
SELECT
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
GO

-- Exercise 4.5
-- List every salesman together with any invoice they're linked to,
-- keeping salesmen who have never been assigned an invoice. Use RIGHT JOIN.

-- === Solution ===
SELECT
    s.IDSalesman,
    s.FirstName,
    s.LastName,
    i.IDInvoice
FROM Invoice AS i
RIGHT JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
ORDER BY s.IDSalesman;
GO

-- Exercise 4.6
-- Using Invoice and Salesman, find rows on either side with no match:
-- invoices with no salesman on record, and salesmen with no invoices.
-- Use FULL OUTER JOIN.

-- === Solution ===
SELECT
    i.IDInvoice,
    s.IDSalesman,
    s.LastName
FROM Invoice AS i
FULL OUTER JOIN Salesman AS s
    ON i.SalesmanID = s.IDSalesman
WHERE i.IDInvoice IS NULL
   OR s.IDSalesman IS NULL;
GO

-- Exercise 4.7
-- Produce every combination of Category and State (a CROSS JOIN).
-- How many rows do you expect before running it?

-- === Solution ===
SELECT
    cat.Name AS CategoryName,
    s.Name   AS StateName
FROM Category AS cat
CROSS JOIN State AS s;
GO


/*===========================================================================
  SECTION 5 — Aggregate Functions
  See: 05-aggregate-functions.md
===========================================================================*/

-- Exercise 5.1
-- Count how many products exist in total, and separately how many have
-- a non-NULL SubcategoryID.

-- === Solution ===
SELECT
    COUNT(*) AS TotalProducts,
    COUNT(SubcategoryID) AS ProductsWithSubcategory
FROM Product;
GO

-- Exercise 5.2
-- For each Color, show how many products have that color, and the
-- average price for that color.

-- === Solution ===
SELECT
    Color,
    COUNT(*) AS ProductCount,
    AVG(PriceWithoutVAT) AS AveragePrice
FROM Product
GROUP BY Color;
GO

-- Exercise 5.3
-- Same as 5.2, but only show colors with more than 5 products.

-- === Solution ===
SELECT
    Color,
    COUNT(*) AS ProductCount,
    AVG(PriceWithoutVAT) AS AveragePrice
FROM Product
GROUP BY Color
HAVING COUNT(*) > 5;
GO

-- Exercise 5.4
-- For each customer, show the total amount they have spent
-- (sum of TotalPrice across all their invoice items), highest first.

-- === Solution ===
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
GROUP BY c.IDCustomer, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;
GO

-- Exercise 5.5
-- For each category, show how many products it has, joining through
-- Subcategory. Order by product count, highest first.

-- === Solution ===
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
GO

-- Exercise 5.6
-- Find the 5 products sold in the highest total quantity
-- (SUM of InvoiceItem.Quantity), highest first.

-- === Solution ===
SELECT TOP 5
    p.Name,
    SUM(ii.Quantity) AS QuantitySold
FROM Product AS p
INNER JOIN InvoiceItem AS ii
    ON ii.ProductID = p.IDProduct
GROUP BY p.Name
ORDER BY QuantitySold DESC;
GO


/*===========================================================================
  SECTION 6 — Subqueries
  See: 06-subqueries.md
===========================================================================*/

-- Exercise 6.1
-- Find all products priced above the overall average product price.

-- === Solution ===
SELECT Name, PriceWithoutVAT
FROM Product
WHERE PriceWithoutVAT > (
    SELECT AVG(PriceWithoutVAT)
    FROM Product
);
GO

-- Exercise 6.2
-- Find all products that have never appeared in any InvoiceItem.

-- === Solution ===
SELECT Name
FROM Product
WHERE IDProduct NOT IN (
    SELECT ProductID
    FROM InvoiceItem
);
GO

-- Exercise 6.3
-- Find all customers who have placed at least one invoice, using EXISTS.

-- === Solution ===
SELECT FirstName, LastName
FROM Customer AS c
WHERE EXISTS (
    SELECT 1
    FROM Invoice AS i
    WHERE i.CustomerID = c.IDCustomer
);
GO

-- Exercise 6.4
-- Find all customers who have NEVER placed an invoice, using NOT EXISTS.

-- === Solution ===
SELECT FirstName, LastName
FROM Customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM Invoice AS i
    WHERE i.CustomerID = c.IDCustomer
);
GO

-- Exercise 6.5
-- Using a derived table, list only the colors that have more than
-- 10 products, together with their product count.

-- === Solution ===
SELECT
    ColorSummary.Color,
    ColorSummary.ProductCount
FROM (
    SELECT Color, COUNT(*) AS ProductCount
    FROM Product
    GROUP BY Color
) AS ColorSummary
WHERE ColorSummary.ProductCount > 10;
GO

-- Exercise 6.6
-- For each customer, show their name and a correlated subquery count of
-- how many invoices they have, highest first.

-- === Solution ===
SELECT
    c.FirstName,
    c.LastName,
    (
        SELECT COUNT(*)
        FROM Invoice AS i
        WHERE i.CustomerID = c.IDCustomer
    ) AS InvoiceCount
FROM Customer AS c
ORDER BY InvoiceCount DESC;
GO

-- Exercise 6.7
-- Find products whose total quantity sold (SUM of InvoiceItem.Quantity)
-- is above the average total quantity sold across all products that have
-- been sold at least once.

-- === Solution ===
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
GO


/*===========================================================================
  SECTION 7 — INSERT, UPDATE, DELETE
  See: 07-insert-update-delete.md

  Every exercise in this section cleans up after itself. Run the cleanup
  statement even if your own attempt looked different, so the database is
  left unchanged for the next exercise.
===========================================================================*/

-- Exercise 7.1
-- Insert a new State named 'Narnia', then select it back to confirm
-- it was inserted, then clean it up.

-- === Solution ===
INSERT INTO State (Name)
VALUES ('Narnia');

SELECT *
FROM State
WHERE Name = 'Narnia';

-- Cleanup
DELETE FROM State
WHERE Name = 'Narnia';
GO

-- Exercise 7.2
-- Insert three states at once: 'Narnia', 'Wakanda', 'Atlantis'.
-- Select them back, then clean them up.

-- === Solution ===
INSERT INTO State (Name)
VALUES
    ('Narnia'),
    ('Wakanda'),
    ('Atlantis');

SELECT *
FROM State
WHERE Name IN ('Narnia', 'Wakanda', 'Atlantis');

-- Cleanup
DELETE FROM State
WHERE Name IN ('Narnia', 'Wakanda', 'Atlantis');
GO

-- Exercise 7.3
-- Insert a State named 'Narnia', then UPDATE its name to 'New Narnia'.
-- Select it back to confirm the rename, then clean it up.

-- === Solution ===
INSERT INTO State (Name)
VALUES ('Narnia');

UPDATE State
SET Name = 'New Narnia'
WHERE Name = 'Narnia';

SELECT *
FROM State
WHERE Name = 'New Narnia';

-- Cleanup
DELETE FROM State
WHERE Name = 'New Narnia';
GO

-- Exercise 7.4
-- Before writing any UPDATE or DELETE, it's good practice to run the
-- matching SELECT first. Insert a State named 'Narnia', then write
-- (but do not run as an UPDATE yet) the SELECT you would use to preview
-- which row an UPDATE WHERE Name = 'Narnia' would affect. Run the
-- SELECT, confirm it matches exactly one row, then clean up.

-- === Solution ===
INSERT INTO State (Name)
VALUES ('Narnia');

-- Preview before the real UPDATE
SELECT *
FROM State
WHERE Name = 'Narnia';

-- Cleanup
DELETE FROM State
WHERE Name = 'Narnia';
GO

-- Exercise 7.5
-- Practice a risky-looking UPDATE safely. Inside a transaction, insert a
-- State named 'Narnia', double-check it with SELECT, then UPDATE its name
-- to 'Narnia Renamed' and SELECT again to see the change. Finish with a
-- ROLLBACK instead of a COMMIT, then SELECT once more to confirm nothing
-- was actually kept.

-- === Solution ===
BEGIN TRAN;

INSERT INTO State (Name)
VALUES ('Narnia');

SELECT * FROM State WHERE Name = 'Narnia';

UPDATE State
SET Name = 'Narnia Renamed'
WHERE Name = 'Narnia';

SELECT * FROM State WHERE Name = 'Narnia Renamed';

ROLLBACK;

-- Confirms the ROLLBACK undid everything, including the INSERT
SELECT * FROM State WHERE Name IN ('Narnia', 'Narnia Renamed');
GO


/*===========================================================================
  SECTION 8 — Database Integrity and Constraints
  See: 08-database-integrity-and-constraints.md

  These exercises build their OWN standalone tables (Teacher, Student,
  Subject, Exam) instead of using AdventureWorksENG. Each exercise cleans
  up by dropping the tables it created.
===========================================================================*/

-- Exercise 8.1
-- Create a Teacher table with:
--   TeacherID  (primary key, auto-generated starting at 1, step 1)
--   NationalID (fixed-length 11 characters, required, must be unique)
--   LastName   (variable-length text up to 40 characters, required)
--   Active     (bit, required, defaults to 1)
-- Insert one teacher without specifying TeacherID or Active, then
-- confirm Active defaulted to 1. Clean up by dropping the table.

-- === Solution ===
CREATE TABLE Teacher (
    TeacherID  INT IDENTITY(1, 1) PRIMARY KEY,
    NationalID CHAR(11) NOT NULL UNIQUE,
    LastName   NVARCHAR(40) NOT NULL,
    Active     BIT NOT NULL DEFAULT 1
);

INSERT INTO Teacher (NationalID, LastName)
VALUES ('06382780091', N'Euler');

SELECT * FROM Teacher;

-- Cleanup
DROP TABLE Teacher;
GO

-- Exercise 8.2
-- Re-create the same Teacher table. Try to insert two teachers with the
-- same NationalID. Confirm the second insert fails, then confirm a
-- single successful insert is still in the table. Clean up.

-- === Solution ===
CREATE TABLE Teacher (
    TeacherID  INT IDENTITY(1, 1) PRIMARY KEY,
    NationalID CHAR(11) NOT NULL UNIQUE,
    LastName   NVARCHAR(40) NOT NULL,
    Active     BIT NOT NULL DEFAULT 1
);

INSERT INTO Teacher (NationalID, LastName)
VALUES ('06382780091', N'Euler');

-- Fails: duplicate NationalID
INSERT INTO Teacher (NationalID, LastName)
VALUES ('06382780091', N'Lagrange');

SELECT * FROM Teacher;

-- Cleanup
DROP TABLE Teacher;
GO

-- Exercise 8.3
-- Create a Subject table (SubjectID int primary key, SubjectName
-- nvarchar(20)) and an Exam table with a composite primary key on
-- (SubjectID, ExamDate), plus a Grade column restricted with CHECK to
-- the range 1-5. Insert one valid exam row, then try to insert a row
-- with Grade = 7 and confirm it is rejected. Clean up both tables.

-- === Solution ===
CREATE TABLE Subject (
    SubjectID   INT PRIMARY KEY,
    SubjectName NVARCHAR(20)
);

CREATE TABLE Exam (
    SubjectID INT,
    ExamDate  DATE,
    Grade     TINYINT NOT NULL CHECK (Grade BETWEEN 1 AND 5),
    CONSTRAINT PK_Exam PRIMARY KEY (SubjectID, ExamDate)
);

INSERT INTO Subject VALUES (1001, N'Math-1');

INSERT INTO Exam (SubjectID, ExamDate, Grade)
VALUES (1001, '2026-01-15', 4);

-- Fails: CHECK constraint
INSERT INTO Exam (SubjectID, ExamDate, Grade)
VALUES (1001, '2026-01-20', 7);

SELECT * FROM Exam;

-- Cleanup
DROP TABLE Exam;
DROP TABLE Subject;
GO

-- Exercise 8.4
-- Create Student (StudentID char(10) primary key, LastName nvarchar(20))
-- and Exam (ExamID identity primary key, StudentID char(10) not null,
-- Grade tinyint not null) with a FOREIGN KEY from Exam.StudentID to
-- Student.StudentID. Insert one student and one matching exam, then try
-- to insert an exam for a StudentID that does not exist in Student and
-- confirm it is rejected. Clean up both tables.

-- === Solution ===
CREATE TABLE Student (
    StudentID CHAR(10) PRIMARY KEY,
    LastName  NVARCHAR(20)
);

CREATE TABLE Exam (
    ExamID    INT IDENTITY(1, 1) PRIMARY KEY,
    StudentID CHAR(10) NOT NULL,
    Grade     TINYINT NOT NULL,
    CONSTRAINT FK_Exam_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID)
);

INSERT INTO Student VALUES ('0555004388', N'Smith');

INSERT INTO Exam (StudentID, Grade)
VALUES ('0555004388', 4);

-- Fails: FOREIGN KEY constraint, no such StudentID in Student
INSERT INTO Exam (StudentID, Grade)
VALUES ('9999999999', 4);

SELECT * FROM Exam;

-- Cleanup
DROP TABLE Exam;
DROP TABLE Student;
GO

-- Exercise 8.5
-- Using the same two tables as 8.4, this time define the foreign key
-- with ON DELETE CASCADE. Insert one student with two exams, delete the
-- student, and confirm both exams were removed automatically. Clean up.

-- === Solution ===
CREATE TABLE Student (
    StudentID CHAR(10) PRIMARY KEY,
    LastName  NVARCHAR(20)
);

CREATE TABLE Exam (
    ExamID    INT IDENTITY(1, 1) PRIMARY KEY,
    StudentID CHAR(10) NOT NULL,
    Grade     TINYINT NOT NULL,
    CONSTRAINT FK_Exam_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE
);

INSERT INTO Student VALUES ('0555004388', N'Smith');

INSERT INTO Exam (StudentID, Grade) VALUES
('0555004388', 4),
('0555004388', 3);

DELETE FROM Student WHERE StudentID = '0555004388';

-- Both exam rows are gone too
SELECT * FROM Exam;

-- Cleanup
DROP TABLE Exam;
DROP TABLE Student;
GO


/*===========================================================================
  SECTION 9 — Built-in Functions
  See: 09-built-in-functions.md
===========================================================================*/

-- Exercise 9.1
-- Show each product's name, its price without VAT, and that price
-- rounded to the nearest whole number.

-- === Solution ===
SELECT
    Name,
    PriceWithoutVAT,
    ROUND(PriceWithoutVAT, 0) AS RoundedPrice
FROM Product;
GO

-- Exercise 9.2
-- Show each product's name in uppercase and its length (number of characters).

-- === Solution ===
SELECT
    Name,
    UPPER(Name) AS NameUpper,
    LEN(Name) AS NameLength
FROM Product;
GO

-- Exercise 9.3
-- For each customer with an email address, show the part of the email
-- before the @ sign (their username).

-- === Solution ===
SELECT
    Email,
    SUBSTRING(Email, 1, CHARINDEX('@', Email) - 1) AS Username
FROM Customer
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) > 0;
GO

-- Exercise 9.4
-- Show every invoice's number, its date, and the year, month, and day
-- extracted separately.

-- === Solution ===
SELECT
    InvoiceNumber,
    InvoiceDate,
    YEAR(InvoiceDate)  AS InvoiceYear,
    MONTH(InvoiceDate) AS InvoiceMonth,
    DAY(InvoiceDate)   AS InvoiceDay
FROM Invoice;
GO

-- Exercise 9.5
-- Show every invoice's number and how many days have passed between its
-- InvoiceDate and today.

-- === Solution ===
SELECT
    InvoiceNumber,
    InvoiceDate,
    DATEDIFF(day, InvoiceDate, GETDATE()) AS DaysSinceInvoice
FROM Invoice;
GO

-- Exercise 9.6
-- Show each product's name and color, replacing a missing color with the
-- text 'NOT SPECIFIED'. Solve it once with ISNULL and once with COALESCE.

-- === Solution ===
SELECT
    Name,
    ISNULL(Color, 'NOT SPECIFIED') AS WithIsNull,
    COALESCE(Color, 'NOT SPECIFIED') AS WithCoalesce
FROM Product;
GO

-- Exercise 9.7
-- Find all products whose color, compared case-insensitively in uppercase,
-- equals 'CRNA'.

-- === Solution ===
SELECT Name, Color
FROM Product
WHERE UPPER(Color) = 'CRNA';
GO

-- Exercise 9.8
-- Find all invoices issued in the year 2003.

-- === Solution ===
SELECT InvoiceNumber, InvoiceDate
FROM Invoice
WHERE YEAR(InvoiceDate) = 2003;
GO

