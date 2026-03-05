
CREATE DATABASE XmlLabDB;
GO

USE XmlLabDB;
GO

CREATE TABLE Categories (
    CategoryID INT IDENTITY PRIMARY KEY,
    CategoryName NVARCHAR(50)
);
GO

CREATE TABLE Products (
    ProductID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50),
    Price DECIMAL(10,2),
    ImageData VARBINARY(MAX),
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID)
);
GO

INSERT INTO Categories (CategoryName)
VALUES
(N'Peripherals'),
(N'Accessories');
GO

INSERT INTO Products (Name, Price, ImageData, CategoryID)
VALUES
(N'Keyboard', 2500.00, CAST('ABC' AS VARBINARY(MAX)), 1),
(N'Mouse',    1200.00, CAST('DEF' AS VARBINARY(MAX)), 1),
(N'USB Cable', 500.00, CAST('GHI' AS VARBINARY(MAX)), 2);
GO


/* 2. FOR XML RAW
*/


SELECT
    c.CategoryName,
    p.ProductID,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML RAW('Row');
GO




/* 
3. FOR XML AUTO

*/

SELECT
    c.CategoryName,
    p.ProductID,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML AUTO;
GO


/* 4. FOR XML EXPLICIT

*/

SELECT
    1 AS Tag, /* Элемент первого уровня */
    NULL AS Parent, /* Родитель отсутсвует */
    c.CategoryName AS [Category!1!Name], /* Значение - Имя категории */
    NULL AS [Product!2!Name], /*  Пустые столбцы  для 2-го уровня */
    NULL AS [Product!2!Price]
FROM Categories c

UNION ALL

SELECT
    2 AS Tag, /* Элемент второго уровня */
    1 AS Parent, /* Родитель — элемент с Tag = 1 - Category */
    NULL, /* У Category в этой строке нет значения - NULL */
    p.Name, /* Атрибут Name у элемента Product (уровень 2) */
    p.Price /* Атрибут Price у элемента Product (уровень 2) */
FROM Products p
FOR XML EXPLICIT;
GO


/* 5. FOR XML PATH

 

 */



SELECT
    c.CategoryName AS '@name', 
    (
        SELECT
            p.ProductID AS '@id',
            p.Name AS 'Name',
            p.Price AS 'Price'
        FROM Products p
        WHERE p.CategoryID = c.CategoryID
        FOR XML PATH('Product'), TYPE
    )
FROM Categories c
FOR XML PATH('Category');
GO


/* 

6. ELEMENTS 
*/

SELECT
    c.CategoryName,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML PATH('Product'), ELEMENTS;
GO


/* 7. BINARY BASE64 */

SELECT
    p.ProductID,
    p.Name,
    p.ImageData
FROM Products p
FOR XML PATH('Product'), BINARY BASE64;
GO


/* 8. ROOT */


SELECT
    c.CategoryName,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML PATH('Product'), ROOT('Store'); 
GO


/* 9. TYPE */


SELECT
    c.CategoryName,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML PATH('Product'), TYPE; 
                                
GO


/* 10. XMLSCHEMA */


SELECT
    c.CategoryName,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML AUTO, XMLSCHEMA;
GO

/* 11. XMLDATA */

SELECT
    c.CategoryName,
    p.Name,
    p.Price
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
FOR XML AUTO, XMLDATA;
GO


/* 12. HTML */

SELECT c.CategoryName AS 'td', 
'', 
p.Name AS 'td',

'', 
p.Price AS 'td' 
FROM Categories c 
JOIN Products p 
ON p.CategoryID = c.CategoryID 
FOR XML PATH('tr'), ROOT('table'); 
GO





