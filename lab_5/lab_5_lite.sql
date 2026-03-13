USE master;
GO

-- проверка существования БД и удаление
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'T-SQL_lab_5_views')
BEGIN
    ALTER DATABASE [T-SQL_lab_5_views] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [T-SQL_lab_5_views];
END
GO

-- создание БД
CREATE DATABASE [T-SQL_lab_5_views];
GO
USE [T-SQL_lab_5_views];
GO

-- схемы
CREATE SCHEMA HumanResources; 
GO
CREATE SCHEMA Person;        
GO
CREATE SCHEMA Sales;          
GO

-- справочник стран
CREATE TABLE Person.CountryRegion (
    CountryRegionCode NVARCHAR(3)  NOT NULL CONSTRAINT PK_CountryRegion PRIMARY KEY,
    Name              NVARCHAR(50) NOT NULL
);
GO

-- справочник регионов (связь со странами)
CREATE TABLE Person.StateProvince (
    StateProvinceID   INT          NOT NULL IDENTITY(1,1) CONSTRAINT PK_StateProvince PRIMARY KEY,
    StateProvinceCode NCHAR(3)     NOT NULL,
    CountryRegionCode NVARCHAR(3)  NOT NULL CONSTRAINT FK_StateProvince_CountryRegion
                                       REFERENCES Person.CountryRegion(CountryRegionCode),
    Name              NVARCHAR(50) NOT NULL
);
GO

-- контактные данные
CREATE TABLE Person.Contact (
    ContactID    INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_Contact PRIMARY KEY,
    Title        NVARCHAR(8)   NULL,
    FirstName    NVARCHAR(50)  NOT NULL,
    MiddleName   NVARCHAR(50)  NULL,
    LastName     NVARCHAR(50)  NOT NULL,
    Phone        NVARCHAR(25)  NULL,
    EmailAddress NVARCHAR(50)  NULL
);
GO

-- отделы
CREATE TABLE HumanResources.Department (
    DepartmentID INT          NOT NULL IDENTITY(1,1) CONSTRAINT PK_Department PRIMARY KEY,
    Name         NVARCHAR(50) NOT NULL,
    GroupName    NVARCHAR(50) NOT NULL
);
GO

-- сотрудники (связь с контактами и отделами)
CREATE TABLE HumanResources.Employee (
    EmployeeID   INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_Employee PRIMARY KEY,
    ContactID    INT           NOT NULL CONSTRAINT FK_Employee_Contact
                                   REFERENCES Person.Contact(ContactID),
    JobTitle     NVARCHAR(50)  NOT NULL,
    HireDate     DATE          NOT NULL,
    Salary       DECIMAL(10,2) NOT NULL,
    DepartmentID INT           NULL CONSTRAINT FK_Employee_Department
                                   REFERENCES HumanResources.Department(DepartmentID)
);
GO

-- секция СЕВЕР (только North)
CREATE TABLE Sales.SalesOrder_North (
    SalesOrderID INT           NOT NULL CONSTRAINT PK_SalesNorth PRIMARY KEY,
    OrderDate    DATE          NOT NULL,
    CustomerID   INT           NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL,
    Region       NVARCHAR(10)  NOT NULL CONSTRAINT DF_SalesNorth_Region DEFAULT 'North',
    CONSTRAINT CK_SalesNorth_Region CHECK (Region = 'North')
);
GO

-- секция ЮГ (только South)
CREATE TABLE Sales.SalesOrder_South (
    SalesOrderID INT           NOT NULL CONSTRAINT PK_SalesSouth PRIMARY KEY,
    OrderDate    DATE          NOT NULL,
    CustomerID   INT           NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL,
    Region       NVARCHAR(10)  NOT NULL CONSTRAINT DF_SalesSouth_Region DEFAULT 'South',
    CONSTRAINT CK_SalesSouth_Region CHECK (Region = 'South')
);
GO

-- тестовые данные: страны
INSERT INTO Person.CountryRegion VALUES ('RU', N'Россия'), ('US', N'США');

-- тестовые данные: регионы
INSERT INTO Person.StateProvince (StateProvinceCode, CountryRegionCode, Name) VALUES
('MSK', 'RU', N'Москва'), ('SPB', 'RU', N'Санкт-Петербург'), ('NY', 'US', N'Нью-Йорк');

-- тестовые данные: контакты
INSERT INTO Person.Contact (Title, FirstName, MiddleName, LastName, Phone, EmailAddress) VALUES
('Mr.',  N'Иван',    N'Петрович',   N'Иванов',  '+7-495-111-11-11', 'ivanov@corp.ru'),
('Ms.',  N'Мария',   NULL,          N'Петрова', '+7-812-222-22-22', 'petrova@corp.ru'),
('Mr.',  N'Алексей', N'Николаевич', N'Сидоров', '+7-495-333-33-33', 'sidorov@corp.ru'),
('Mrs.', N'Елена',   N'Сергеевна',  N'Козлова', '+7-495-444-44-44', 'kozlova@corp.ru');

-- тестовые данные: отделы
INSERT INTO HumanResources.Department (Name, GroupName) VALUES
(N'Разработка',  N'Технологии'),
(N'Маркетинг',   N'Продажи и Маркетинг'),
(N'Финансы',     N'Администрация');

-- тестовые данные: сотрудники
INSERT INTO HumanResources.Employee (ContactID, JobTitle, HireDate, Salary, DepartmentID) VALUES
(1, N'Разработчик',          '2020-01-15', 85000, 1),
(2, N'Менеджер по продажам', '2019-03-20', 72000, 2),
(3, N'Финансовый аналитик',  '2021-06-01', 78000, 3),
(4, N'HR-специалист',        '2018-11-10', 65000, 1);

-- тестовые данные: северные заказы
INSERT INTO Sales.SalesOrder_North (SalesOrderID, OrderDate, CustomerID, TotalAmount) VALUES
(1, '2024-01-10', 101, 15000), (2, '2024-02-05', 102, 23000),
(3, '2024-02-20', 103,  8500), (4, '2024-03-01', 104, 31000);

-- тестовые данные: южные заказы
INSERT INTO Sales.SalesOrder_South (SalesOrderID, OrderDate, CustomerID, TotalAmount) VALUES
(5, '2024-01-12', 201, 12000), (6, '2024-01-25', 202, 18500),
(7, '2024-02-08', 203, 27000), (8, '2024-03-01', 204,  9500);
GO

-- СТАНДАРТ: простое объединение двух таблиц
CREATE VIEW HumanResources.vEmployeeNames
AS
SELECT e.EmployeeID, c.FirstName, c.LastName, e.JobTitle, e.Salary
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeeNames;
GO

-- ЯВНЫЕ ИМЕНА: т.к. есть выражение (конкатенация)
CREATE VIEW HumanResources.vEmployeeContact (EmployeeID, FullName, ContactPhone)
AS
SELECT e.EmployeeID,
       c.FirstName + N' ' + c.LastName,
       c.Phone
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeeContact;
GO

-- ШИФРОВАНИЕ: текст представления недоступен для чтения
CREATE VIEW HumanResources.vSalarySensitive
WITH ENCRYPTION
AS
SELECT e.EmployeeID,
       c.FirstName + N' ' + c.LastName AS EmployeeName,
       e.Salary
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vSalarySensitive;
GO

-- попытка прочитать зашифрованное (ошибка)
EXEC sp_helptext 'HumanResources.vSalarySensitive';

-- CHECK OPTION: нельзя изменить так, чтобы строка исчезла из представления
CREATE VIEW HumanResources.vDept1Employees
AS
SELECT e.EmployeeID, c.FirstName, e.DepartmentID, e.Salary
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID
WHERE e.DepartmentID = 1
WITH CHECK OPTION;
GO
SELECT * FROM HumanResources.vDept1Employees;
GO

-- разрешено (остаётся в Dept1)
UPDATE HumanResources.vDept1Employees SET Salary = 90000 WHERE EmployeeID = 1;
GO

-- запрещено (уйдёт из Dept1)
BEGIN TRY
    UPDATE HumanResources.vDept1Employees SET DepartmentID = 2 WHERE EmployeeID = 1;
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
END CATCH
GO

-- ИЗМЕНЕНИЕ: добавляем поле HireDate
ALTER VIEW HumanResources.vEmployeeNames
AS
SELECT e.EmployeeID, c.FirstName, c.LastName, e.JobTitle, e.Salary, e.HireDate
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeeNames;
GO

-- изменение зашифрованного (WITH ENCRYPTION)
ALTER VIEW HumanResources.vSalarySensitive
WITH ENCRYPTION
AS
SELECT e.EmployeeID,
       c.FirstName + N' ' + c.LastName AS EmployeeName,
       e.Salary, e.HireDate
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vSalarySensitive;
GO







-- обязательные настройки для индексированных представлений
SET NUMERIC_ROUNDABORT     OFF;
SET ANSI_PADDING            ON;
SET ANSI_WARNINGS           ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER       ON;
SET ANSI_NULLS              ON;
SET ARITHABORT              ON;
GO

-- SCHEMABINDING: привязка к схеме (для индекса)
CREATE VIEW Person.vStateProvinceCountryRegion
WITH SCHEMABINDING
AS
SELECT sp.[StateProvinceID], sp.[StateProvinceCode],
       sp.[Name] AS [StateProvinceName], sp.[CountryRegionCode],
       cr.[Name] AS [CountryRegionName]
FROM [Person].[StateProvince]   sp
INNER JOIN [Person].[CountryRegion] cr ON cr.[CountryRegionCode] = sp.[CountryRegionCode];
GO



-- проверка: SCHEMABINDING блокирует изменение таблицы
BEGIN TRY
    ALTER TABLE Person.StateProvince DROP COLUMN StateProvinceCode;
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
    PRINT '→ SCHEMABINDING запрещает изменения, которые сломают представление.';
END CATCH
GO

-- ИНДЕКС: материализуем представление
CREATE UNIQUE CLUSTERED INDEX [IX_vStateProvinceCountryRegion]
ON [Person].[vStateProvinceCountryRegion] ([StateProvinceID] ASC, [CountryRegionCode] ASC);
GO
SELECT * FROM Person.vStateProvinceCountryRegion WHERE CountryRegionCode = 'RU';
GO

-- агрегация с COUNT_BIG (обязательно для индекса)
CREATE VIEW Sales.vSalesNorthSummary
WITH SCHEMABINDING
AS
SELECT [CustomerID],
       COUNT_BIG(*)       AS OrderCount,
       SUM([TotalAmount]) AS TotalRevenue
FROM [Sales].[SalesOrder_North]
GROUP BY [CustomerID];
GO

-- индекс на агрегированном представлении
CREATE UNIQUE CLUSTERED INDEX [IX_vSalesNorthSummary]
ON [Sales].[vSalesNorthSummary] ([CustomerID] ASC);
GO
SELECT * FROM Sales.vSalesNorthSummary;
GO

-- оптимизатор может использовать индекс даже без указания представления
SELECT CustomerID, SUM(TotalAmount) AS Revenue
FROM Sales.SalesOrder_North
GROUP BY CustomerID;
GO

-- проверка: какие индексы созданы на представлениях
SELECT OBJECT_NAME(i.object_id) AS [Представление], i.name AS [Индекс], i.type_desc
FROM sys.indexes i INNER JOIN sys.views v ON v.object_id = i.object_id
WHERE i.type > 0;
GO

-- СЕКЦИОНИРОВАННОЕ: объединение двух таблиц-секций
CREATE VIEW Sales.vSalesPartitioned
AS
SELECT [SalesOrderID], [OrderDate], [CustomerID], [TotalAmount], [Region]
FROM [Sales].[SalesOrder_North]
UNION ALL
SELECT [SalesOrderID], [OrderDate], [CustomerID], [TotalAmount], [Region]
FROM [Sales].[SalesOrder_South];
GO

-- все данные как единое целое
SELECT * FROM Sales.vSalesPartitioned ORDER BY SalesOrderID;
GO

-- elimination: читается только нужная секция
SELECT * FROM Sales.vSalesPartitioned WHERE Region = 'North';
SELECT * FROM Sales.vSalesPartitioned WHERE Region = 'South';
GO

-- агрегация по секциям
SELECT Region, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalRevenue
FROM Sales.vSalesPartitioned
GROUP BY Region;
GO

-- метаданные: информация о представлениях
SELECT s.name AS [Схема], v.name AS [Представление],
       OBJECTPROPERTY(v.object_id, 'IsIndexed')     AS [Индексировано],
       OBJECTPROPERTY(v.object_id, 'IsSchemaBound')  AS [SchemaBound],
       OBJECTPROPERTY(v.object_id, 'IsEncrypted')    AS [Зашифровано]
FROM sys.views v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
ORDER BY s.name, v.name;
GO

-- получение текста незашифрованного представления
EXEC sp_helptext 'HumanResources.vEmployeeNames';
GO

-- зависимости: кто использует таблицу Employee
SELECT OBJECT_NAME(referencing_id) AS [Зависимый объект],
       referenced_entity_name      AS [Исходный объект]
FROM sys.sql_expression_dependencies
WHERE referenced_entity_name = 'Employee'
  AND referenced_schema_name = 'HumanResources';
GO

-- финальная классификация всех представлений
SELECT s.name AS [Схема], v.name AS [Представление],
    CASE
        WHEN OBJECTPROPERTY(v.object_id, 'IsIndexed')    = 1 THEN N'Индексированное'
        WHEN OBJECTPROPERTY(v.object_id, 'IsSchemaBound')= 1 THEN N'С привязкой схемы'
        ELSE N'Стандартное'
    END                                               AS [Тип],
    OBJECTPROPERTY(v.object_id, 'IsEncrypted')        AS [Зашифровано],
    v.create_date                                     AS [Дата создания]
FROM sys.views v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
ORDER BY s.name, v.name;
GO







