USE master;
GO


-- 1: БД БЕЗ ИНДЕКСОВ

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'T-SQL_lab_4_no_index')
    DROP DATABASE [T-SQL_lab_4_no_index];
GO
CREATE DATABASE [T-SQL_lab_4_no_index];
GO
USE [T-SQL_lab_4_no_index];
GO

-- Создание таблиц
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100),
    City NVARCHAR(50)
);
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    Price DECIMAL(10,2)
);
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE
);
CREATE TABLE OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT
);

-- Заполнение данными
INSERT INTO Customers (Name, City)
SELECT TOP (1000000) 
    CONCAT('Customer_', ROW_NUMBER() OVER(ORDER BY (SELECT NULL))),
    CONCAT('City_', (ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 20000) + 1)
FROM sys.all_columns a CROSS JOIN sys.all_columns b;

INSERT INTO Products (ProductName, Category, Price)
SELECT TOP (500000)
    CONCAT('Product_', ROW_NUMBER() OVER(ORDER BY (SELECT NULL))),
    CONCAT('Category_', (ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 10000) + 1),
    ROUND(ABS(CHECKSUM(NEWID())) % 2000 + 10.5, 2)
FROM sys.all_columns a CROSS JOIN sys.all_columns b;

INSERT INTO Orders (CustomerID, OrderDate)
SELECT TOP (10000000)
    (ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 1000000) + 1,
    DATEADD(DAY, -(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 1095), GETDATE())
FROM sys.all_columns a CROSS JOIN sys.all_columns b CROSS JOIN (SELECT TOP 10 * FROM sys.objects) c;

INSERT INTO OrderItems (OrderID, ProductID, Quantity)
SELECT TOP (100000000)
    (ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 10000000) + 1,
    (ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 500000) + 1,
    (ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) % 100) + 1
FROM sys.all_columns a CROSS JOIN sys.all_columns b CROSS JOIN (SELECT TOP 100 * FROM sys.objects) c;
GO


-- 2: БД С ИНДЕКСАМИ

USE master;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'T-SQL_lab_4_indexed')
    DROP DATABASE [T-SQL_lab_4_indexed];
GO
CREATE DATABASE [T-SQL_lab_4_indexed];
GO
USE [T-SQL_lab_4_indexed];
GO

-- Копирование данных из первой базы
SELECT * INTO Customers FROM [T-SQL_lab_4_no_index].dbo.Customers;
SELECT * INTO Products FROM [T-SQL_lab_4_no_index].dbo.Products;
SELECT * INTO Orders FROM [T-SQL_lab_4_no_index].dbo.Orders;
SELECT * INTO OrderItems FROM [T-SQL_lab_4_no_index].dbo.OrderItems;
GO

ALTER TABLE Customers ADD CONSTRAINT PK_Cust PRIMARY KEY (CustomerID);
ALTER TABLE Products ADD CONSTRAINT PK_Prod PRIMARY KEY (ProductID);
ALTER TABLE Orders ADD CONSTRAINT PK_Ord PRIMARY KEY (OrderID);
ALTER TABLE OrderItems ADD CONSTRAINT PK_OrdItm PRIMARY KEY (OrderItemID);

CREATE INDEX idx_Orders_CustomerID_OrderID ON Orders(CustomerID, OrderDate);
CREATE INDEX idx_OrderItems_OrderID_ProductID ON OrderItems(OrderID, ProductID) INCLUDE (Quantity);
CREATE INDEX idx_OrderItems_ProductID ON OrderItems(ProductID) INCLUDE (Quantity);
CREATE INDEX idx_Customers_City ON Customers(City);
CREATE INDEX idx_Products_Category_Price ON Products(Category, Price);
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- 3: ТЕСТОВАЯ БД, СОЗДАНИЕ ТАБЛИЦ
USE master;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'T-SQL_lab_4_test')
    DROP DATABASE [T-SQL_lab_4_test];
GO
CREATE DATABASE [T-SQL_lab_4_test];
GO
USE [T-SQL_lab_4_test];
GO


-- КУЧА (HEAP) - без кластеризованного индекса
CREATE TABLE DemoHeap (
    ID INT IDENTITY(1,1),
    Name NVARCHAR(50),
    Value INT
);
INSERT INTO DemoHeap (Name, Value) VALUES 
    ('Heap Test 1', 100),
    ('Heap Test 2', 200),
    ('Heap Test 3', 300);


-- кластеризованный индекс
CREATE TABLE DemoClustered (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50)
);
INSERT INTO DemoClustered VALUES (1, 'Clustered 1'), (2, 'Clustered 2'), (3, 'Clustered 3');

-- Уникальный индекс
CREATE TABLE DemoUnique (
    Code VARCHAR(10),
    Description NVARCHAR(50)
);
INSERT INTO DemoUnique VALUES ('A001', 'Unique Test 1'), ('A002', 'Unique Test 2');
CREATE UNIQUE INDEX UIX_DemoUnique_Code ON DemoUnique(Code);

-- Композитный индекс
CREATE TABLE DemoComposite (
    LastName NVARCHAR(50),
    FirstName NVARCHAR(50),
    Age INT
);
INSERT INTO DemoComposite VALUES 
    ('Иванов', 'Иван', 25),
    ('Иванов', 'Петр', 30),
    ('Петров', 'Иван', 28);
CREATE INDEX IX_DemoComposite_Name ON DemoComposite(LastName, FirstName);

-- INCLUDE
CREATE TABLE DemoInclude (
    ProductCode INT,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2),
    Quantity INT
);
INSERT INTO DemoInclude VALUES 
    (1, 'Товар 1', 100.50, 10),
    (2, 'Товар 2', 200.75, 5),
    (3, 'Товар 3', 300.00, 8);
CREATE INDEX IX_DemoInclude_Code ON DemoInclude(ProductCode) INCLUDE (ProductName, Price); -- не делает столбцы частью ключа, но хранит данные

-- Вычисляемый столбец
CREATE TABLE DemoComputed (
    Price DECIMAL(10,2),
    Quantity INT,
    TotalValue AS (Price * Quantity) PERSISTED -- PERSITED - сохраняемый, без него (по умолчанию) считается при каждом запросе
);
INSERT INTO DemoComputed (Price, Quantity) 
VALUES (100, 5), (200, 3), (150, 4);
CREATE INDEX IX_DemoComputed_Total ON DemoComputed(TotalValue);

-- XML индексы
CREATE TABLE DemoXML (
    DocID INT PRIMARY KEY,
    XMLData XML
);
INSERT INTO DemoXML VALUES 
    (1, '<root><item id="1">Значение 1</item><item id="2">Значение 2</item></root>'),
    (2, '<root><item id="3">Значение 3</item><item id="4">Значение 4</item></root>');
CREATE PRIMARY XML INDEX PXML_DemoXML_Data ON DemoXML(XMLData);
CREATE XML INDEX IXML_DemoXML_Path ON DemoXML(XMLData) USING XML INDEX PXML_DemoXML_Data FOR PATH;
CREATE XML INDEX IXML_DemoXML_Value ON DemoXML(XMLData) USING XML INDEX PXML_DemoXML_Data FOR VALUE;
CREATE XML INDEX IXML_DemoXML_Property ON DemoXML(XMLData) USING XML INDEX PXML_DemoXML_Data FOR PROPERTY;

-- FILLFACTOR
CREATE TABLE DemoFillFactor (
    ID INT,
    Data NVARCHAR(1000)
);
INSERT INTO DemoFillFactor SELECT TOP 1000 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), 'Test' FROM sys.all_columns;
CREATE INDEX IX_DemoFillFactor_ID ON DemoFillFactor(ID) WITH (FILLFACTOR = 70); -- процент заполенения страницы индекса

-- PAD_INDEX
CREATE TABLE DemoPadIndex (
    ID INT,
    Data NVARCHAR(1000)
);
INSERT INTO DemoPadIndex SELECT TOP 1000 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), 'Test' FROM sys.all_columns;
CREATE INDEX IX_DemoPadIndex_ID ON DemoPadIndex(ID) WITH (FILLFACTOR = 60, PAD_INDEX = ON);

-- IGNORE_DUP_KEY
CREATE TABLE DemoIgnoreDup (
    UniqueCode INT
);
CREATE UNIQUE INDEX UIX_DemoIgnoreDup_Code ON DemoIgnoreDup(UniqueCode) WITH (IGNORE_DUP_KEY = ON);

-- ALLOW_ROW_LOCKS
CREATE TABLE DemoRowLocks (
    ID INT,
    Data NVARCHAR(100)
);
INSERT INTO DemoRowLocks VALUES (1, 'Test 1'), (2, 'Test 2'), (3, 'Test 3');
CREATE INDEX IX_DemoRowLocks_ID ON DemoRowLocks(ID) WITH (ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = ON);
GO

-- 4: ВИДЫ ИНДЕКСОВ

USE [T-SQL_lab_4_test];
GO
-- 4.1 Кластеризованного индекс
SELECT * FROM DemoClustered WHERE ID = 2;
GO

-- 4.2 Уникальный индекс
BEGIN TRY
    INSERT INTO DemoUnique VALUES ('A001', 'Дубликат');
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА: Нельзя вставить дубликат в уникальный индекс!';
END CATCH
SELECT * FROM DemoUnique;
GO

-- 4.3 Композитный индекс
SELECT * FROM DemoComposite WHERE LastName = 'Иванов' AND FirstName = 'Иван';
GO

-- 4.4 INCLUDE
-- Весь запрос берется из индекса, без обращения к таблице
SELECT ProductCode, ProductName, Price FROM DemoInclude WHERE ProductCode = 2;
GO

-- 4.5 Индекс на вычисляемом столбце
SELECT * FROM DemoComputed WHERE TotalValue > 500;
GO

-- 4.6 XML индекс
SELECT DocID, XMLData.value('(/root/item[@id="1"]/text())[1]', 'VARCHAR(20)') AS ItemValue
FROM DemoXML
WHERE XMLData.exist('/root/item[@id="2"]') = 1;
GO

-- 4.7 FILLFACTOR
SELECT 
    name,
    fill_factor
FROM sys.indexes 
WHERE object_id = OBJECT_ID('DemoFillFactor');
GO

-- 4.8 IGNORE_DUP_KEY
INSERT INTO DemoIgnoreDup VALUES (1), (1), (2), (1), (3);
SELECT * FROM DemoIgnoreDup;
GO

-- 4.9 Блокировоки
SELECT 
    name,
    allow_row_locks,
    allow_page_locks
FROM sys.indexes
WHERE object_id = OBJECT_ID('DemoRowLocks');
GO



-- 5: ПОЛУЧЕНИЕ ИНФОРМАЦИИ ОБ ИНДЕКСАХ

-- 5.1 sys.indexes
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    type_desc,
    is_unique,
    is_primary_key,
    fill_factor
FROM sys.indexes
WHERE object_id > 100 AND name IS NOT NULL
ORDER BY TableName, IndexName;

-- 5.2 sp_helpindex
EXEC sp_helpindex 'DemoComposite';

-- 5.3 INDEXPROPERTY
SELECT 
    'UIX_DemoUnique_Code' AS IndexName,
    INDEXPROPERTY(OBJECT_ID('DemoUnique'), 'UIX_DemoUnique_Code', 'IsUnique') AS IsUnique,
    INDEXPROPERTY(OBJECT_ID('DemoUnique'), 'UIX_DemoUnique_Code', 'IsClustered') AS IsClustered;

-- 5.4 sys.index_columns
SELECT 
    i.name AS IndexName,
    c.name AS ColumnName,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('DemoInclude');

-- 5.5 sys.dm_db_index_physical_stats
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 0;
GO

-- 6: ОПТИМИЗАЦИЯ И ДЕФРАГМЕНТАЦИЯ

-- 6.1 Реорганизация
ALTER INDEX IX_DemoFillFactor_ID ON DemoFillFactor REORGANIZE;
GO

-- 6.2 Перестроение
ALTER INDEX IX_DemoPadIndex_ID ON DemoPadIndex REBUILD WITH (FILLFACTOR = 80);
GO

-- 6.3 Обновление статистики
UPDATE STATISTICS DemoComposite WITH FULLSCAN;
GO

UPDATE STATISTICS DemoComposite WITH SAMPLE 50 PERCENT;
GO

-- Автоматически (по умолчанию)
UPDATE STATISTICS DemoComposite;

-- 7: ТЕСТИРОВАНИЕ

USE [T-SQL_lab_4_no_index];
GO
PRINT '--- Тест 1 ---';
SET STATISTICS TIME ON;
SELECT TOP 15 c.CustomerID, c.Name, SUM(oi.Quantity) AS TotalQty
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderItems oi ON o.OrderID = oi.OrderID
WHERE c.CustomerID BETWEEN 1000 AND 20000
GROUP BY c.CustomerID, c.Name
ORDER BY TotalQty DESC;
GO

USE [T-SQL_lab_4_indexed];
GO
PRINT '--- Тест 1 ---';
SELECT TOP 15 c.CustomerID, c.Name, SUM(oi.Quantity) AS TotalQty
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderItems oi ON o.OrderID = oi.OrderID
WHERE c.CustomerID BETWEEN 1000 AND 20000
GROUP BY c.CustomerID, c.Name
ORDER BY TotalQty DESC;
GO

USE [T-SQL_lab_4_no_index];
GO
PRINT '--- Тест 2 ---';
SELECT TOP 10 p.ProductID, p.ProductName, SUM(oi.Quantity) AS TotalSold
FROM Products p
JOIN OrderItems oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSold DESC;
GO

USE [T-SQL_lab_4_indexed];
GO
PRINT '--- Тест 2 ---';
SELECT TOP 10 p.ProductID, p.ProductName, SUM(oi.Quantity) AS TotalSold
FROM Products p
JOIN OrderItems oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSold DESC;
GO

USE [T-SQL_lab_4_no_index];
GO
PRINT '--- Тест 3 ---';
SELECT 
    p.Category,
    COUNT(*) AS OrderCount
FROM OrderItems oi
JOIN Products p ON oi.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY OrderCount DESC;

USE [T-SQL_lab_4_indexed];
GO
PRINT '--- Тест 3 ---';
SELECT 
    p.Category,
    COUNT(*) AS OrderCount
FROM OrderItems oi
JOIN Products p ON oi.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY OrderCount DESC;

USE [T-SQL_lab_4_no_index];
GO
PRINT '--- Тест 4 ---';
SELECT TOP 10 
    p.ProductID, 
    p.ProductName, 
    SUM(oi.Quantity) AS TotalSoldInYear
FROM Products p
JOIN OrderItems oi ON p.ProductID = oi.ProductID
JOIN Orders o ON oi.OrderID = o.OrderID
WHERE o.OrderDate BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSoldInYear DESC;
GO

USE [T-SQL_lab_4_indexed];
GO
PRINT '--- Тест 4 ---';
SELECT TOP 10 
    p.ProductID, 
    p.ProductName, 
    SUM(oi.Quantity) AS TotalSoldInYear
FROM Products p
JOIN OrderItems oi ON p.ProductID = oi.ProductID
JOIN Orders o ON oi.OrderID = o.OrderID
WHERE o.OrderDate BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSoldInYear DESC;
GO

-- 8: ИТОГОВАЯ ИНФОРМАЦИЯ

-- Размеры индексов
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    SUM(s.used_page_count) * 8 / 1024 AS IndexSizeMB
FROM sys.dm_db_partition_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE i.object_id > 100 AND s.index_id > 0
GROUP BY i.object_id, i.name, i.type_desc
ORDER BY IndexSizeMB DESC;


