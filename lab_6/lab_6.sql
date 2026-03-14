
--  СОЗДАНИЕ БД
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'T-SQL_lab_6_integrity')
BEGIN
    ALTER DATABASE [T-SQL_lab_6_integrity] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [T-SQL_lab_6_integrity];
END
GO

CREATE DATABASE [T-SQL_lab_6_integrity];
GO

USE [T-SQL_lab_6_integrity];
GO



--  СХЕМЫ
CREATE SCHEMA HumanResources;
GO
CREATE SCHEMA Production;
GO
CREATE SCHEMA Sales;
GO

--  PRIMARY KEY
--  Уникально идентифицирует каждую строку (целостность сущности).
--  Одна таблица — одно ограничение PRIMARY KEY.
--  NULL не допускается. Автоматически создаёт уникальный индекс.
--  По умолчанию — кластерный. Удалить индекс нельзя, пока живёт PK.

-- таблица БЕЗ PK
CREATE TABLE HumanResources.TestPK (
    ID   INT          NOT NULL,
    Name NVARCHAR(50) NOT NULL
);
GO

-- PRIMARY KEY
ALTER TABLE HumanResources.TestPK
ADD CONSTRAINT [PK_TestPK] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

-- вставки проходят
INSERT INTO HumanResources.TestPK VALUES (1, N'Первый');
INSERT INTO HumanResources.TestPK VALUES (2, N'Второй');

-- дублирующийся ID
BEGIN TRY
    INSERT INTO HumanResources.TestPK VALUES (1, N'Дубликат ID=1');
END TRY
BEGIN CATCH
    PRINT 'PRIMARY KEY: дубликат отклонён — ' + ERROR_MESSAGE();
END CATCH

-- NULL в ключевом столбце
BEGIN TRY
    INSERT INTO HumanResources.TestPK VALUES (NULL, N'NULL в PK');
END TRY
BEGIN CATCH
    PRINT 'PRIMARY KEY: NULL не допускается — ' + ERROR_MESSAGE();
END CATCH

-- Очистка
DROP TABLE HumanResources.TestPK;
GO

--  DEFAULT
--  Вставляет значение, если в INSERT оно не указано.



CREATE TABLE HumanResources.Employee (
    EmployeeID       INT           NOT NULL IDENTITY(1,1),
    NationalIDNumber NVARCHAR(15)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    JobTitle         NVARCHAR(50)  NOT NULL,
    HireDate         DATE          NOT NULL,
    Salary           DECIMAL(10,2) NOT NULL,
    DepartmentID     SMALLINT      NULL,
    IsActive         BIT           NOT NULL,
    ModifiedDate     DATETIME      NOT NULL,
    CONSTRAINT [PK_Employee_EmployeeID] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

CREATE TABLE Production.Product (
    ProductID    INT           NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL,
    ModifiedDate DATETIME      NOT NULL,
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

-- DEFAULT-ограничения
ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [DF_Employee_IsActive]     DEFAULT (1)        FOR [IsActive];

ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [DF_Employee_ModifiedDate] DEFAULT (GETDATE()) FOR [ModifiedDate];

ALTER TABLE Production.Product
ADD CONSTRAINT [DF_Product_ModifiedDate]  DEFAULT (GETDATE()) FOR [ModifiedDate];
GO

INSERT INTO HumanResources.Employee
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID, ModifiedDate)
VALUES
    ('777888999', N'Тест', N'Дефолт', N'Тестировщик', '2024-01-01', 60000, 1, DEFAULT);

SELECT 'Тестовый сотрудник с DEFAULT-значениями:' AS Info;
SELECT EmployeeID, FirstName, IsActive, ModifiedDate
FROM HumanResources.Employee
WHERE NationalIDNumber = '777888999';
GO

DELETE FROM HumanResources.Employee WHERE NationalIDNumber = '777888999';
GO

-- Очистка
DROP TABLE HumanResources.Employee;
DROP TABLE Production.Product;
GO

--  CHECK
--  Ограничивает значения при INSERT и UPDATE.

-- таблицы
CREATE TABLE HumanResources.Employee (
    EmployeeID       INT           NOT NULL IDENTITY(1,1),
    NationalIDNumber NVARCHAR(15)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    JobTitle         NVARCHAR(50)  NOT NULL,
    HireDate         DATE          NOT NULL,
    Salary           DECIMAL(10,2) NOT NULL,
    DepartmentID     SMALLINT      NULL,
    IsActive         BIT           NOT NULL DEFAULT (1),
    ModifiedDate     DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Employee_EmployeeID] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

CREATE TABLE Production.Product (
    ProductID    INT           NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL,
    ModifiedDate DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

CREATE TABLE HumanResources.EmployeeDepartmentHistory (
    EmployeeID   INT      NOT NULL,
    DepartmentID SMALLINT NOT NULL,
    StartDate    DATE     NOT NULL,
    EndDate      DATE     NULL,
    CONSTRAINT [PK_EmpDeptHist] PRIMARY KEY ([EmployeeID], [DepartmentID], [StartDate])
);
GO

-- тестовые данные
INSERT INTO HumanResources.Employee 
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID)
VALUES 
    ('123456789', N'Иван', N'Иванов', N'Разработчик', '2020-01-15', 85000, 1);

-- CHECK: зарплата >= 0
ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [CK_Employee_Salary] CHECK ([Salary] >= 0);

-- CHECK на продукты
ALTER TABLE Production.Product
ADD CONSTRAINT [CK_Product_Price]    CHECK ([Price]    >= 0);
ALTER TABLE Production.Product
ADD CONSTRAINT [CK_Product_StockQty] CHECK ([StockQty] >= 0);

-- CHECK: EndDate >= StartDate
ALTER TABLE [HumanResources].[EmployeeDepartmentHistory]
WITH CHECK
ADD CONSTRAINT [CK_EmpDeptHist_EndDate]
CHECK (([EndDate] >= [StartDate] OR [EndDate] IS NULL));
GO

-- отрицательная зарплата отклоняется
BEGIN TRY
    INSERT INTO HumanResources.Employee
        (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID)
    VALUES ('000000001', N'Тест', N'Чек', N'Стажёр', '2024-01-01', -100, 1);
END TRY
BEGIN CATCH
    PRINT 'CHECK (Salary >= 0): отрицательная зарплата отклонена — ' + ERROR_MESSAGE();
END CATCH
GO

-- корректная запись в историю (EndDate = NULL)
INSERT INTO HumanResources.EmployeeDepartmentHistory VALUES (1, 1, '2024-06-01', NULL);
PRINT 'Корректная запись с EndDate=NULL добавлена';
GO

-- EndDate раньше StartDate — отклоняется
BEGIN TRY
    INSERT INTO HumanResources.EmployeeDepartmentHistory
    VALUES (1, 1, '2024-06-01', '2024-05-01');
END TRY
BEGIN CATCH
    PRINT 'CHECK (EndDate >= StartDate): неверный диапазон дат отклонён — ' + ERROR_MESSAGE();
END CATCH
GO


-- Очистка
DROP TABLE HumanResources.EmployeeDepartmentHistory;
DROP TABLE HumanResources.Employee;
DROP TABLE Production.Product;
GO

--  UNIQUE
--  Запрещает дублирование (целостность сущности для не-PK столбцов).
--  Таблица может иметь много UNIQUE, но только один PRIMARY KEY.
--  Допускает одно NULL-значение.


CREATE TABLE HumanResources.Employee (
    EmployeeID       INT           NOT NULL IDENTITY(1,1),
    NationalIDNumber NVARCHAR(15)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    JobTitle         NVARCHAR(50)  NOT NULL,
    HireDate         DATE          NOT NULL,
    Salary           DECIMAL(10,2) NOT NULL,
    DepartmentID     SMALLINT      NULL,
    IsActive         BIT           NOT NULL DEFAULT (1),
    ModifiedDate     DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Employee_EmployeeID] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

-- тестовые данные
INSERT INTO HumanResources.Employee 
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID)
VALUES 
    ('123456789', N'Иван', N'Иванов', N'Разработчик', '2020-01-15', 85000, 1);

-- UNIQUE на NationalIDNumber
ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [UQ_Employee_NationalIDNumber] UNIQUE NONCLUSTERED ([NationalIDNumber]);
GO

-- дублирующийся ИНН отклоняется
BEGIN TRY
    INSERT INTO HumanResources.Employee
        (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID)
    VALUES ('123456789', N'Двойник', N'Иванова', N'Разработчик', '2024-01-01', 70000, 1);
END TRY
BEGIN CATCH
    PRINT 'UNIQUE (NationalIDNumber): дублирующийся ИНН отклонён — ' + ERROR_MESSAGE();
END CATCH
GO

-- добавление составного UNIQUE
ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [UQ_Employee_FullName] UNIQUE NONCLUSTERED ([FirstName], [LastName]);
GO


-- Очистка
DROP TABLE HumanResources.Employee;
GO

--  FOREIGN KEY
--  Устанавливает связь между таблицами (ссылочная целостность).
--  Ссылается на PRIMARY KEY или UNIQUE другой (или той же) таблицы.
--  Не создаёт индекс автоматически.
--  Число столбцов и типы в FK должны соответствовать REFERENCES.


-- таблицы для FOREIGN KEY
CREATE TABLE HumanResources.Department (
    DepartmentID SMALLINT     NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50) NOT NULL,
    GroupName    NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME     NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Department_DepartmentID] PRIMARY KEY CLUSTERED ([DepartmentID] ASC)
);
GO

CREATE TABLE HumanResources.Employee (
    EmployeeID       INT           NOT NULL IDENTITY(1,1),
    NationalIDNumber NVARCHAR(15)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    JobTitle         NVARCHAR(50)  NOT NULL,
    HireDate         DATE          NOT NULL,
    Salary           DECIMAL(10,2) NOT NULL,
    DepartmentID     SMALLINT      NULL,
    IsActive         BIT           NOT NULL DEFAULT (1),
    ModifiedDate     DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Employee_EmployeeID] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

CREATE TABLE HumanResources.EmployeeDepartmentHistory (
    EmployeeID   INT      NOT NULL,
    DepartmentID SMALLINT NOT NULL,
    StartDate    DATE     NOT NULL,
    EndDate      DATE     NULL,
    CONSTRAINT [PK_EmpDeptHist] PRIMARY KEY ([EmployeeID], [DepartmentID], [StartDate])
);
GO

-- тестовые данные
INSERT INTO HumanResources.Department (Name, GroupName) VALUES
(N'Разработка',   N'Технологии'),
(N'Маркетинг',    N'Продажи и Маркетинг');

INSERT INTO HumanResources.Employee 
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID)
VALUES 
    ('123456789', N'Иван', N'Иванов', N'Разработчик', '2020-01-15', 85000, 1);

-- FK: Employee → Department
ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [FK_Employee_Department] FOREIGN KEY ([DepartmentID])
    REFERENCES [HumanResources].[Department] ([DepartmentID]);

-- FK: EmployeeDepartmentHistory → Employee и Department
ALTER TABLE HumanResources.EmployeeDepartmentHistory
ADD CONSTRAINT [FK_EmpDeptHist_Employee] FOREIGN KEY ([EmployeeID])
    REFERENCES [HumanResources].[Employee] ([EmployeeID]);

ALTER TABLE HumanResources.EmployeeDepartmentHistory
ADD CONSTRAINT [FK_EmpDeptHist_Department] FOREIGN KEY ([DepartmentID])
    REFERENCES [HumanResources].[Department] ([DepartmentID]);
GO

-- нельзя вставить сотрудника с несуществующим DepartmentID
BEGIN TRY
    INSERT INTO HumanResources.Employee
        (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID)
    VALUES ('999000111', N'Тест', N'ФК', N'Призрак', '2024-01-01', 50000, 99);
END TRY
BEGIN CATCH
    PRINT 'FOREIGN KEY: несуществующий DepartmentID=99 отклонён — ' + ERROR_MESSAGE();
END CATCH
GO

-- : нельзя удалить отдел, пока в нём есть сотрудники
BEGIN TRY
    DELETE FROM HumanResources.Department WHERE DepartmentID = 1;
END TRY
BEGIN CATCH
    PRINT 'FOREIGN KEY (NO ACTION): удаление отдела с сотрудниками отклонено — ' + ERROR_MESSAGE();
END CATCH
GO

-- Очистка
DROP TABLE HumanResources.EmployeeDepartmentHistory;
DROP TABLE HumanResources.Employee;
DROP TABLE HumanResources.Department;
GO

--  ON DELETE CASCADE
--  CASCADE — UPDATE: обновить FK; DELETE: удалить зависимые строки


-- таблицы
CREATE TABLE Sales.Customer (
    CustomerID  INT          NOT NULL IDENTITY(1,1),
    CompanyName NVARCHAR(50) NOT NULL,
    ContactName NVARCHAR(50) NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY ([CustomerID])
);
GO

CREATE TABLE Sales.SalesOrderHeader (
    SalesOrderID INT           NOT NULL IDENTITY(1,1),
    CustomerID   INT           NOT NULL,
    OrderDate    DATE          NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL,
    Status       NVARCHAR(20)  NOT NULL DEFAULT ('Новый'),
    CONSTRAINT [PK_SalesOrder] PRIMARY KEY ([SalesOrderID])
);
GO

-- тестовые данные
SET IDENTITY_INSERT Sales.Customer ON;
INSERT INTO Sales.Customer (CustomerID, CompanyName, ContactName)
VALUES (1, N'ООО Рога и Копыта', N'Иванченко П.П.');
SET IDENTITY_INSERT Sales.Customer OFF;

INSERT INTO Sales.SalesOrderHeader (CustomerID, OrderDate, TotalAmount)
VALUES (1, '2024-01-10', 150000),
       (1, '2024-02-05', 75000);

-- FK с CASCADE
ALTER TABLE [Sales].[SalesOrderHeader]
ADD CONSTRAINT [FK_SalesOrderHeader_Customer] FOREIGN KEY ([CustomerID])
    REFERENCES [Sales].[Customer] ([CustomerID])
    ON DELETE CASCADE;
GO

SELECT 'Заказы ДО удаления заказчика CustomerID=1:' AS Info;
SELECT SalesOrderID, CustomerID, TotalAmount FROM Sales.SalesOrderHeader;

-- Удаляем заказчика, его заказы удаляются автоматически (CASCADE)
DELETE FROM Sales.Customer WHERE CustomerID = 1;

SELECT 'Заказы ПОСЛЕ удаления заказчика CustomerID=1:' AS Info;
SELECT SalesOrderID, CustomerID, TotalAmount FROM Sales.SalesOrderHeader;
GO

-- Очистка
DROP TABLE Sales.SalesOrderHeader;
DROP TABLE Sales.Customer;
GO

--  ON DELETE SET NULL
--  SET NULL — FK становится NULL (столбец должен допускать NULL)

-- тестовые таблицы
CREATE TABLE HumanResources.TestParent (
    ParentID INT NOT NULL,
    Name     NVARCHAR(30) NOT NULL,
    CONSTRAINT [PK_TestParent] PRIMARY KEY ([ParentID])
);
GO

CREATE TABLE HumanResources.TestChild (
    ChildID  INT NOT NULL,
    ParentID INT NULL,      -- NULL обязателен для SET NULL
    CONSTRAINT [PK_TestChild] PRIMARY KEY ([ChildID]),
    CONSTRAINT [FK_TestChild_Parent] FOREIGN KEY ([ParentID])
        REFERENCES [HumanResources].[TestParent] ([ParentID])
        ON DELETE SET NULL
);
GO

INSERT INTO HumanResources.TestParent VALUES (1, N'Родитель');
INSERT INTO HumanResources.TestChild VALUES (1, 1), (2, 1);

SELECT 'TestChild ДО DELETE SET NULL:' AS Info;
SELECT * FROM HumanResources.TestChild;

-- Удаляем родителя, FK в дочерних строках становится NULL
DELETE FROM HumanResources.TestParent WHERE ParentID = 1;

SELECT 'TestChild ПОСЛЕ DELETE SET NULL (ParentID = NULL):' AS Info;
SELECT * FROM HumanResources.TestChild;

-- Очистка
DROP TABLE HumanResources.TestChild;
DROP TABLE HumanResources.TestParent;
GO

--  ON DELETE SET DEFAULT
--  SET DEFAULT — FK = DEFAULT (DEFAULT должен быть задан)


-- тестовые таблицы
CREATE TABLE HumanResources.TestParent2 (
    ParentID INT NOT NULL,
    Name     NVARCHAR(30) NOT NULL,
    CONSTRAINT [PK_TestParent2] PRIMARY KEY ([ParentID])
);
GO

CREATE TABLE HumanResources.TestChild2 (
    ChildID  INT NOT NULL,
    ParentID INT NOT NULL CONSTRAINT [DF_TestChild2_ParentID] DEFAULT (0),
    CONSTRAINT [PK_TestChild2] PRIMARY KEY ([ChildID]),
    CONSTRAINT [FK_TestChild2_Parent] FOREIGN KEY ([ParentID])
        REFERENCES [HumanResources].[TestParent2] ([ParentID])
        ON DELETE SET DEFAULT
);
GO

-- Строка с ParentID=0 должна существовать в родительской таблице!
INSERT INTO HumanResources.TestParent2 VALUES (0, N'Неизвестный'), (1, N'Родитель');
INSERT INTO HumanResources.TestChild2 (ChildID, ParentID) VALUES (1, 1), (2, 1);

SELECT 'TestChild2 ДО DELETE SET DEFAULT:' AS Info;
SELECT * FROM HumanResources.TestChild2;

-- Удаляем родителя, FK принимает значение DEFAULT = 0
DELETE FROM HumanResources.TestParent2 WHERE ParentID = 1;

SELECT 'TestChild2 ПОСЛЕ DELETE SET DEFAULT (ParentID = 0):' AS Info;
SELECT * FROM HumanResources.TestChild2;

-- Очистка
DROP TABLE HumanResources.TestChild2;
DROP TABLE HumanResources.TestParent2;
GO


--  ОТКЛЮЧЕНИЕ ОГРАНИЧЕНИЙ
--  Можно отключить только CHECK и FOREIGN KEY.
--  NOCHECK CONSTRAINT — временно отключить

-- таблицы
CREATE TABLE Sales.Customer (
    CustomerID  INT          NOT NULL IDENTITY(1,1),
    CompanyName NVARCHAR(50) NOT NULL,
    ContactName NVARCHAR(50) NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY ([CustomerID])
);
GO

CREATE TABLE Sales.SalesOrderHeader (
    SalesOrderID INT           NOT NULL IDENTITY(1,1),
    CustomerID   INT           NOT NULL,
    OrderDate    DATE          NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL,
    Status       NVARCHAR(20)  NOT NULL DEFAULT ('Новый'),
    CONSTRAINT [PK_SalesOrder] PRIMARY KEY ([SalesOrderID])
);
GO

-- тестовые данные
INSERT INTO Sales.Customer (CompanyName) VALUES (N'Тестовый клиент');

-- FK с проверкой
ALTER TABLE [Sales].[SalesOrderHeader]
ADD CONSTRAINT [FK_SalesOrder_Customer]
    FOREIGN KEY ([CustomerID])
    REFERENCES [Sales].[Customer] ([CustomerID]);
GO

-- отключаем FK
ALTER TABLE [Sales].[SalesOrderHeader]
NOCHECK CONSTRAINT [FK_SalesOrder_Customer];
GO

-- с отключённым FK вставляем «осиротевший» заказ
INSERT INTO Sales.SalesOrderHeader (CustomerID, OrderDate, TotalAmount)
VALUES (9999, '2024-03-01', 1000);

SELECT 'Заказ с несуществующим CustomerID=9999 вставлен (FK отключён):' AS Info;
SELECT SalesOrderID, CustomerID FROM Sales.SalesOrderHeader WHERE CustomerID = 9999;
GO

-- FK обратно
ALTER TABLE [Sales].[SalesOrderHeader]
CHECK CONSTRAINT [FK_SalesOrder_Customer];
GO

-- Проверяем информацию об ограничениях
EXEC sp_helpconstraint 'Sales.SalesOrderHeader';
GO

-- Очистка
DROP TABLE Sales.SalesOrderHeader;
DROP TABLE Sales.Customer;
GO

--  ТРИГГЕР AFTER INSERT
--  Срабатывает после INSERT.

-- таблицы
CREATE TABLE Production.Product (
    ProductID    INT           NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL,
    ModifiedDate DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

CREATE TABLE Production.ProductChangeLog (
    LogID      INT           NOT NULL IDENTITY(1,1),
    ProductID  INT           NOT NULL,
    ChangeType NVARCHAR(10)  NOT NULL,
    ChangedAt  DATETIME      NOT NULL DEFAULT (GETDATE()),
    OldPrice   DECIMAL(10,2) NULL,
    NewPrice   DECIMAL(10,2) NULL,
    CONSTRAINT [PK_ProductChangeLog] PRIMARY KEY ([LogID])
);
GO

-- триггер AFTER INSERT
CREATE TRIGGER [Production].[trg_Product_AfterInsert]
ON [Production].[Product]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [Production].[ProductChangeLog] ([ProductID], [ChangeType], [NewPrice])
    SELECT [ProductID], 'INSERT', [Price]
    FROM inserted;
END;
GO

-- вставляем продукт, триггер пишет запись в лог
INSERT INTO Production.Product (Name, Price, StockQty)
VALUES (N'Мышь', 1500, 200);

SELECT 'Лог ПОСЛЕ INSERT продукта:' AS Info;
SELECT * FROM Production.ProductChangeLog;
GO

-- Очистка
DROP TABLE Production.ProductChangeLog;
DROP TABLE Production.Product;
GO

--  ТРИГГЕР AFTER DELETE
--  Срабатывает после DELETE.

-- таблицы
CREATE TABLE Production.Product (
    ProductID    INT           NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL,
    ModifiedDate DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

CREATE TABLE Production.ProductChangeLog (
    LogID      INT           NOT NULL IDENTITY(1,1),
    ProductID  INT           NOT NULL,
    ChangeType NVARCHAR(10)  NOT NULL,
    ChangedAt  DATETIME      NOT NULL DEFAULT (GETDATE()),
    OldPrice   DECIMAL(10,2) NULL,
    NewPrice   DECIMAL(10,2) NULL,
    CONSTRAINT [PK_ProductChangeLog] PRIMARY KEY ([LogID])
);
GO

-- тестовые данные
INSERT INTO Production.Product (Name, Price, StockQty)
VALUES (N'Мышь', 1500, 200);

-- триггер AFTER DELETE
CREATE TRIGGER [Production].[trg_Product_AfterDelete]
ON [Production].[Product]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [Production].[ProductChangeLog] ([ProductID], [ChangeType], [OldPrice])
    SELECT [ProductID], 'DELETE', [Price]
    FROM deleted;
END;
GO

-- удаляем продукт, триггер логирует удаление
DELETE FROM Production.Product WHERE Name = N'Мышь';

SELECT 'Лог ПОСЛЕ DELETE продукта:' AS Info;
SELECT * FROM Production.ProductChangeLog;
GO

-- Очистка
DROP TABLE Production.ProductChangeLog;
DROP TABLE Production.Product;
GO


--  ТРИГГЕР AFTER UPDATE
--  Срабатывает после UPDATE.


-- таблицы
CREATE TABLE Production.Product (
    ProductID    INT           NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL,
    ModifiedDate DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

CREATE TABLE Production.ProductChangeLog (
    LogID      INT           NOT NULL IDENTITY(1,1),
    ProductID  INT           NOT NULL,
    ChangeType NVARCHAR(10)  NOT NULL,
    ChangedAt  DATETIME      NOT NULL DEFAULT (GETDATE()),
    OldPrice   DECIMAL(10,2) NULL,
    NewPrice   DECIMAL(10,2) NULL,
    CONSTRAINT [PK_ProductChangeLog] PRIMARY KEY ([LogID])
);
GO

-- тестовые данные
INSERT INTO Production.Product (Name, Price, StockQty)
VALUES (N'Ноутбук', 75000, 15);

-- триггер AFTER UPDATE
CREATE TRIGGER [Production].[trg_Product_AfterUpdate]
ON [Production].[Product]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- автоматически обновляем ModifiedDate
    UPDATE [Production].[Product]
    SET [ModifiedDate] = GETDATE()
    FROM inserted
    WHERE inserted.[ProductID] = [Production].[Product].[ProductID];

    -- если обновлялась цена — пишем в лог
    IF UPDATE(Price)
    BEGIN
        INSERT INTO [Production].[ProductChangeLog]
            ([ProductID], [ChangeType], [OldPrice], [NewPrice])
        SELECT
            i.[ProductID],
            'UPDATE',
            d.[Price],
            i.[Price]
        FROM inserted i
        INNER JOIN deleted d ON d.[ProductID] = i.[ProductID];
    END
END;
GO

-- данные ДО
SELECT 'Ноутбук ДО UPDATE:' AS Info;
SELECT ProductID, Name, Price, ModifiedDate FROM Production.Product WHERE Name = N'Ноутбук';

-- обновляем цену
UPDATE Production.Product SET Price = 79000 WHERE Name = N'Ноутбук';

-- данные ПОСЛЕ
SELECT 'Ноутбук ПОСЛЕ UPDATE:' AS Info;
SELECT ProductID, Name, Price, ModifiedDate FROM Production.Product WHERE Name = N'Ноутбук';

-- лог
SELECT 'Лог ПОСЛЕ UPDATE цены:' AS Info;
SELECT * FROM Production.ProductChangeLog;
GO

-- Очистка
DROP TABLE Production.ProductChangeLog;
DROP TABLE Production.Product;
GO

--  ТРИГГЕР INSTEAD OF
--  Выполняется ВМЕСТО исходной операции.

-- таблица
CREATE TABLE HumanResources.Employee (
    EmployeeID       INT           NOT NULL IDENTITY(1,1),
    NationalIDNumber NVARCHAR(15)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    JobTitle         NVARCHAR(50)  NOT NULL,
    HireDate         DATE          NOT NULL,
    Salary           DECIMAL(10,2) NOT NULL,
    DepartmentID     SMALLINT      NULL,
    IsActive         BIT           NOT NULL DEFAULT (1),
    ModifiedDate     DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Employee_EmployeeID] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

-- тестовые данные
INSERT INTO HumanResources.Employee 
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary)
VALUES 
    ('123456789', N'Иван', N'Иванов', N'Разработчик', '2020-01-15', 85000),
    ('987654321', N'Мария', N'Петрова', N'Менеджер', '2019-03-20', 72000);

-- триггер INSTEAD OF DELETE
CREATE TRIGGER [HumanResources].[trg_Employee_InsteadOfDelete]
ON [HumanResources].[Employee]
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted WHERE IsActive = 1)
    BEGIN
        RAISERROR(N'Нельзя удалять активных сотрудников. Сначала деактивируйте их (IsActive = 0).', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM [HumanResources].[Employee]
        WHERE [EmployeeID] IN (SELECT [EmployeeID] FROM deleted);
    END
END;
GO

-- попытка удалить активного сотрудника
BEGIN TRY
    DELETE FROM HumanResources.Employee WHERE EmployeeID = 1;
END TRY
BEGIN CATCH
    PRINT 'INSTEAD OF DELETE: ' + ERROR_MESSAGE();
END CATCH
GO

-- деактивируем - удаляем
UPDATE HumanResources.Employee SET IsActive = 0 WHERE EmployeeID = 2;
DELETE FROM HumanResources.Employee WHERE EmployeeID = 2;

SELECT 'Сотрудники ПОСЛЕ удаления деактивированного:' AS Info;
SELECT EmployeeID, FirstName, IsActive FROM HumanResources.Employee;
GO

-- Очистка
DROP TABLE HumanResources.Employee;
GO

--  ВЛОЖЕННЫЕ ТРИГГЕРЫ (NESTED TRIGGERS)
--  Триггер на таблице Product запускает триггер на таблице ProductChangeLog
--  @@NESTLEVEL показывает текущий уровень вложенности


-- таблицы
CREATE TABLE Production.Product (
    ProductID    INT           NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50)  NOT NULL,
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL,
    ModifiedDate DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

CREATE TABLE Production.ProductChangeLog (
    LogID      INT           NOT NULL IDENTITY(1,1),
    ProductID  INT           NOT NULL,
    ChangeType NVARCHAR(10)  NOT NULL,
    ChangedAt  DATETIME      NOT NULL DEFAULT (GETDATE()),
    OldPrice   DECIMAL(10,2) NULL,
    NewPrice   DECIMAL(10,2) NULL,
    TriggerLevel INT         NULL,  -- какой триггер сработал
    NestLevel  INT           NULL,  -- уровень вложенности
    CONSTRAINT [PK_ProductChangeLog] PRIMARY KEY ([LogID])
);
GO

CREATE TABLE Production.ChangeStatistics (
    StatID     INT IDENTITY(1,1) PRIMARY KEY,
    TotalChanges INT NOT NULL,
    LastChange  DATETIME NOT NULL DEFAULT (GETDATE()),
    NestLevel   INT NULL
);
GO


INSERT INTO Production.ChangeStatistics (TotalChanges, LastChange) VALUES (0, GETDATE());
GO

-- → ПЕРВЫЙ ТРИГГЕР (на таблице Product)
CREATE TRIGGER [Production].[trg_Product_AfterInsert]
ON [Production].[Product]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentLevel INT = @@NESTLEVEL;
    PRINT 'ТРИГГЕР 1 (Product) сработал на уровне: ' + CAST(@CurrentLevel AS VARCHAR);
    
    -- Логируем вставку товара
    INSERT INTO [Production].[ProductChangeLog] 
        ([ProductID], [ChangeType], [NewPrice], [TriggerLevel], [NestLevel])
    SELECT 
        [ProductID], 
        'INSERT', 
        [Price], 
        1,  -- это триггер №1
        @CurrentLevel
    FROM inserted;
    
    -- Этот INSERT запустит ВТОРОЙ триггер (на ProductChangeLog)
    -- потому что вставляем данные в таблицу, у которой есть триггер
END;
GO

-- → ВТОРОЙ ТРИГГЕР (на таблице ProductChangeLog)
CREATE TRIGGER [Production].[trg_ProductChangeLog_AfterInsert]
ON [Production].[ProductChangeLog]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentLevel INT = @@NESTLEVEL;
    PRINT 'ТРИГГЕР 2 (ProductChangeLog) сработал на уровне: ' + CAST(@CurrentLevel AS VARCHAR);
    
    -- Обновляем статистику (считаем общее количество изменений)
    UPDATE Production.ChangeStatistics
    SET TotalChanges = TotalChanges + (SELECT COUNT(*) FROM inserted),
        LastChange = GETDATE(),
        NestLevel = @CurrentLevel;
    
    -- Этот UPDATE может запустить ТРЕТИЙ триггер, если он есть на ChangeStatistics
END;
GO

-- → ТРЕТИЙ ТРИГГЕР (на таблице ChangeStatistics)
CREATE TRIGGER [Production].[trg_ChangeStatistics_AfterUpdate]
ON [Production].[ChangeStatistics]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentLevel INT = @@NESTLEVEL;
    PRINT 'ТРИГГЕР 3 (ChangeStatistics) сработал на уровне: ' + CAST(@CurrentLevel AS VARCHAR);
    
    -- логируем в консоль, что статистика обновилась
    PRINT 'Статистика изменений обновлена на уровне ' + CAST(@CurrentLevel AS VARCHAR);
END;
GO

-- INSERT запускает ЦЕПОЧКУ триггеров
INSERT INTO Production.Product (Name, Price, StockQty)
VALUES (N'Наушники', 5000, 50);
GO


SELECT '1. Таблица Product (товары):' AS Info;
SELECT ProductID, Name, Price FROM Production.Product;

SELECT '2. Таблица ProductChangeLog (лог с указанием триггера и уровня):' AS Info;
SELECT LogID, ProductID, ChangeType, TriggerLevel, NestLevel 
FROM Production.ProductChangeLog;

SELECT '3. Таблица ChangeStatistics (статистика с уровнем вложенности):' AS Info;
SELECT StatID, TotalChanges, LastChange, NestLevel 
FROM Production.ChangeStatistics;



-- Очистка
DROP TRIGGER [Production].[trg_ChangeStatistics_AfterUpdate];
DROP TRIGGER [Production].[trg_ProductChangeLog_AfterInsert];
DROP TRIGGER [Production].[trg_Product_AfterInsert];
DROP TABLE Production.ChangeStatistics;
DROP TABLE Production.ProductChangeLog;
DROP TABLE Production.Product;
GO

--  РЕКУРСИВНЫЕ ТРИГГЕРЫ
--  Триггер вызывает сам себя. Нужно условие остановки.

-- рекурсивные триггеры для базы
ALTER DATABASE [T-SQL_lab_6_integrity] SET RECURSIVE_TRIGGERS ON;
GO

-- таблица с иерархией
CREATE TABLE Production.Category (
    CategoryID  INT          NOT NULL IDENTITY(1,1),
    Name        NVARCHAR(50) NOT NULL,
    ParentID    INT          NULL,
    UpdateCount INT          NOT NULL DEFAULT (0),
    CONSTRAINT [PK_Category] PRIMARY KEY ([CategoryID]),
    CONSTRAINT [FK_Category_Parent] FOREIGN KEY ([ParentID])
        REFERENCES Production.Category([CategoryID])
);
GO

-- рекурсивный триггер
CREATE TRIGGER [Production].[trg_Category_RecursiveUpdate]
ON [Production].[Category]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @@NESTLEVEL > 3
        RETURN;  -- условие остановки рекурсии

    UPDATE [Production].[Category]
    SET [UpdateCount] = [UpdateCount] + 1
    WHERE [CategoryID] IN (
        SELECT [ParentID] FROM inserted WHERE [ParentID] IS NOT NULL
    );
END;
GO

-- иерархические данные
INSERT INTO Production.Category (Name, ParentID) VALUES
(N'Электроника', NULL),   -- (уровень 1)
(N'Компьютеры',  1),      -- (уровень 2)
(N'Ноутбуки',    2);      -- (уровень 3)

SELECT 'Категории ДО UPDATE:' AS Info;
SELECT * FROM Production.Category;

-- обновляем категорию, рекурсивно обновляются родители
UPDATE Production.Category SET Name = N'Компьютеры и ПК' WHERE CategoryID = 2;

SELECT 'Категории ПОСЛЕ UPDATE:' AS Info;
SELECT * FROM Production.Category;
GO

-- выключение рекурсии
ALTER DATABASE [T-SQL_lab_6_integrity] SET RECURSIVE_TRIGGERS OFF;
GO

-- Очистка
DROP TABLE Production.Category;
GO
