
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




-- Целостность данных — это точность и согласованность данных в БД.
-- Три основных типа:
--   Домен (столбец) — допустимые значения в столбце, разрешение NULL
--   Сущность (строка) — уникальная идентификация каждой строки (PRIMARY KEY)
--   Ссылочная        — связи между таблицами через FK → PK
--
-- Механизмы обеспечения целостности в SQL Server 2005:
--   Data types   — базовые ограничения на тип значений
--   Rules        — допустимые значения столбца (устарело, лучше CHECK)
--   Defaults     — значение по умолчанию (устарело, лучше DEFAULT constraint)
--   Constraints  — рекомендуемый стандартный метод (ANSI)
--   Triggers     — сложная бизнес-логика при изменении данных
--   XML schemas  — ограничение структуры XML-данных



--  СОЗДАНИЕ СХЕМ И ТАБЛИЦ


CREATE SCHEMA HumanResources;
GO
CREATE SCHEMA Production;
GO
CREATE SCHEMA Sales;
GO


-- таблица отделов (будем показывать PRIMARY KEY на ней)
CREATE TABLE HumanResources.Department (
    DepartmentID SMALLINT     NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50) NOT NULL,
    GroupName    NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME     NOT NULL,

    -- PRIMARY KEY clustered — пример из методички
    CONSTRAINT [PK_Department_DepartmentID] PRIMARY KEY CLUSTERED
        ([DepartmentID] ASC) WITH (IGNORE_DUP_KEY = OFF)
);
GO

-- таблица сотрудников — покажем UNIQUE, FOREIGN KEY, DEFAULT, CHECK
CREATE TABLE HumanResources.Employee (
    EmployeeID       INT           NOT NULL IDENTITY(1,1),
    NationalIDNumber NVARCHAR(15)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    LastName         NVARCHAR(50)  NOT NULL,
    JobTitle         NVARCHAR(50)  NOT NULL,
    HireDate         DATE          NOT NULL,
    Salary           DECIMAL(10,2) NOT NULL,
    DepartmentID     SMALLINT      NULL,
    -- DEFAULT задаётся инлайн при определении столбца (FOR column — только для ALTER TABLE)
    IsActive         BIT           NOT NULL CONSTRAINT [DF_Employee_IsActive]     DEFAULT (1),
    ModifiedDate     DATETIME      NOT NULL CONSTRAINT [DF_Employee_ModifiedDate] DEFAULT (GETDATE()),

    CONSTRAINT [PK_Employee_EmployeeID] PRIMARY KEY CLUSTERED ([EmployeeID] ASC),

    -- UNIQUE на NationalIDNumber — у каждого сотрудника свой ИНН
    CONSTRAINT [UQ_Employee_NationalIDNumber] UNIQUE NONCLUSTERED ([NationalIDNumber]),

    -- FK на Department — ссылочная целостность
    CONSTRAINT [FK_Employee_Department] FOREIGN KEY ([DepartmentID])
        REFERENCES [HumanResources].[Department] ([DepartmentID]),

    -- CHECK — зарплата не может быть отрицательной
    CONSTRAINT [CK_Employee_Salary] CHECK ([Salary] >= 0)
);
GO

-- таблица истории смены отделов — нужна для демо CHECK между столбцами и CASCADE
CREATE TABLE HumanResources.EmployeeDepartmentHistory (
    EmployeeID   INT      NOT NULL,
    DepartmentID SMALLINT NOT NULL,
    StartDate    DATE     NOT NULL,
    EndDate      DATE     NULL,

    CONSTRAINT [PK_EmpDeptHist] PRIMARY KEY ([EmployeeID], [DepartmentID], [StartDate]),

    CONSTRAINT [FK_EmpDeptHist_Employee]   FOREIGN KEY ([EmployeeID])
        REFERENCES [HumanResources].[Employee] ([EmployeeID]),

    CONSTRAINT [FK_EmpDeptHist_Department] FOREIGN KEY ([DepartmentID])
        REFERENCES [HumanResources].[Department] ([DepartmentID])
);
GO

-- таблица продуктов — для демо триггеров
CREATE TABLE Production.Product (
    ProductID   INT           NOT NULL IDENTITY(1,1),
    Name        NVARCHAR(50)  NOT NULL,
    Price       DECIMAL(10,2) NOT NULL,
    StockQty    INT           NOT NULL,
    ModifiedDate DATETIME     NOT NULL CONSTRAINT [DF_Product_ModifiedDate] DEFAULT (GETDATE()),

    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID]),
    CONSTRAINT [CK_Product_Price]    CHECK ([Price]    >= 0),
    CONSTRAINT [CK_Product_StockQty] CHECK ([StockQty] >= 0)
);
GO

-- таблица лога изменений продуктов — для демо триггера INSERT
CREATE TABLE Production.ProductChangeLog (
    LogID       INT          NOT NULL IDENTITY(1,1) CONSTRAINT [PK_ProductChangeLog] PRIMARY KEY,
    ProductID   INT          NOT NULL,
    ChangeType  NVARCHAR(10) NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
    ChangedAt   DATETIME     NOT NULL CONSTRAINT [DF_Log_ChangedAt] DEFAULT (GETDATE()),
    OldPrice    DECIMAL(10,2) NULL,
    NewPrice    DECIMAL(10,2) NULL
);
GO

-- таблица заказчиков — для демо каскадного удаления
CREATE TABLE Sales.Customer (
    CustomerID  INT          NOT NULL IDENTITY(1,1) CONSTRAINT [PK_Customer] PRIMARY KEY,
    CompanyName NVARCHAR(50) NOT NULL,
    ContactName NVARCHAR(50) NULL
);
GO

-- таблица заказов — FK с разными опциями CASCADE
CREATE TABLE Sales.SalesOrderHeader (
    SalesOrderID INT           NOT NULL IDENTITY(1,1) CONSTRAINT [PK_SalesOrder] PRIMARY KEY,
    CustomerID   INT           NOT NULL,
    OrderDate    DATE          NOT NULL,
    TotalAmount  DECIMAL(10,2) NOT NULL CONSTRAINT [CK_SalesOrder_TotalAmount] CHECK ([TotalAmount] >= 0),
    Status       NVARCHAR(20)  NOT NULL CONSTRAINT [DF_SalesOrder_Status] DEFAULT ('Новый'),

    -- ON DELETE CASCADE — при удалении заказчика удалятся и его заказы
    -- ON UPDATE CASCADE — при смене CustomerID обновится и здесь
    CONSTRAINT [FK_SalesOrderHeader_Customer] FOREIGN KEY ([CustomerID])
        REFERENCES [Sales].[Customer] ([CustomerID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO



--  ЗАПОЛНЕНИЕ ТАБЛИЦ

INSERT INTO HumanResources.Department (Name, GroupName, ModifiedDate) VALUES
(N'Разработка',     N'Технологии',            GETDATE()),
(N'Маркетинг',      N'Продажи и Маркетинг',   GETDATE()),
(N'Финансы',        N'Администрация',          GETDATE()),
(N'Отдел кадров',   N'Администрация',          GETDATE());

INSERT INTO HumanResources.Employee
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID, ModifiedDate)
VALUES
('123456789', N'Иван',    N'Иванов',  N'Разработчик',         '2020-01-15', 85000, 1, GETDATE()),
('987654321', N'Мария',   N'Петрова', N'Менеджер по продажам','2019-03-20', 72000, 2, GETDATE()),
('111222333', N'Алексей', N'Сидоров', N'Финансовый аналитик', '2021-06-01', 78000, 3, GETDATE()),
('444555666', N'Елена',   N'Козлова', N'HR-специалист',       '2018-11-10', 65000, 4, GETDATE());

INSERT INTO Production.Product (Name, Price, StockQty) VALUES
(N'Ноутбук',    75000, 15),
(N'Монитор',    25000, 30),
(N'Клавиатура',  3500, 100);

INSERT INTO Sales.Customer (CompanyName, ContactName) VALUES
(N'ООО Рога и Копыта', N'Иванченко П.П.'),
(N'АО ТехноТрейд',    N'Смирнова А.В.'),
(N'ИП Петров',         N'Петров С.С.');

INSERT INTO Sales.SalesOrderHeader (CustomerID, OrderDate, TotalAmount) VALUES
(1, '2024-01-10', 150000),
(1, '2024-02-05',  75000),
(2, '2024-01-20', 225000);




--  ОГРАНИЧЕНИЯ (CONSTRAINTS)


-- Ограничения — ANSI-стандартный рекомендуемый метод обеспечения целостности.
-- Предпочтительнее триггеров, правил и умолчаний.
-- Оптимизатор запросов использует ограничения для построения планов выполнения.


-- ----------------------------------------------------------
-- 2.1 PRIMARY KEY
--
-- Уникально идентифицирует каждую строку таблицы (целостность сущности).
-- Одна таблица — одно ограничение PRIMARY KEY.
-- NULL не допускается. Автоматически создаёт уникальный индекс.
-- По умолчанию — кластерный, можно явно задать NONCLUSTERED.
-- Удалить индекс нельзя, пока существует ограничение.
-- ----------------------------------------------------------

-- добавляем PK через ALTER TABLE
CREATE TABLE HumanResources.TestPK (
    ID   INT          NOT NULL,
    Name NVARCHAR(50) NOT NULL
);
GO

ALTER TABLE HumanResources.TestPK
ADD CONSTRAINT [PK_TestPK] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

-- убеждаемся, что дубликаты не пройдут
INSERT INTO HumanResources.TestPK VALUES (1, N'Первый');
INSERT INTO HumanResources.TestPK VALUES (2, N'Второй');

BEGIN TRY
    INSERT INTO HumanResources.TestPK VALUES (1, N'Дубликат ID=1');
END TRY
BEGIN CATCH
    PRINT 'PRIMARY KEY: дубликат отклонён — ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    INSERT INTO HumanResources.TestPK VALUES (NULL, N'NULL в PK');
END TRY
BEGIN CATCH
    PRINT 'PRIMARY KEY: NULL не допускается — ' + ERROR_MESSAGE();
END CATCH

DROP TABLE HumanResources.TestPK;
GO


-- 2.2 DEFAULT
--
-- Вставляет значение, если в INSERT оно не указано.
-- Срабатывает только при INSERT.
-- Один столбец — одно DEFAULT.
-- Не применяется к IDENTITY и rowversion.
-- Можно использовать системные функции: GETDATE(), USER, SYSTEM_USER и др.

-- IsActive = 1 и ModifiedDate = GETDATE() — мы не указываем их в INSERT
INSERT INTO HumanResources.Employee
    (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID, ModifiedDate)
VALUES
    ('777888999', N'Тест', N'Дефолт', N'Тестировщик', '2024-01-01', 60000, 1, DEFAULT);
-- ModifiedDate получит GETDATE(), IsActive получит 1

SELECT EmployeeID, FirstName, IsActive, ModifiedDate
FROM HumanResources.Employee
WHERE NationalIDNumber = '777888999';
GO

-- убираем тестовую запись
DELETE FROM HumanResources.Employee WHERE NationalIDNumber = '777888999';
GO

-- добавление DEFAULT через ALTER TABLE
ALTER TABLE Production.Product
ADD CONSTRAINT [DF_Product_Price_Zero] DEFAULT (0.00) FOR [Price];
-- такое добавить не дадим, т.к. уже есть NOT NULL без DEFAULT на Price,
-- но сам синтаксис ALTER TABLE + DEFAULT рабочий — удалим сразу
ALTER TABLE Production.Product
DROP CONSTRAINT [DF_Product_Price_Zero];
GO


-- 2.3 CHECK
--
-- Ограничивает значения при INSERT и UPDATE.
-- Любое булево выражение (TRUE/FALSE).
-- Подзапросы запрещены.
-- Один столбец может иметь несколько CHECK.
-- Нельзя применять к rowversion, text, ntext, image.
-- DBCC CHECKCONSTRAINTS вернёт строки, нарушающие CHECK.

-- проверка CK_Employee_Salary — зарплата не может быть < 0
BEGIN TRY
    INSERT INTO HumanResources.Employee
        (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID, ModifiedDate)
    VALUES ('000000001', N'Тест', N'Чек', N'Стажёр', '2024-01-01', -100, 1, GETDATE());
END TRY
BEGIN CATCH
    PRINT 'CHECK (Salary >= 0): отрицательная зарплата отклонена — ' + ERROR_MESSAGE();
END CATCH
GO

-- CHECK между двумя столбцами одной таблицы — EndDate >= StartDate (пример из методички)
ALTER TABLE [HumanResources].[EmployeeDepartmentHistory]
WITH CHECK
ADD CONSTRAINT [CK_EmpDeptHist_EndDate]
CHECK (([EndDate] >= [StartDate] OR [EndDate] IS NULL));
GO

-- проверяем: EndDate раньше StartDate — должно отклонить
INSERT INTO HumanResources.EmployeeDepartmentHistory VALUES (1, 1, '2024-06-01', NULL);

BEGIN TRY
    INSERT INTO HumanResources.EmployeeDepartmentHistory
    VALUES (1, 1, '2024-06-01', '2024-05-01');  -- EndDate < StartDate
END TRY
BEGIN CATCH
    PRINT 'CHECK (EndDate >= StartDate): неверный диапазон дат отклонён — ' + ERROR_MESSAGE();
END CATCH
GO

-- DBCC CHECKCONSTRAINTS — проверяет все данные таблицы на соответствие CHECK
DBCC CHECKCONSTRAINTS ('HumanResources.Employee');
GO


-- 2.4 UNIQUE
--
-- Запрещает дублирование значений (целостность сущности для не-PK столбцов).
-- Одна таблица — много UNIQUE, но один PRIMARY KEY.
-- Допускает одно NULL-значение.
-- Реализуется через уникальный некластерный индекс (max 249 штук).

-- NationalIDNumber помечен UNIQUE — два сотрудника с одним ИНН не пройдут
BEGIN TRY
    INSERT INTO HumanResources.Employee
        (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID, ModifiedDate)
    VALUES ('123456789', N'Двойник', N'Иванова', N'Разработчик', '2024-01-01', 70000, 1, GETDATE());
END TRY
BEGIN CATCH
    PRINT 'UNIQUE (NationalIDNumber): дублирующийся ИНН отклонён — ' + ERROR_MESSAGE();
END CATCH
GO

-- добавление UNIQUE через ALTER TABLE
ALTER TABLE HumanResources.Employee
ADD CONSTRAINT [UQ_Employee_FullName] UNIQUE NONCLUSTERED ([FirstName], [LastName]);
GO

-- удаление UNIQUE
ALTER TABLE HumanResources.Employee
DROP CONSTRAINT [UQ_Employee_FullName];
GO



-- 2.5 FOREIGN KEY
--
-- Устанавливает связь между таблицами (ссылочная целостность).
-- Ссылается на PRIMARY KEY или UNIQUE другой (или той же) таблицы.
-- Не создаёт индекс автоматически — в отличие от PK и UNIQUE.
-- Число столбцов и типы в FK должны соответствовать столбцам в PK.


-- нельзя вставить сотрудника с несуществующим отделом
BEGIN TRY
    INSERT INTO HumanResources.Employee
        (NationalIDNumber, FirstName, LastName, JobTitle, HireDate, Salary, DepartmentID, ModifiedDate)
    VALUES ('999000111', N'Тест', N'ФК', N'Призрак', '2024-01-01', 50000, 99, GETDATE());
END TRY
BEGIN CATCH
    PRINT 'FOREIGN KEY: несуществующий DepartmentID=99 отклонён — ' + ERROR_MESSAGE();
END CATCH
GO

-- нельзя удалить отдел, пока в нём есть сотрудники (NO ACTION по умолчанию)
BEGIN TRY
    DELETE FROM HumanResources.Department WHERE DepartmentID = 1;
END TRY
BEGIN CATCH
    PRINT 'FOREIGN KEY (NO ACTION): удаление отдела с сотрудниками отклонено — ' + ERROR_MESSAGE();
END CATCH
GO

-- добавление FK через ALTER TABLE — пример из методички
-- NO ACTION здесь, т.к. CASCADE уже задан в основном FK на этой таблице —
-- SQL Server запрещает два каскадных пути к одной таблице (защита от циклов)
ALTER TABLE [Sales].[SalesOrderHeader] WITH CHECK
ADD CONSTRAINT [FK_SalesOrderHeader_Customer_CustomerID_demo]
    FOREIGN KEY ([CustomerID])
    REFERENCES [Sales].[Customer] ([CustomerID])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

ALTER TABLE [Sales].[SalesOrderHeader]
DROP CONSTRAINT [FK_SalesOrderHeader_Customer_CustomerID_demo];
GO



-- 2.6 КАСКАДНАЯ ССЫЛОЧНАЯ ЦЕЛОСТНОСТЬ
--
-- ON DELETE / ON UPDATE управляют поведением при изменении PK.
--
-- NO ACTION   — ошибка, откат (по умолчанию)
-- CASCADE     — UPDATE: обновить FK; DELETE: удалить зависимые строки
-- SET NULL    — FK становится NULL (столбец должен допускать NULL)
-- SET DEFAULT — FK устанавливается в DEFAULT (должен быть задан DEFAULT)


-- демо ON DELETE CASCADE:
-- при удалении заказчика удаляются все его заказы автоматически

SELECT 'Заказы до удаления заказчика CustomerID=1:' AS Info;
SELECT SalesOrderID, CustomerID, TotalAmount FROM Sales.SalesOrderHeader;
GO

DELETE FROM Sales.Customer WHERE CustomerID = 1;

SELECT 'Заказы после удаления заказчика CustomerID=1 (CASCADE):' AS Info;
SELECT SalesOrderID, CustomerID, TotalAmount FROM Sales.SalesOrderHeader;
GO



-- демо SET NULL — создаём отдельные таблицы специально
CREATE TABLE HumanResources.TestParent (
    ParentID INT NOT NULL CONSTRAINT [PK_TestParent] PRIMARY KEY,
    Name     NVARCHAR(30) NOT NULL
);

CREATE TABLE HumanResources.TestChild (
    ChildID  INT NOT NULL CONSTRAINT [PK_TestChild] PRIMARY KEY,
    ParentID INT NULL,  -- NULL допускается — иначе SET NULL не применить
    CONSTRAINT [FK_TestChild_Parent] FOREIGN KEY ([ParentID])
        REFERENCES [HumanResources].[TestParent] ([ParentID])
        ON DELETE SET NULL
        ON UPDATE SET NULL
);

INSERT INTO HumanResources.TestParent VALUES (1, N'Родитель');
INSERT INTO HumanResources.TestChild  VALUES (1, 1), (2, 1);

SELECT 'TestChild до DELETE SET NULL:' AS Info;
SELECT * FROM HumanResources.TestChild;

DELETE FROM HumanResources.TestParent WHERE ParentID = 1;

SELECT 'TestChild после DELETE SET NULL (ParentID стал NULL):' AS Info;
SELECT * FROM HumanResources.TestChild;

DROP TABLE HumanResources.TestChild;
DROP TABLE HumanResources.TestParent;
GO

-- демо SET DEFAULT
CREATE TABLE HumanResources.TestParent2 (
    ParentID INT NOT NULL CONSTRAINT [PK_TestParent2] PRIMARY KEY,
    Name     NVARCHAR(30) NOT NULL
);

CREATE TABLE HumanResources.TestChild2 (
    ChildID  INT NOT NULL CONSTRAINT [PK_TestChild2] PRIMARY KEY,
    ParentID INT NOT NULL CONSTRAINT [DF_TestChild2_ParentID] DEFAULT (0),
    CONSTRAINT [FK_TestChild2_Parent] FOREIGN KEY ([ParentID])
        REFERENCES [HumanResources].[TestParent2] ([ParentID])
        ON DELETE SET DEFAULT
        ON UPDATE SET DEFAULT
);

INSERT INTO HumanResources.TestParent2 VALUES (0, N'Неизвестный'), (1, N'Родитель');
INSERT INTO HumanResources.TestChild2 (ChildID, ParentID) VALUES (1, 1), (2, 1);

SELECT 'TestChild2 до DELETE SET DEFAULT:' AS Info;
SELECT * FROM HumanResources.TestChild2;

DELETE FROM HumanResources.TestParent2 WHERE ParentID = 1;

SELECT 'TestChild2 после DELETE SET DEFAULT (ParentID стал DEFAULT=0):' AS Info;
SELECT * FROM HumanResources.TestChild2;

DROP TABLE HumanResources.TestChild2;
DROP TABLE HumanResources.TestParent2;
GO



-- 2.7 ОТКЛЮЧЕНИЕ ОГРАНИЧЕНИЙ
--
-- Можно отключить только CHECK и FOREIGN KEY.
-- PRIMARY KEY, UNIQUE, DEFAULT — нужно удалять и пересоздавать.
--
-- Когда отключать:
--   — при массовой загрузке данных (оптимизация производительности)
--   — при добавлении ограничения к таблице с уже существующими данными
--
-- WITH NOCHECK — не проверять существующие данные при добавлении FK/CHECK
-- NOCHECK CONSTRAINT — временно отключить проверку
-- CHECK CONSTRAINT   — включить обратно
--
-- Проверить состояние: sp_help или OBJECTPROPERTY(..., 'CnstIsDisabled')


-- добавляем FK без проверки существующих данных (WITH NOCHECK)
-- полезно, если в таблице уже есть записи, которые могут не соответствовать
ALTER TABLE [Sales].[SalesOrderHeader] WITH NOCHECK
ADD CONSTRAINT [FK_SalesOrder_Customer_demo2]
    FOREIGN KEY ([CustomerID])
    REFERENCES [Sales].[Customer] ([CustomerID]);
GO

-- отключаем ограничение — теперь FK не проверяется при вставке
ALTER TABLE [Sales].[SalesOrderHeader]
NOCHECK CONSTRAINT [FK_SalesOrderHeader_Customer];

-- с отключённым FK можно вставить "осиротевший" заказ
INSERT INTO Sales.SalesOrderHeader (CustomerID, OrderDate, TotalAmount)
VALUES (9999, '2024-03-01', 1000);

SELECT 'Заказ с несуществующим CustomerID=9999 вставлен (FK отключён):' AS Info;
SELECT SalesOrderID, CustomerID FROM Sales.SalesOrderHeader WHERE CustomerID = 9999;
GO

-- включаем ограничение обратно
ALTER TABLE [Sales].[SalesOrderHeader]
CHECK CONSTRAINT [FK_SalesOrderHeader_Customer];
GO

-- убираем мусорный заказ и лишнее ограничение
DELETE FROM Sales.SalesOrderHeader WHERE CustomerID = 9999;
ALTER TABLE [Sales].[SalesOrderHeader] DROP CONSTRAINT [FK_SalesOrder_Customer_demo2];
GO

-- проверить информацию об ограничениях таблицы
EXEC sp_helpconstraint 'HumanResources.Employee';
GO

-- OBJECTPROPERTY для проверки состояния ограничения
SELECT
    o.name AS [Ограничение],
    OBJECTPROPERTY(o.object_id, 'CnstIsDisabled') AS [Отключено]
FROM sys.objects o
WHERE o.parent_object_id = OBJECT_ID('HumanResources.Employee')
  AND o.type IN ('C', 'F');  -- C = CHECK, F = FOREIGN KEY
GO



--  3: ТРИГГЕРЫ (TRIGGERS)

-- Триггер — специальная хранимая процедура, которая выполняется
-- автоматически при INSERT, UPDATE или DELETE на таблице/представлении.
--
-- Триггер + вызвавший оператор = одна транзакция → можно откатить.
-- Могут ссылаться на другие таблицы (в отличие от CHECK).
-- Позволяют реализовать сложную бизнес-логику.
--
-- Две категории:
--   AFTER (FOR)   — выполняется ПОСЛЕ операции; только для таблиц
--   INSTEAD OF    — выполняется ВМЕСТО операции; для таблиц и представлений
--
-- Таблицы inserted и deleted:
--   inserted — новые строки (INSERT/UPDATE)
--   deleted  — старые строки (DELETE/UPDATE)
--
-- Синтаксис:
-- CREATE TRIGGER [schema.]trigger_name
-- ON { table | view }
-- [ WITH <dml_trigger_option> ]
-- { FOR | AFTER | INSTEAD OF }
-- { [INSERT] [,] [UPDATE] [,] [DELETE] }
-- AS { sql_statement [...] }



-- 3.1 ТРИГГЕР INSERT (AFTER INSERT)
--
-- Срабатывает после INSERT.
-- Новые строки — и в основной таблице, и в таблице inserted.
-- Таблица inserted позволяет читать только что добавленные данные.

-- при добавлении продукта пишем запись в лог
CREATE TRIGGER [Production].[trg_Product_AfterInsert]
ON [Production].[Product]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- из таблицы inserted берём все только что вставленные строки
    INSERT INTO [Production].[ProductChangeLog] ([ProductID], [ChangeType], [NewPrice])
    SELECT [ProductID], 'INSERT', [Price]
    FROM inserted;
END;
GO

-- проверяем: вставляем продукт, смотрим лог
INSERT INTO Production.Product (Name, Price, StockQty)
VALUES (N'Мышь', 1500, 200);

SELECT 'Лог после INSERT продукта:' AS Info;
SELECT * FROM Production.ProductChangeLog;
GO


-- 3.2 ТРИГГЕР DELETE (AFTER DELETE)
--
-- Срабатывает после DELETE.
-- Удалённые строки помещаются в таблицу deleted.
-- Таблица deleted хранится в кеш-памяти.
-- На TRUNCATE TABLE триггер DELETE не срабатывает (не журналируется).

-- при удалении продукта логируем факт (пример аналогичен delCustomer из методички)
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

-- проверяем: удаляем продукт, смотрим лог
DELETE FROM Production.Product WHERE Name = N'Мышь';

SELECT 'Лог после DELETE продукта:' AS Info;
SELECT * FROM Production.ProductChangeLog;
GO


-- 3.3 ТРИГГЕР UPDATE (AFTER UPDATE)
--
-- Срабатывает после UPDATE.
-- Логически два шага: шаг DELETE (старые данные → deleted)
--                     + шаг INSERT (новые данные → inserted).
-- IF UPDATE(column) — проверяет, был ли обновлён конкретный столбец.

-- при изменении цены логируем старую и новую цену (аналог updtProductReview из методички)
-- также обновляем ModifiedDate автоматически
CREATE TRIGGER [Production].[trg_Product_AfterUpdate]
ON [Production].[Product]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- обновляем ModifiedDate в изменённых строках
    UPDATE [Production].[Product]
    SET [ModifiedDate] = GETDATE()
    FROM inserted
    WHERE inserted.[ProductID] = [Production].[Product].[ProductID];

    -- если менялась именно цена — пишем в лог (используем IF UPDATE)
    IF UPDATE(Price)
    BEGIN
        INSERT INTO [Production].[ProductChangeLog]
            ([ProductID], [ChangeType], [OldPrice], [NewPrice])
        SELECT
            i.[ProductID],
            'UPDATE',
            d.[Price],  -- старая цена из deleted
            i.[Price]   -- новая цена из inserted
        FROM inserted i
        INNER JOIN deleted d ON d.[ProductID] = i.[ProductID];
    END
END;
GO

-- проверяем: меняем цену ноутбука
SELECT 'Ноутбук до UPDATE:' AS Info;
SELECT ProductID, Name, Price, ModifiedDate FROM Production.Product WHERE Name = N'Ноутбук';

UPDATE Production.Product SET Price = 79000 WHERE Name = N'Ноутбук';

SELECT 'Ноутбук после UPDATE:' AS Info;
SELECT ProductID, Name, Price, ModifiedDate FROM Production.Product WHERE Name = N'Ноутбук';

SELECT 'Лог после UPDATE цены:' AS Info;
SELECT * FROM Production.ProductChangeLog;
GO



-- 3.4 ТРИГГЕР INSTEAD OF (ВМЕСТО)
--
-- Выполняется ВМЕСТО исходной операции.
-- Исходная операция (INSERT/UPDATE/DELETE) НЕ выполняется сама по себе.
-- Каждая таблица/представление — не более одного INSTEAD OF на действие.
-- Нельзя создать на представлении с WITH CHECK OPTION.
-- Полезен для:
--   — обновления многотабличных представлений
--   — реализации альтернативного действия при определённых условиях
--   — отклонения части операций с разрешением остальных

-- запрещаем удалять активных сотрудников (аналог delEmployee из методички)
CREATE TRIGGER [HumanResources].[trg_Employee_InsteadOfDelete]
ON [HumanResources].[Employee]
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeleteCount INT;
    SELECT @DeleteCount = COUNT(*) FROM deleted;

    IF @DeleteCount > 0
    BEGIN
        -- проверяем, есть ли среди удаляемых активные сотрудники
        IF EXISTS (SELECT 1 FROM deleted WHERE IsActive = 1)
        BEGIN
            RAISERROR(
                N'Нельзя удалять активных сотрудников. Сначала деактивируйте их (IsActive = 0).',
                16, 1
            );

            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
        END
        ELSE
        BEGIN
            -- неактивных удалять можно
            DELETE FROM [HumanResources].[Employee]
            WHERE [EmployeeID] IN (SELECT [EmployeeID] FROM deleted);
        END
    END
END;
GO

-- попытка удалить активного сотрудника — должна быть отклонена
BEGIN TRY
    DELETE FROM HumanResources.Employee WHERE EmployeeID = 1;
END TRY
BEGIN CATCH
    PRINT 'INSTEAD OF DELETE: ' + ERROR_MESSAGE();
END CATCH
GO

-- деактивируем сотрудника и потом удаляем — должно сработать
UPDATE HumanResources.Employee SET IsActive = 0 WHERE EmployeeID = 4;
DELETE FROM HumanResources.Employee WHERE EmployeeID = 4;

SELECT 'Сотрудники после удаления деактивированного (EmployeeID=4):' AS Info;
SELECT EmployeeID, FirstName, IsActive FROM HumanResources.Employee;
GO



-- 3.5 ВЛОЖЕННЫЕ ТРИГГЕРЫ
--
-- Триггер, который выполняет INSERT/UPDATE/DELETE на другой таблице,
-- может запустить триггер на этой другой таблице — это и есть вложение.
-- Максимальная глубина — 32 уровня.
-- При превышении: транзакция откатывается.
-- Управляется через sp_configure 'nested triggers', 0/1.
-- @@NESTLEVEL — текущий уровень вложения.


-- наш trg_Product_AfterInsert уже является примером:
-- пользователь делает INSERT в Product → триггер делает INSERT в ProductChangeLog
-- если бы у ProductChangeLog тоже был триггер — это было бы вложение уровня 2

-- проверяем текущий уровень вложения внутри триггера через таблицу
-- (добавим в лог уровень вложения — для наглядности)
ALTER TABLE Production.ProductChangeLog
ADD NestLevel INT NULL;
GO

ALTER TRIGGER [Production].[trg_Product_AfterInsert]
ON [Production].[Product]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [Production].[ProductChangeLog] ([ProductID], [ChangeType], [NewPrice], [NestLevel])
    SELECT [ProductID], 'INSERT', [Price], @@NESTLEVEL
    FROM inserted;
END;
GO

-- вставляем ещё один продукт — смотрим уровень вложения в логе
INSERT INTO Production.Product (Name, Price, StockQty)
VALUES (N'Наушники', 5000, 50);

SELECT 'Лог с уровнем вложения (@@NESTLEVEL):' AS Info;
SELECT LogID, ProductID, ChangeType, NestLevel FROM Production.ProductChangeLog
ORDER BY LogID DESC;
GO

-- проверить, включена ли вложенность триггеров на сервере
EXEC sp_configure 'nested triggers';
GO

-- отключение вложенности (уровень сервера):
-- EXEC sp_configure 'nested triggers', 0; RECONFIGURE;
-- включение обратно:
-- EXEC sp_configure 'nested triggers', 1; RECONFIGURE;



-- 3.6 РЕКУРСИВНЫЕ ТРИГГЕРЫ
--
-- Триггер, который вызывает сам себя (прямо или косвенно).
-- По умолчанию ОТКЛЮЧЕНЫ на уровне базы данных.
-- Включаются через ALTER DATABASE ... SET RECURSIVE_TRIGGERS ON.
--
-- Прямая рекурсия:  триггер T1 на таблице A → обновляет A → снова T1
-- Косвенная рекурсия: T1 на A → обновляет B → T2 на B → обновляет A → снова T1
--
-- Если вложенные триггеры отключены — рекурсивные тоже отключены.
-- RECURSIVE_TRIGGERS влияет только на прямую рекурсию.
-- Без контроля глубины превысит лимит 32 уровня → откат транзакции.


-- проверяем текущее состояние RECURSIVE_TRIGGERS для нашей БД
SELECT
    name AS [База данных],
    is_recursive_triggers_on AS [Рекурсивные триггеры включены]
FROM sys.databases
WHERE name = 'T-SQL_lab_6_integrity';
GO

-- включение рекурсивных триггеров:
ALTER DATABASE [T-SQL_lab_6_integrity] SET RECURSIVE_TRIGGERS ON;
GO

-- демо: таблица с рекурсивной связью (дерево категорий)
CREATE TABLE Production.Category (
    CategoryID   INT          NOT NULL IDENTITY(1,1) CONSTRAINT [PK_Category] PRIMARY KEY,
    Name         NVARCHAR(50) NOT NULL,
    ParentID     INT          NULL CONSTRAINT [FK_Category_Parent]
                                   REFERENCES Production.Category(CategoryID),
    UpdateCount  INT          NOT NULL CONSTRAINT [DF_Category_UpdateCount] DEFAULT (0)
);
GO

-- рекурсивный триггер: при обновлении категории обновляет родительскую
-- (реальный пример — пересчёт счётчиков вверх по дереву)
-- здесь добавляем @@NESTLEVEL в условие остановки, чтобы не уйти в бесконечность
CREATE TRIGGER [Production].[trg_Category_RecursiveUpdate]
ON [Production].[Category]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- условие остановки — не уходим глубже 3 уровней
    IF @@NESTLEVEL > 3
        RETURN;

    -- обновляем родительскую категорию (увеличиваем счётчик)
    UPDATE [Production].[Category]
    SET [UpdateCount] = [UpdateCount] + 1
    WHERE [CategoryID] IN (
        SELECT [ParentID] FROM inserted WHERE [ParentID] IS NOT NULL
    );
END;
GO

INSERT INTO Production.Category (Name, ParentID) VALUES
(N'Электроника', NULL),     -- корень
(N'Компьютеры',  1),        -- дочерняя
(N'Ноутбуки',    2);        -- внучатая

SELECT 'Категории до UPDATE:' AS Info;
SELECT * FROM Production.Category;

-- обновляем дочернюю категорию — триггер должен обновить родительскую,
-- та в свою очередь обновит её родителя (2 уровня рекурсии)
UPDATE Production.Category SET Name = N'Компьютеры и ПК' WHERE CategoryID = 2;

SELECT 'Категории после UPDATE (UpdateCount показывает глубину рекурсии):' AS Info;
SELECT * FROM Production.Category;
GO

-- выключаем рекурсивные триггеры обратно
ALTER DATABASE [T-SQL_lab_6_integrity] SET RECURSIVE_TRIGGERS OFF;
GO



--  СПИСОК ТРИГГЕРОВ И ОГРАНИЧЕНИЙ


SELECT 'Триггеры в базе данных:' AS Info;
SELECT
    s.name  AS [Схема],
    t.name  AS [Триггер],
    o.name  AS [На таблице],
    t.type_desc,
    CASE OBJECTPROPERTY(t.object_id, 'ExecIsInsteadOfTrigger')
        WHEN 1 THEN 'INSTEAD OF'
        ELSE 'AFTER'
    END AS [Тип],
    CASE OBJECTPROPERTY(t.object_id, 'ExecIsInsertTrigger') WHEN 1 THEN 'INSERT ' ELSE '' END +
    CASE OBJECTPROPERTY(t.object_id, 'ExecIsUpdateTrigger') WHEN 1 THEN 'UPDATE ' ELSE '' END +
    CASE OBJECTPROPERTY(t.object_id, 'ExecIsDeleteTrigger') WHEN 1 THEN 'DELETE'  ELSE '' END
        AS [Событие]
FROM sys.triggers t
INNER JOIN sys.objects  o ON o.object_id = t.parent_id
INNER JOIN sys.schemas  s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name, t.name;
GO

SELECT 'Ограничения в базе данных:' AS Info;
SELECT
    s.name  AS [Схема],
    o.name  AS [Таблица],
    c.name  AS [Ограничение],
    c.type_desc
FROM sys.objects c
INNER JOIN sys.objects o ON o.object_id = c.parent_object_id
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE c.type IN ('C', 'D', 'F', 'PK', 'UQ')
ORDER BY s.name, o.name, c.type_desc;
GO