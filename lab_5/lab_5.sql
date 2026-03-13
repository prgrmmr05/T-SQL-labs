
-- СОЗДАНИЕ БАЗЫ ДАННЫХ

USE master;
GO



CREATE DATABASE [T-SQL_lab_5_views];
GO

USE [T-SQL_lab_5_views];
GO




-- СОЗДАНИЕ СХЕМ


CREATE SCHEMA HumanResources;
GO
CREATE SCHEMA Person;
GO
CREATE SCHEMA Sales;
GO



-- СОЗДАНИЕ ТАБЛИЦ

-- Таблица стран/регионов
CREATE TABLE Person.CountryRegion (
    CountryRegionCode NVARCHAR(3)  NOT NULL CONSTRAINT PK_CountryRegion PRIMARY KEY,
    Name              NVARCHAR(50) NOT NULL
);
GO

-- Таблица провинций/штатов
CREATE TABLE Person.StateProvince (
    StateProvinceID   INT          NOT NULL IDENTITY(1,1) CONSTRAINT PK_StateProvince PRIMARY KEY,
    StateProvinceCode NCHAR(3)     NOT NULL,
    CountryRegionCode NVARCHAR(3)  NOT NULL CONSTRAINT FK_StateProvince_CountryRegion
                                       REFERENCES Person.CountryRegion(CountryRegionCode),
    Name              NVARCHAR(50) NOT NULL
);
GO

-- Таблица адресов
CREATE TABLE Person.Address (
    AddressID       INT          NOT NULL IDENTITY(1,1) CONSTRAINT PK_Address PRIMARY KEY,
    AddressLine1    NVARCHAR(60) NOT NULL,
    AddressLine2    NVARCHAR(60) NULL,
    City            NVARCHAR(30) NOT NULL,
    PostalCode      NVARCHAR(15) NOT NULL,
    StateProvinceID INT          NOT NULL CONSTRAINT FK_Address_StateProvince
                                     REFERENCES Person.StateProvince(StateProvinceID)
);
GO

-- Таблица контактных данных
CREATE TABLE Person.Contact (
    ContactID      INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_Contact PRIMARY KEY,
    Title          NVARCHAR(8)   NULL,
    FirstName      NVARCHAR(50)  NOT NULL,
    MiddleName     NVARCHAR(50)  NULL,
    LastName       NVARCHAR(50)  NOT NULL,
    Suffix         NVARCHAR(10)  NULL,
    Phone          NVARCHAR(25)  NULL,
    EmailAddress   NVARCHAR(50)  NULL,
    EmailPromotion INT           NOT NULL CONSTRAINT DF_Contact_EmailPromotion DEFAULT 0
);
GO

-- Таблица отделов
CREATE TABLE HumanResources.Department (
    DepartmentID INT          NOT NULL IDENTITY(1,1) CONSTRAINT PK_Department PRIMARY KEY,
    Name         NVARCHAR(50) NOT NULL,
    GroupName    NVARCHAR(50) NOT NULL
);
GO

-- Таблица сотрудников
CREATE TABLE HumanResources.Employee (
    EmployeeID   INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_Employee PRIMARY KEY,
    ContactID    INT           NOT NULL CONSTRAINT FK_Employee_Contact
                                   REFERENCES Person.Contact(ContactID),
    JobTitle     NVARCHAR(50)  NOT NULL,
    HireDate     DATE          NOT NULL,
    Salary       DECIMAL(10,2) NOT NULL,
    DepartmentID INT           NULL    CONSTRAINT FK_Employee_Department
                                   REFERENCES HumanResources.Department(DepartmentID)
);
GO

-- Таблица связи сотрудник-адрес
CREATE TABLE HumanResources.EmployeeAddress (
    EmployeeID INT NOT NULL CONSTRAINT FK_EmpAddr_Employee
                       REFERENCES HumanResources.Employee(EmployeeID),
    AddressID  INT NOT NULL CONSTRAINT FK_EmpAddr_Address
                       REFERENCES Person.Address(AddressID),
    CONSTRAINT PK_EmployeeAddress PRIMARY KEY (EmployeeID, AddressID)
);
GO




CREATE TABLE Sales.SalesOrder_North (
    SalesOrderID INT           NOT NULL CONSTRAINT PK_SalesNorth PRIMARY KEY,
    OrderDate    DATE          NOT NULL,
    CustomerID   INT           NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL,
    Region       NVARCHAR(10)  NOT NULL CONSTRAINT DF_SalesNorth_Region DEFAULT 'North',
    CONSTRAINT CK_SalesNorth_Region CHECK (Region = 'North')
);
GO

CREATE TABLE Sales.SalesOrder_South (
    SalesOrderID INT           NOT NULL CONSTRAINT PK_SalesSouth PRIMARY KEY,
    OrderDate    DATE          NOT NULL,
    CustomerID   INT           NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL,
    Region       NVARCHAR(10)  NOT NULL CONSTRAINT DF_SalesSouth_Region DEFAULT 'South',
    CONSTRAINT CK_SalesSouth_Region CHECK (Region = 'South')
);
GO


-- НАПОЛНЕНИЕ ТАБЛИЦ


-- Страны
INSERT INTO Person.CountryRegion (CountryRegionCode, Name) VALUES
('RU', N'Россия'),
('US', N'США'),
('DE', N'Германия');

-- Провинции/области
INSERT INTO Person.StateProvince (StateProvinceCode, CountryRegionCode, Name) VALUES
('MSK', 'RU', N'Москва'),
('SPB', 'RU', N'Санкт-Петербург'),
('NY',  'US', N'Нью-Йорк'),
('CA',  'US', N'Калифорния');

-- Адреса
INSERT INTO Person.Address (AddressLine1, City, PostalCode, StateProvinceID) VALUES
(N'ул. Ленина, 1',     N'Москва',             '101000', 1),
(N'пр. Невский, 100',  N'Санкт-Петербург',    '190000', 2),
(N'5th Avenue, 350',   N'Нью-Йорк',           '10001',  3),
(N'Sunset Blvd, 1200', N'Лос-Анджелес',       '90028',  4);

-- Контакты
INSERT INTO Person.Contact (Title, FirstName, MiddleName, LastName, Phone, EmailAddress) VALUES
('Mr.',  N'Иван',    N'Петрович',   N'Иванов',  '+7-495-111-11-11', 'ivanov@corp.ru'),
('Ms.',  N'Мария',   NULL,          N'Петрова', '+7-812-222-22-22', 'petrova@corp.ru'),
('Mr.',  N'Алексей', N'Николаевич', N'Сидоров', '+7-495-333-33-33', 'sidorov@corp.ru'),
('Mrs.', N'Елена',   N'Сергеевна',  N'Козлова', '+7-495-444-44-44', 'kozlova@corp.ru'),
('Mr.',  N'Дмитрий', NULL,          N'Новиков', '+7-812-555-55-55', 'novikov@corp.ru');

-- Отделы
INSERT INTO HumanResources.Department (Name, GroupName) VALUES
(N'Разработка',                   N'Технологии'),
(N'Маркетинг',                    N'Продажи и Маркетинг'),
(N'Финансы',                      N'Администрация'),
(N'Отдел кадров',                 N'Администрация'),
(N'Информационные технологии',    N'Технологии');

-- Сотрудники
INSERT INTO HumanResources.Employee (ContactID, JobTitle, HireDate, Salary, DepartmentID) VALUES
(1, N'Разработчик',              '2020-01-15', 85000.00, 1),
(2, N'Менеджер по продажам',     '2019-03-20', 72000.00, 2),
(3, N'Финансовый аналитик',      '2021-06-01', 78000.00, 3),
(4, N'HR-специалист',            '2018-11-10', 65000.00, 4),
(5, N'Системный администратор',  '2022-02-28', 80000.00, 5);

-- Адреса сотрудников
INSERT INTO HumanResources.EmployeeAddress (EmployeeID, AddressID) VALUES
(1, 1), (2, 2), (3, 3), (4, 4), (5, 1);

-- Продажи Север (SalesOrderID 1–4)
INSERT INTO Sales.SalesOrder_North (SalesOrderID, OrderDate, CustomerID, TotalAmount) VALUES
(1, '2024-01-10', 101, 15000.00),
(2, '2024-01-15', 102, 23000.00),
(3, '2024-02-05', 103,  8500.00),
(4, '2024-02-20', 104, 31000.00);

-- Продажи Юг (SalesOrderID 5–8)
INSERT INTO Sales.SalesOrder_South (SalesOrderID, OrderDate, CustomerID, TotalAmount) VALUES
(5, '2024-01-12', 201, 12000.00),
(6, '2024-01-25', 202, 18500.00),
(7, '2024-02-08', 203, 27000.00),
(8, '2024-03-01', 204,  9500.00);

PRINT 'Тестовые данные вставлены во все таблицы.';
GO





-- Представление — виртуальная таблица, содержание которой
-- определяется запросом. Строки и столбцы формируются динамически
-- при каждом обращении (если представление не индексировано).
-- Таблицы в запросе называются БАЗОВЫМИ ТАБЛИЦАМИ.


-- 1: Подмножество столбцов базовой таблицы (проекция)
CREATE VIEW HumanResources.vEmployeeNames
AS
SELECT
    e.EmployeeID,
    c.FirstName,
    c.LastName,
    e.JobTitle
FROM HumanResources.Employee  e
INNER JOIN Person.Contact     c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeeNames;
GO

-- 2: Подмножество строк базовой таблицы (фильтрация)
CREATE VIEW HumanResources.vHighPaidEmployees
AS
SELECT
    e.EmployeeID,
    c.FirstName,
    c.LastName,
    e.Salary
FROM HumanResources.Employee  e
INNER JOIN Person.Contact     c ON c.ContactID = e.ContactID
WHERE e.Salary > 75000;
GO
SELECT * FROM HumanResources.vHighPaidEmployees;
GO

-- 3: Соединение нескольких базовых таблиц (JOIN)
CREATE VIEW [HumanResources].[vEmployee]
AS
SELECT
    e.[EmployeeID],
    c.[Title],
    c.[FirstName],
    c.[MiddleName],
    c.[LastName],
    c.[Suffix],
    e.[JobTitle],
    c.[Phone],
    c.[EmailAddress],
    c.[EmailPromotion],
    a.[AddressLine1],
    a.[AddressLine2],
    a.[City],
    sp.[Name]  AS [StateProvinceName],
    a.[PostalCode],
    cr.[Name]  AS [CountryRegionName]
FROM [HumanResources].[Employee]        e
INNER JOIN [Person].[Contact]           c  ON c.[ContactID]       = e.[ContactID]
INNER JOIN [HumanResources].[EmployeeAddress] ea ON e.[EmployeeID] = ea.[EmployeeID]
INNER JOIN [Person].[Address]           a  ON ea.[AddressID]      = a.[AddressID]
INNER JOIN [Person].[StateProvince]     sp ON sp.[StateProvinceID]= a.[StateProvinceID]
INNER JOIN [Person].[CountryRegion]     cr ON cr.[CountryRegionCode] = sp.[CountryRegionCode];
GO
SELECT * FROM [HumanResources].[vEmployee];
GO

-- 4: Статистические итоги (агрегация)
CREATE VIEW HumanResources.vDepartmentSalaryStats
AS
SELECT
    d.Name              AS DepartmentName,
    COUNT(e.EmployeeID) AS EmployeeCount,
    AVG(e.Salary)       AS AvgSalary,
    MIN(e.Salary)       AS MinSalary,
    MAX(e.Salary)       AS MaxSalary,
    SUM(e.Salary)       AS TotalSalary
FROM HumanResources.Employee   e
INNER JOIN HumanResources.Department d ON d.DepartmentID = e.DepartmentID
GROUP BY d.Name;
GO
SELECT * FROM HumanResources.vDepartmentSalaryStats;
GO

-- 5: Подмножество другого представления (вложенное представление)
-- vMoscowEmployees строится поверх vEmployee
CREATE VIEW HumanResources.vMoscowEmployees
AS
SELECT
    EmployeeID,
    FirstName,
    LastName,
    City,
    CountryRegionName
FROM HumanResources.vEmployee          -- БАЗОВОЕ ПРЕДСТАВЛЕНИЕ
WHERE City = N'Москва';
GO
SELECT * FROM HumanResources.vMoscowEmployees;
GO



-- ПРЕДСТАВЛЕНИЯ
-- 1. Стандартные     — данные формируются динамически
-- 2. Индексированные — материализованы, физически хранятся
-- 3. Секционированные — объединяют горизонтально разделённые данные



-- ПРЕИМУЩЕСТВА ПРЕДСТАВЛЕНИЙ



-- 1: Фокусировка данных для пользователя
-- Пользователь видит только нужные столбцы — чувствительные данные скрыты.
CREATE VIEW HumanResources.vEmployeePublic
AS
SELECT
    e.EmployeeID,
    c.FirstName,
    c.LastName,
    e.JobTitle,
    c.Phone,
    c.EmailAddress
    -- Salary намеренно не включена!
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeePublic;
GO

-- 2: Защита от сложности базы данных
SELECT FirstName, LastName, City, CountryRegionName
FROM HumanResources.vEmployee;
GO

-- 3: Упрощение управления правами

-- новый юзер
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'readonly_user')
    CREATE LOGIN [readonly_user] WITH PASSWORD = 'P@ssw0rd_Lab5!';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'readonly_user')
    CREATE USER [readonly_user] FOR LOGIN [readonly_user];
GO

-- право ТОЛЬКО на представление — не на базовые таблицы!
GRANT SELECT ON HumanResources.vEmployeePublic TO [readonly_user];
GO
-- Право SELECT выдано на vEmployeePublic. На таблицы Employee и Contact — НЕТ.

-- проверка, что пользователь имеет право на представление
SELECT
    dp.name          AS [Пользователь],
    o.name           AS [Объект],
    o.type_desc,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
INNER JOIN sys.objects             o  ON o.object_id     = p.major_id
WHERE dp.name = 'readonly_user';
GO

-- запросы от имени readonly_user через EXECUTE AS
EXECUTE AS USER = 'readonly_user';
    BEGIN TRY
        SELECT * FROM HumanResources.vEmployeePublic;
        PRINT 'Доступ к представлению — РАЗРЕШЁН.';
    END TRY
    BEGIN CATCH
        PRINT 'ОШИБКА: ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- запрос от имени readonly_user напрямую к таблице Employee (должен ОТКЛОНИТЬ)'
EXECUTE AS USER = 'readonly_user';
    BEGIN TRY
        SELECT * FROM HumanResources.Employee;
        PRINT 'Доступ к таблице — разрешён (неожиданно!).';
    END TRY
    BEGIN CATCH
        PRINT 'Доступ к таблице Employee — ЗАПРЕЩЁН (ожидаемо): ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- запрос от имени readonly_user напрямую к таблице Contact (должен ОТКЛОНИТЬ):
EXECUTE AS USER = 'readonly_user';
    BEGIN TRY
        SELECT * FROM Person.Contact;
    END TRY
    BEGIN CATCH
        PRINT 'Доступ к таблице Contact — ЗАПРЕЩЁН (ожидаемо): ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- отзыв прав и удаление юзера
REVOKE SELECT ON HumanResources.vEmployeePublic FROM [readonly_user];
DROP USER  [readonly_user];
DROP LOGIN [readonly_user];
GO

-- ПРЕИМУЩЕСТВО 4: Улучшение производительности (индексированные — см. Урок 3)


-- ПРЕИМУЩЕСТВО 5: Организация данных для экспорта
-- Представление готовит данные для экспорта в другое приложение


-- ПРЕИМУЩЕСТВО 6: Обратная совместимость
-- Представление эмулирует старую таблицу после изменения схемы
CREATE VIEW HumanResources.vLegacyEmployeeView
AS
-- "Старая" схема: FullName как единый столбец, без MiddleName
SELECT
    e.EmployeeID             AS EmpID,
    c.FirstName + ' ' + c.LastName AS FullName,
    e.JobTitle               AS Position,
    e.HireDate               AS StartDate
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vLegacyEmployeeView;
GO



-- СИНТАКСИС CREATE VIEW:
--
-- CREATE VIEW [ schema_name . ] view_name [ (column [ ,...n ] ) ]
-- [ WITH [ ENCRYPTION ] [, SCHEMABINDING ] [, VIEW_METADATA ] ]
-- AS select_statement [ ; ]
-- [ WITH CHECK OPTION ]


-- 2.1 CREATE VIEW — явное задание имён столбцов
-- Требуется, если: столбец получен из выражения / функции,
-- или в соединяемых таблицах есть одноимённые столбцы.
CREATE VIEW HumanResources.vEmployeeContact (
    EmployeeID,
    FullName,
    ContactPhone,
    WorkEmail
)
AS
SELECT
    e.EmployeeID,
    c.FirstName + N' ' + c.LastName,   -- выражение → нужен псевдоним
    c.Phone,
    c.EmailAddress
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeeContact;
GO





-- WITH VIEW_METADATA
-- При запросах через API SQL Server возвращает метаданные
-- о представлении (а не о базовых таблицах).
-- Позволяет клиентским приложениям обновлять данные через представление.
CREATE VIEW HumanResources.vEmployeeMetadata
WITH VIEW_METADATA
AS
SELECT
    e.EmployeeID,
    c.FirstName,
    c.LastName,
    e.JobTitle,
    e.HireDate
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vEmployeeMetadata;
GO


-- ORDER BY разрешён только совместно с TOP
CREATE VIEW HumanResources.vTop3HighestPaid
AS
SELECT TOP 3
    e.EmployeeID,
    c.FirstName,
    c.LastName,
    e.Salary
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID
ORDER BY e.Salary DESC;          -- ORDER BY разрешён благодаря TOP
GO
SELECT * FROM HumanResources.vTop3HighestPaid;
GO




-- ALTER VIEW — изменение представления
-- Сохраняет права; не затрагивает хранимые процедуры и триггеры.
-- Имеет те же ограничения, что и CREATE VIEW.


-- До ALTER VIEW — vEmployee включает адресные данные:
SELECT EmployeeID, FirstName, City, CountryRegionName
FROM HumanResources.vEmployee;
GO

-- Изменяем vEmployee — убираем адресную информацию
ALTER VIEW [HumanResources].[vEmployee]
AS
SELECT
    e.[EmployeeID],
    c.[Title],
    c.[FirstName],
    c.[MiddleName],
    c.[LastName],
    c.[Suffix],
    e.[JobTitle],
    c.[Phone],
    c.[EmailAddress]
FROM [HumanResources].[Employee]  e
INNER JOIN [Person].[Contact]     c ON c.[ContactID] = e.[ContactID];
GO

-- После ALTER VIEW — адресные данные удалены из представления:
SELECT * FROM [HumanResources].[vEmployee];
GO


-- DROP VIEW — удаление представления
-- Удаляет определение и все права на него.
-- Удаление таблицы НЕ удаляет представление автоматически!

-- Создаём представление специально для удаления
CREATE VIEW HumanResources.vTempForDrop
AS
SELECT EmployeeID, JobTitle FROM HumanResources.Employee;
GO

SELECT * FROM HumanResources.vTempForDrop;

DROP VIEW HumanResources.vTempForDrop;
GO

-- DROP VIEW нескольких представлений одним оператором
-- Синтаксис: DROP VIEW [ schema_name . ] view_name [ ...,n ]
CREATE VIEW HumanResources.vDropTest1 AS SELECT 1 AS Num;
CREATE VIEW HumanResources.vDropTest2 AS SELECT 2 AS Num;
GO
DROP VIEW HumanResources.vDropTest1, HumanResources.vDropTest2;
GO








-- ИНДЕКСИРОВАННЫЕ ПРЕДСТАВЛЕНИЯ

-- параметры сессии для индексированных представлений
SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING        ON;
SET ANSI_WARNINGS       ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER   ON;
SET ANSI_NULLS          ON;
SET ARITHABORT          ON;
GO


CREATE UNIQUE CLUSTERED INDEX [IX_vStateProvinceCountryRegion]
ON [Person].[vStateProvinceCountryRegion]
(
    [StateProvinceID]   ASC,
    [CountryRegionCode] ASC
);
GO


-- Запрос использует индекс
SELECT * FROM Person.vStateProvinceCountryRegion WHERE CountryRegionCode = 'RU';
GO

-- Индексированное представление с агрегацией (COUNT_BIG обязателен)
CREATE VIEW Sales.vSalesNorthSummary
WITH SCHEMABINDING
AS
SELECT
    [CustomerID],
    COUNT_BIG(*)       AS OrderCount,    -- COUNT_BIG обязателен при агрегации
    SUM([TotalAmount]) AS TotalRevenue
FROM [Sales].[SalesOrder_North]          -- двухчастное имя
GROUP BY [CustomerID];
GO

-- Создаём кластерный индекс
CREATE UNIQUE CLUSTERED INDEX [IX_vSalesNorthSummary_CustomerID]
ON [Sales].[vSalesNorthSummary]
([CustomerID] ASC);
GO

-- Индексированное представление vSalesNorthSummary создано с агрегацией:
SELECT * FROM Sales.vSalesNorthSummary;
GO

-- Оптимизатор может использовать индекс представления
-- даже без явного указания имени представления в запросе!
-- (WITH (NOEXPAND) форсирует использование индексированного представления):
SELECT CustomerID, SUM(TotalAmount) AS Revenue
FROM Sales.SalesOrder_North
GROUP BY CustomerID;
GO



/*
'Когда использовать индексированные представления:'
Данные обновляются редко'
Запросы выполняют много JOIN и агрегаций'
Многие пользователи часто запрашивают одни и те же данные'
Не подходит: таблицы часто обновляются (издержки на поддержание индекса)'
*/

-- СЕКЦИОНИРОВАННЫЕ ПРЕДСТАВЛЕНИЯ (PARTITIONED VIEWS)

CREATE VIEW Sales.vSalesPartitioned
AS
SELECT          -- Секция "Север"
    [SalesOrderID],
    [OrderDate],
    [CustomerID],
    [TotalAmount],
    [Region]
FROM [Sales].[SalesOrder_North]

UNION ALL       -- объединение без дублирования

SELECT          -- Секция "Юг"
    [SalesOrderID],
    [OrderDate],
    [CustomerID],
    [TotalAmount],
    [Region]
FROM [Sales].[SalesOrder_South];
GO

-- Локальное секционированное представление — объединённые данные:'
SELECT * FROM Sales.vSalesPartitioned ORDER BY SalesOrderID;
GO

-- Оптимизатор использует CHECK CONSTRAINT для исключения лишних таблиц
-- Запрос только по Region = North (читает только SalesOrder_North):
SELECT * FROM Sales.vSalesPartitioned WHERE Region = 'North';
GO

-- Запрос только по Region = South (читает только SalesOrder_South):
SELECT * FROM Sales.vSalesPartitioned WHERE Region = 'South';
GO

-- Агрегация через секционированное представление
SELECT
    Region,
    COUNT(*)         AS OrderCount,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AvgOrderValue,
    MIN(TotalAmount) AS MinOrder,
    MAX(TotalAmount) AS MaxOrder
FROM Sales.vSalesPartitioned
GROUP BY Region;
GO




CREATE VIEW HumanResources.vSalarySensitive
WITH ENCRYPTION
AS
SELECT
    e.EmployeeID,
    c.FirstName + N' ' + c.LastName AS EmployeeName,
    e.Salary,
    e.HireDate
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID;
GO
SELECT * FROM HumanResources.vSalarySensitive;
GO


EXEC sp_helptext 'HumanResources.vSalarySensitive';


SELECT
    s.name  AS [Схема],
    v.name  AS [Представление],
    OBJECTPROPERTY(v.object_id, 'IsEncrypted')   AS [Encrypted?]
FROM sys.views v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE v.name = 'vSalarySensitive';
GO