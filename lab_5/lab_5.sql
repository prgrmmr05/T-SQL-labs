
-- СОЗДАНИЕ БАЗЫ ДАННЫХ

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'T-SQL_lab_5_views')
BEGIN
    ALTER DATABASE [T-SQL_lab_5_views] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [T-SQL_lab_5_views];
    PRINT 'Старая база данных удалена.';
END
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

-- Таблицы для демонстрации секционированного представления
-- !!! CHECK CONSTRAINT на столбце Region - SQL Server
-- использует его для оптимизации при запросах к секц. представлению


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


-- ПРИМЕР 1: Подмножество столбцов базовой таблицы (проекция)
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

-- ПРИМЕР 2: Подмножество строк базовой таблицы (фильтрация)
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

-- ПРИМЕР 3: Соединение нескольких базовых таблиц (JOIN)
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

-- ПРИМЕР 4: Статистические итоги (агрегация)
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

-- ПРИМЕР 5: Подмножество другого представления (вложенное представление)
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



-- ТИПЫ ПРЕДСТАВЛЕНИЙ
-- 1. Стандартные     — данные формируются динамически
-- 2. Индексированные — материализованы, физически хранятся
-- 3. Секционированные — объединяют горизонтально разделённые данные



-- ПРЕИМУЩЕСТВА ПРЕДСТАВЛЕНИЙ



-- ПРЕИМУЩЕСТВО 1: Фокусировка данных для пользователя
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

-- ПРЕИМУЩЕСТВО 2: Защита от сложности базы данных
-- Сложный JOIN скрыт — пользователь запрашивает как обычную таблицу.
SELECT FirstName, LastName, City, CountryRegionName
FROM HumanResources.vEmployee;
GO

-- ПРЕИМУЩЕСТВО 3: Упрощение управления правами

-- Создаём логин и пользователя БД (без пароля — только для теста)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'readonly_user')
    CREATE LOGIN [readonly_user] WITH PASSWORD = 'P@ssw0rd_Lab5!';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'readonly_user')
    CREATE USER [readonly_user] FOR LOGIN [readonly_user];
GO

-- Выдаём право ТОЛЬКО на представление — не на базовые таблицы!
GRANT SELECT ON HumanResources.vEmployeePublic TO [readonly_user];
GO
-- Право SELECT выдано на vEmployeePublic. На таблицы Employee и Contact — НЕТ.

-- Проверяем, что пользователь имеет право на представление
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

-- Выполняем запросы от имени readonly_user через EXECUTE AS
EXECUTE AS USER = 'readonly_user';
    BEGIN TRY
        SELECT * FROM HumanResources.vEmployeePublic;
        PRINT '✓ Доступ к представлению — РАЗРЕШЁН.';
    END TRY
    BEGIN CATCH
        PRINT '✗ ОШИБКА: ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- Запрос от имени readonly_user напрямую к таблице Employee (должен ОТКЛОНИТЬ)'
EXECUTE AS USER = 'readonly_user';
    BEGIN TRY
        SELECT * FROM HumanResources.Employee;
        PRINT '✓ Доступ к таблице — разрешён (неожиданно!).';
    END TRY
    BEGIN CATCH
        PRINT '✗ Доступ к таблице Employee — ЗАПРЕЩЁН (ожидаемо): ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- Запрос от имени readonly_user напрямую к таблице Contact (должен ОТКЛОНИТЬ):
EXECUTE AS USER = 'readonly_user';
    BEGIN TRY
        SELECT * FROM Person.Contact;
    END TRY
    BEGIN CATCH
        PRINT '✗ Доступ к таблице Contact — ЗАПРЕЩЁН (ожидаемо): ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- Отзываем право и убираем пользователя
REVOKE SELECT ON HumanResources.vEmployeePublic FROM [readonly_user];
DROP USER  [readonly_user];
DROP LOGIN [readonly_user];
GO

-- ПРЕИМУЩЕСТВО 4: Улучшение производительности (индексированные — см. Урок 3)


-- ПРЕИМУЩЕСТВО 5: Организация данных для экспорта
-- Представление готовит данные для экспорта в другое приложение
CREATE VIEW Sales.vExportSalesReport
AS
SELECT
    sn.SalesOrderID,
    sn.OrderDate,
    sn.CustomerID,
    sn.TotalAmount,
    sn.Region
FROM Sales.SalesOrder_North sn
UNION ALL
SELECT
    ss.SalesOrderID,
    ss.OrderDate,
    ss.CustomerID,
    ss.TotalAmount,
    ss.Region
FROM Sales.SalesOrder_South ss;
GO
SELECT * FROM Sales.vExportSalesReport ORDER BY OrderDate;
GO

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



-- 2.2 WITH SCHEMABINDING
-- Привязывает представление к схеме базовых таблиц.
-- Запрещает изменение таблиц, если оно нарушит представление.
-- ОБЯЗАТЕЛЬНО для создания индексированного представления!
-- Требует двухчастных имён (schema.table).
CREATE VIEW Person.vStateProvinceCountryRegion
WITH SCHEMABINDING
AS
SELECT
    sp.[StateProvinceID],
    sp.[StateProvinceCode],
    sp.[Name]              AS [StateProvinceName],
    sp.[CountryRegionCode],
    cr.[Name]              AS [CountryRegionName]
FROM [Person].[StateProvince]  sp          -- двухчастное имя: схема.таблица
INNER JOIN [Person].[CountryRegion] cr
    ON cr.[CountryRegionCode] = sp.[CountryRegionCode];
GO
SELECT * FROM Person.vStateProvinceCountryRegion;
GO

-- Проверка защиты SCHEMABINDING: попытка удалить столбец
BEGIN TRY
    ALTER TABLE Person.StateProvince DROP COLUMN StateProvinceCode;
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
    PRINT '→ SCHEMABINDING защищает базовые таблицы от разрушающих изменений.';
END CATCH
GO


-- 2.3 WITH VIEW_METADATA
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


-- 2.4 ORDER BY разрешён только совместно с TOP
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

-- Ограничения CREATE VIEW (нарушение вызовет ошибку):
-- НЕЛЬЗЯ: вложенность более 32 уровней
-- НЕЛЬЗЯ: более 1024 столбцов
-- НЕЛЬЗЯ: COMPUTE, COMPUTE BY
-- НЕЛЬЗЯ: ORDER BY без TOP
-- НЕЛЬЗЯ: INTO в подзапросе
-- НЕЛЬЗЯ: OPTION (query hint) в запросе
-- НЕЛЬЗЯ: TABLESAMPLE
-- НЕЛЬЗЯ: временные таблицы или временные представления
-- НЕЛЬЗЯ: связывать Rule/Default с представлением
-- НЕЛЬЗЯ: триггеры AFTER (только INSTEAD OF)



-- 2.5 ALTER VIEW — изменение представления
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


-- 2.6 DROP VIEW — удаление представления
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
PRINT 'Два представления удалены одним оператором DROP VIEW.';
GO


-- 2.7 ЦЕПОЧКИ ВЛАДЕНИЯ (OWNERSHIP CHAINS)
-- Когда представление и базовые таблицы имеют одного владельца,
-- SQL Server НЕ проверяет права пользователя на каждую базовую
-- таблицу — достаточно права на представление.
-- При РАЗРЫВЕ цепочки (разные владельцы) права проверяются.
-- Чтобы избежать разрыва: все объекты должны иметь одного владельца.


-- Схемы и их владельцы (все должны принадлежать dbo для непрерывной цепочки):
SELECT
    s.name  AS [Схема],
    dp.name AS [Владелец схемы]
FROM sys.schemas    s
INNER JOIN sys.database_principals dp ON dp.principal_id = s.principal_id
WHERE s.name IN ('HumanResources', 'Person', 'Sales');
GO

PRINT 'Объекты БД и их владельцы:';
SELECT
    s.name  AS [Схема],
    o.name  AS [Объект],
    o.type_desc,
    dp.name AS [Владелец]
FROM sys.objects o
INNER JOIN sys.schemas            s  ON s.schema_id   = o.schema_id
INNER JOIN sys.database_principals dp ON dp.principal_id = s.principal_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.type_desc, o.name;
GO

-- ДЕМОНСТРАЦИЯ ЦЕПОЧКИ ВЛАДЕНИЯ


-- Создаём тестового пользователя
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'chain_test_user')
    CREATE LOGIN [chain_test_user] WITH PASSWORD = 'P@ssw0rd_Lab5!';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'chain_test_user')
    CREATE USER [chain_test_user] FOR LOGIN [chain_test_user];
GO

-- -------------------------------------------------------
-- СЛУЧАЙ 1: НЕПРЕРЫВНАЯ цепочка владения
-- vEmployee (владелец: dbo) → Employee (владелец: dbo)
--                           → Contact  (владелец: dbo)
-- SQL Server НЕ проверяет права на базовые таблицы!
-- Достаточно права только на представление.
-- -------------------------------------------------------

GRANT SELECT ON HumanResources.vEmployee TO [chain_test_user];
-- Выдано право ТОЛЬКО на vEmployee. На Employee и Contact — НЕТ.
GO

EXECUTE AS USER = 'chain_test_user';
    PRINT 'Запрос к представлению vEmployee:';
    BEGIN TRY
        SELECT EmployeeID, FirstName, LastName, JobTitle
        FROM HumanResources.vEmployee;
        PRINT 'СРАБОТАЛО — SQL Server не проверял права на базовые таблицы!';
        PRINT 'Цепочка владения непрерывна: vEmployee→Employee→Contact (все dbo).';
    END TRY
    BEGIN CATCH
        PRINT 'ОШИБКА: ' + ERROR_MESSAGE();
    END CATCH

    PRINT '';
    PRINT 'Прямой запрос к базовой таблице Employee:';
    BEGIN TRY
        SELECT * FROM HumanResources.Employee;
        PRINT 'Доступ разрешён.';
    END TRY
    BEGIN CATCH
        PRINT 'ЗАПРЕЩЕНО (ожидаемо): ' + ERROR_MESSAGE();
        PRINT 'Права выданы только на представление — не на таблицу напрямую.';
    END CATCH
REVERT;
GO

REVOKE SELECT ON HumanResources.vEmployee FROM [chain_test_user];
GO

-- -------------------------------------------------------
-- СЛУЧАЙ 2: РАЗОРВАННАЯ цепочка владения
-- Создаём схему с другим владельцем и таблицу в ней.
-- Представление (dbo) → таблица (другой владелец)
-- SQL Server ПРОВЕРЯЕТ права пользователя на таблицу!
-- Без явного GRANT на таблицу — доступ будет ОТКЛОНЁН.
-- -------------------------------------------------------

-- Создаём второго пользователя — он станет владельцем схемы
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'schema_owner')
    CREATE LOGIN [schema_owner] WITH PASSWORD = 'P@ssw0rd_Lab5!';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'schema_owner')
    CREATE USER [schema_owner] FOR LOGIN [schema_owner];
GO

-- Создаём схему с владельцем schema_owner (не dbo!)
CREATE SCHEMA [OtherOwner] AUTHORIZATION [schema_owner];
GO

-- Таблица принадлежит schema_owner через схему OtherOwner
CREATE TABLE [OtherOwner].[SecretData] (
    ID    INT          NOT NULL PRIMARY KEY,
    Info  NVARCHAR(50) NOT NULL
);
GO

INSERT INTO [OtherOwner].[SecretData] VALUES (1, N'Секретные данные');
GO

-- Представление принадлежит dbo (через схему HumanResources)
CREATE VIEW HumanResources.vBrokenChain
AS
SELECT ID, Info
FROM [OtherOwner].[SecretData];  -- ДРУГОЙ владелец → цепочка РАЗОРВАНА
GO

GRANT SELECT ON HumanResources.vBrokenChain TO [chain_test_user];
-- Выдано право на представление vBrokenChain.
-- !!! НО: представление (dbo) → таблица (schema_owner) — цепочка РАЗОРВАНА!
GO

EXECUTE AS USER = 'chain_test_user';
    PRINT 'Запрос к представлению с разорванной цепочкой:';
    BEGIN TRY
        SELECT * FROM HumanResources.vBrokenChain;
        PRINT '✓ Сработало.';
    END TRY
    BEGIN CATCH
        PRINT '✗ ЗАПРЕЩЕНО (ожидаемо): ' + ERROR_MESSAGE();
        PRINT '  Цепочка разорвана → SQL Server проверил права на SecretData → отказал!';
    END CATCH
REVERT;
GO

-- Теперь выдаём явное право на таблицу — разрыв компенсирован
GRANT SELECT ON [OtherOwner].[SecretData] TO [chain_test_user];
GO

EXECUTE AS USER = 'chain_test_user';
    BEGIN TRY
        SELECT * FROM HumanResources.vBrokenChain;
        PRINT '✓ Теперь работает — права на таблицу выданы явно.';
    END TRY
    BEGIN CATCH
        PRINT '✗ ОШИБКА: ' + ERROR_MESSAGE();
    END CATCH
REVERT;
GO

-- -------------------------------------------------------
-- !!! чтобы избежать разрыва — все объекты одному владельцу
-- -------------------------------------------------------
-- Непрерывная цепочка (один владелец) → достаточно права на представление.';
-- Разорванная цепочка (разные владельцы) → нужны явные права на каждый объект.';
-- Рекомендация: держать все связанные объекты под одним владельцем (dbo).';


-- Очистка
REVOKE SELECT ON HumanResources.vBrokenChain    FROM [chain_test_user];
REVOKE SELECT ON [OtherOwner].[SecretData]       FROM [chain_test_user];
DROP VIEW  HumanResources.vBrokenChain;
DROP TABLE [OtherOwner].[SecretData];
DROP SCHEMA [OtherOwner];
DROP USER  [chain_test_user];
DROP LOGIN [chain_test_user];
DROP USER  [schema_owner];
DROP LOGIN [schema_owner];
GO


-- 2.8 ИСТОЧНИКИ ИНФОРМАЦИИ О ПРЕДСТАВЛЕНИЯХ


-- ИСТОЧНИК 1: sys.views — список всех представлений
USE [T-SQL_lab_5_views];
GO
SELECT
    s.name       AS [Схема],
    v.name       AS [Имя представления],
    v.object_id,
    v.create_date,
    v.modify_date,
    OBJECTPROPERTY(v.object_id, 'IsIndexed')    AS [Индексировано],
    OBJECTPROPERTY(v.object_id, 'IsSchemaBound') AS [SchemaBound]
FROM sys.views   v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
ORDER BY s.name, v.name;
GO

-- ИСТОЧНИК 2: sp_helptext — текст незашифрованного представления
EXEC sp_helptext 'HumanResources.vEmployeeNames';
GO

-- ИСТОЧНИК 3: sys.sql_expression_dependencies — зависимости объектов
-- (sys.sql_dependencies — устаревший вариант из SQL Server 2005)
-- объекты, зависящие от таблицы Employee:
SELECT
    OBJECT_NAME(referencing_id) AS [Зависимый объект],
    referenced_schema_name      AS [Схема объекта],
    referenced_entity_name      AS [Исходный объект]
FROM sys.sql_expression_dependencies
WHERE referenced_entity_name = 'Employee'
  AND referenced_schema_name = 'HumanResources';
GO

-- ИСТОЧНИК 4: sys.sql_dependencies
SELECT DISTINCT
    OBJECT_NAME(object_id) AS [Зависимый объект]
FROM sys.sql_dependencies
WHERE referenced_major_id = OBJECT_ID(N'HumanResources.Employee');
GO



-- 2.9 ШИФРОВАНИЕ ПРЕДСТАВЛЕНИЯ — WITH ENCRYPTION
-- Текст определения сохраняется в sys.syscomments.
-- WITH ENCRYPTION шифрует этот текст → никто не сможет его прочитать.
-- ВАЖНО: сохранить копию CREATE VIEW перед шифрованием!

-- Создаём зашифрованное представление
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

-- sp_helptext вернёт ОШИБКУ для зашифрованного представления
-- Попытка прочитать зашифрованное представление через sp_helptext:
BEGIN TRY
    EXEC sp_helptext 'HumanResources.vSalarySensitive';
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
    PRINT '→ Определение зашифровано. Доступ к тексту невозможен.';
END CATCH
GO

-- !!! при ALTER VIEW нужно снова указывать WITH ENCRYPTION,
-- иначе шифрование будет снято!

-- ALTER VIEW зашифрованного представления (WITH ENCRYPTION сохраняем):
ALTER VIEW [HumanResources].[vSalarySensitive]
WITH ENCRYPTION
AS
SELECT
    e.EmployeeID,
    c.FirstName + N' ' + c.LastName AS EmployeeName,
    e.Salary,
    e.HireDate,
    e.JobTitle          -- добавлен новый столбец
FROM [HumanResources].[Employee] e
INNER JOIN [Person].[Contact]    c ON c.[ContactID] = e.[ContactID];
GO
SELECT * FROM HumanResources.vSalarySensitive;
GO


-- 2.10 ИЗМЕНЕНИЕ ДАННЫХ ЧЕРЕЗ ПРЕДСТАВЛЕНИЕ
-- INSERT / UPDATE / DELETE
--
-- Ограничения:
--  • Только одна базовая таблица в одном операторе
--  • Нельзя изменять вычисляемые столбцы и агрегаты
--  • Нельзя изменять столбцы, задействованные в GROUP BY/HAVING/DISTINCT


-- Создаём "обновляемое" представление на одну таблицу
CREATE VIEW Sales.vSalesNorthModify
AS
SELECT
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalAmount
FROM Sales.SalesOrder_North;
GO

-- INSERT через представление
-- Данные ДО INSERT через представление:
SELECT * FROM Sales.vSalesNorthModify;

INSERT INTO Sales.vSalesNorthModify (SalesOrderID, OrderDate, CustomerID, TotalAmount)
VALUES (10, '2024-04-01', 110, 50000.00);

-- Данные ПОСЛЕ INSERT через представление:
SELECT * FROM Sales.vSalesNorthModify;
GO

-- UPDATE через представление
-- (изменение суммы заказа):
UPDATE Sales.vSalesNorthModify
SET TotalAmount = 55000.00
WHERE SalesOrderID = 10;

SELECT SalesOrderID, TotalAmount FROM Sales.vSalesNorthModify WHERE SalesOrderID = 10;
GO

-- DELETE через представление
DELETE FROM Sales.vSalesNorthModify WHERE SalesOrderID = 10;

-- После DELETE:
SELECT * FROM Sales.vSalesNorthModify;
GO

-- Попытка UPDATE через многотабличное представление — ошибка
-- (vEmployee):
BEGIN TRY
    UPDATE HumanResources.vEmployee
    SET FirstName = N'Тест'
    WHERE EmployeeID = 1;
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
    PRINT '→ Нельзя изменять данные через представление, затрагивающее несколько таблиц.';
END CATCH
GO

-- Попытка UPDATE агрегированного столбца — ошибка
-- (vDepartmentSalaryStats):
BEGIN TRY
    UPDATE HumanResources.vDepartmentSalaryStats
    SET AvgSalary = 100000
    WHERE DepartmentName = N'Разработка';
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
    PRINT '→ Нельзя изменять столбцы, полученные из агрегатных функций.';
END CATCH
GO


-- 2.11 WITH CHECK OPTION
-- Все операторы модификации должны соответствовать критерию WHERE
-- представления. Если строка после изменения «выпадет» из представления
-- — операция будет ОТМЕНЕНА с ошибкой.

CREATE VIEW HumanResources.vDept1Employees
AS
SELECT
    e.EmployeeID,
    c.FirstName,
    c.LastName,
    e.DepartmentID,
    e.Salary
FROM HumanResources.Employee e
INNER JOIN Person.Contact    c ON c.ContactID = e.ContactID
WHERE e.DepartmentID = 1        -- только отдел Разработки
WITH CHECK OPTION;
GO

-- Текущие данные (только DepartmentID = 1):
SELECT * FROM HumanResources.vDept1Employees;
GO

-- Разрешённый UPDATE (строка остаётся в представлении)
-- изменяем Salary (DepartmentID не меняется):
UPDATE HumanResources.vDept1Employees
SET Salary = 92000.00
WHERE EmployeeID = 1;
SELECT EmployeeID, Salary FROM HumanResources.vDept1Employees;
GO

-- Запрещённый UPDATE (строка исчезнет из представления → CHECK OPTION отклоняет)
-- попытка сменить DepartmentID через представление:
BEGIN TRY
    UPDATE HumanResources.vDept1Employees
    SET DepartmentID = 2           -- строка уйдёт из представления
    WHERE EmployeeID = 1;
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА (ожидаемо): ' + ERROR_MESSAGE();
    PRINT '→ WITH CHECK OPTION не позволяет изменить строку так, чтобы она исчезла из представления.';
END CATCH
GO




-- 3.1 ОСНОВНЫЕ СВЕДЕНИЯ О ПРОИЗВОДИТЕЛЬНОСТИ
-- Стандартное представление: SQL Server каждый раз выполняет SELECT.
-- Вложенные представления увеличивают издержки.
-- Для анализа вложенных зашифрованных представлений — SQL Server Profiler.

-- 'Вложенность: vMoscowEmployees → vEmployee → (Employee + Contact + ... 6 таблиц)'
-- 'Каждый SELECT к vMoscowEmployees выполняет полный цепочечный JOIN:'
SELECT * FROM HumanResources.vMoscowEmployees;
GO

-- Определяем глубину вложенности
SELECT
    referencing_obj.name AS [Представление],
    referenced_obj.name  AS [Зависит от],
    dep.is_caller_dependent
FROM sys.sql_expression_dependencies dep
INNER JOIN sys.objects referencing_obj ON referencing_obj.object_id = dep.referencing_id
INNER JOIN sys.objects referenced_obj  ON referenced_obj.object_id  = dep.referenced_id
WHERE referencing_obj.type = 'V'
ORDER BY referencing_obj.name;
GO


-- 3.2 ИНДЕКСИРОВАННЫЕ ПРЕДСТАВЛЕНИЯ (INDEXED VIEWS)
-- Представление материализуется — данные хранятся физически
-- на страницах индекса листового уровня.
-- Требования:
--   • WITH SCHEMABINDING обязательно
--   • Первый индекс: UNIQUE CLUSTERED
--   • Нельзя ссылаться на другие представления
--   • Двухчастные имена таблиц
--   • Только детерминированные функции
--   • Таблицы в той же БД с тем же владельцем
-- Применять когда:
--   • Данные обновляются редко
--   • Много агрегаций и JOIN-ов
--   • Выигрыш в производительности > издержки на обслуживание

-- Обязательные параметры сессии для индексированных представлений
SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING        ON;
SET ANSI_WARNINGS       ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER   ON;
SET ANSI_NULLS          ON;
SET ARITHABORT          ON;
GO

-- Person.vStateProvinceCountryRegion уже создано с SCHEMABINDING (п. 2.2)
-- Создаём UNIQUE CLUSTERED INDEX — материализуем представление
-- (точно как в примере из методички)
CREATE UNIQUE CLUSTERED INDEX [IX_vStateProvinceCountryRegion]
ON [Person].[vStateProvinceCountryRegion]
(
    [StateProvinceID]   ASC,
    [CountryRegionCode] ASC
);
GO

-- 'Уникальный кластерный индекс IX_vStateProvinceCountryRegion создан!
-- 'Представление теперь МАТЕРИАЛИЗОВАНО — данные хранятся физически.
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

-- Проверка индексов на представлении
SELECT
    OBJECT_NAME(i.object_id) AS [Представление],
    i.name                   AS [Индекс],
    i.type_desc,
    i.is_unique
FROM sys.indexes i
INNER JOIN sys.views v ON v.object_id = i.object_id
WHERE i.type > 0;
GO

/*
'Когда использовать индексированные представления:'
Данные обновляются редко'
Запросы выполняют много JOIN и агрегаций'
Многие пользователи часто запрашивают одни и те же данные'
Не подходит: таблицы часто обновляются (издержки на поддержание индекса)'
*/

-- 3.3 СЕКЦИОНИРОВАННЫЕ ПРЕДСТАВЛЕНИЯ (PARTITIONED VIEWS)
-- Объединяет горизонтально разделённые данные из нескольких
-- таблиц через UNION ALL → выглядит как одна таблица.
--
-- Типы:
--   • Локальное  — все таблицы на одном экземпляре SQL Server
--                 (в SQL Server 2005+ только для совместимости;
--                  предпочтительнее — секционированные таблицы)
--   • Распределённое — таблицы на разных серверах (федерация серверов)

-- Локальное секционированное представление
-- Sales.SalesOrder_North и Sales.SalesOrder_South — горизонтальные секции
-- CHECK CONSTRAINT на Region позволяет оптимизатору «знать», в какой
-- таблице искать данные при фильтрации по Region.
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
-- Запрос только по Region = North (оптимизатор читает только SalesOrder_North):
SELECT * FROM Sales.vSalesPartitioned WHERE Region = 'North';
GO

-- Запрос только по Region = South (оптимизатор читает только SalesOrder_South):
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




-- ИТОГ ПО ВСЕМ СОЗДАННЫМ ПРЕДСТАВЛЕНИЯМ



SELECT
    s.name                          AS [Схема],
    v.name                          AS [Представление],
    CASE
        WHEN OBJECTPROPERTY(v.object_id, 'IsIndexed')    = 1 THEN N'Индексированное'
        WHEN OBJECTPROPERTY(v.object_id, 'IsSchemaBound')= 1 THEN N'С привязкой схемы'
        ELSE N'Стандартное'
    END                             AS [Тип],
    OBJECTPROPERTY(v.object_id, 'IsEncrypted')  AS [Зашифровано],
    v.create_date                   AS [Дата создания]
FROM sys.views   v
INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
ORDER BY s.name, v.name;
GO
