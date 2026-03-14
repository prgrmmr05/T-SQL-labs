--  СОЗДАНИЕ БД
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'T-SQL_lab_7_proc_func')
BEGIN
    ALTER DATABASE [T-SQL_lab_7_proc_func] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [T-SQL_lab_7_proc_func];
END
GO

CREATE DATABASE [T-SQL_lab_7_proc_func];
GO

USE [T-SQL_lab_7_proc_func];
GO


--  СХЕМЫ
CREATE SCHEMA Production;
GO
CREATE SCHEMA HumanResources;
GO
CREATE SCHEMA Sales;
GO



--  ХРАНИМЫЕ ПРОЦЕДУРЫ


--  ПРОСТАЯ ХРАНИМАЯ ПРОЦЕДУРА
--  Именованная группа операторов T-SQL, откомпилированных в единый план выполнения.
--  Создаётся только в текущей БД (исключение — временные процедуры, они в tempdb).
--  Имена объектов внутри квалифицируются схемой.
--  Префикс sp_ не используется — SQL Server ищет его в master перед текущей БД.
--  Одна процедура — одна задача.

-- рабочая таблица
CREATE TABLE Production.Product (
    ProductID         INT           NOT NULL IDENTITY(1,1),
    Name              NVARCHAR(50)  NOT NULL,
    ProductNumber     NVARCHAR(25)  NOT NULL,
    Price             DECIMAL(10,2) NOT NULL,
    DaysToManufacture INT           NOT NULL,
    CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID])
);
GO

INSERT INTO Production.Product (Name, ProductNumber, Price, DaysToManufacture) VALUES
(N'Ноутбук',    N'LT-001', 75000,  3),
(N'Мышь',       N'MS-001',  1500,  0),
(N'Клавиатура', N'KB-001',  3200,  0),
(N'Монитор',    N'MN-001', 28000,  2),
(N'Наушники',   N'HS-001',  5000,  1),
(N'Сервер',     N'SV-001', 250000, 7);
GO

-- CREATE PROCEDURE — без параметров
CREATE PROC Production.LongLeadProducts
AS
    SELECT Name, ProductNumber
    FROM   Production.Product
    WHERE  DaysToManufacture >= 1;
GO

-- EXEC / EXECUTE для вызова процедуры
SELECT 'Вызов простой процедуры:' AS Info;
EXEC Production.LongLeadProducts;
GO


--  ALTER PROCEDURE
--  Изменяет определение и сохраняет все разрешения.
--  DROP + CREATE — сбрасывает разрешения.
--  ALTER меняет только саму процедуру; вложенные процедуры не затрагиваются.
--  Если процедура была создана WITH ENCRYPTION, опцию нужно указать снова в ALTER.

ALTER PROC Production.LongLeadProducts
AS
    SELECT Name, ProductNumber, DaysToManufacture
    FROM   Production.Product
    WHERE  DaysToManufacture >= 1
    ORDER BY DaysToManufacture DESC, Name;
GO

SELECT 'После ALTER (добавлен столбец DaysToManufacture и ORDER BY):' AS Info;
EXEC Production.LongLeadProducts;
GO


--  sp_depends — зависимости объекта
--  Перед удалением процедуры рекомендуется проверять, что от неё зависит.

EXEC sp_depends @objname = N'Production.LongLeadProducts';
GO


--  DROP PROCEDURE — удаление из текущей БД

DROP PROC Production.LongLeadProducts;
GO

-- процедуры больше нет — вызов вызовет ошибку
BEGIN TRY
    EXEC Production.LongLeadProducts;
END TRY
BEGIN CATCH
    PRINT 'DROP PROCEDURE: процедура удалена — ' + ERROR_MESSAGE();
END CATCH
GO

-- Очистка
DROP TABLE Production.Product;
GO


--  WITH ENCRYPTION
--  Скрывает текст процедуры — sys.sql_modules.definition возвращает NULL.
--  Процедура продолжает выполняться нормально.
--  После ALTER без ENCRYPTION текст снова становится виден.

CREATE TABLE Production.Product (
    ProductID INT          NOT NULL IDENTITY(1,1),
    Name      NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_Product_Enc] PRIMARY KEY ([ProductID])
);
GO

INSERT INTO Production.Product (Name) VALUES (N'Тест'), (N'Продукт');
GO

-- процедура с шифрованием тела
CREATE PROC Production.GetAllProducts
WITH ENCRYPTION
AS
    SELECT ProductID, Name FROM Production.Product;
GO

-- определение скрыто
SELECT 'Текст WITH ENCRYPTION (должен быть NULL):' AS Info;
SELECT
    OBJECT_NAME(object_id) AS ProcName,
    definition             AS ProcText   -- NULL для зашифрованных
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('Production.GetAllProducts');
GO

-- процедура при этом выполняется нормально
SELECT 'Процедура WITH ENCRYPTION работает:' AS Info;
EXEC Production.GetAllProducts;
GO

-- Очистка
DROP PROC Production.GetAllProducts;
DROP TABLE Production.Product;
GO


--  WITH RECOMPILE
--  Новый план выполнения создаётся при каждом вызове.
--  Полезно, когда данные меняются интенсивно и кэшированный план устаревает.

CREATE TABLE Production.Product (
    ProductID INT          NOT NULL IDENTITY(1,1),
    Name      NVARCHAR(50) NOT NULL,
    StockQty  INT          NOT NULL,
    CONSTRAINT [PK_Product_RC] PRIMARY KEY ([ProductID])
);
GO

INSERT INTO Production.Product (Name, StockQty) VALUES
(N'Ноутбук', 15), (N'Мышь', 200), (N'Монитор', 30);
GO

-- WITH RECOMPILE — перекомпиляция при каждом вызове
CREATE PROC Production.ProductsInStock
WITH RECOMPILE
AS
    SELECT ProductID, Name, StockQty
    FROM   Production.Product
    WHERE  StockQty > 0;
GO

SELECT 'Процедура WITH RECOMPILE:' AS Info;
EXEC Production.ProductsInStock;
GO

-- Очистка
DROP PROC Production.ProductsInStock;
DROP TABLE Production.Product;
GO


--  ВРЕМЕННАЯ ХРАНИМАЯ ПРОЦЕДУРА
--  # (одна решётка)   — локальная: видна только в текущей сессии.
--  ## (две решётки)   — глобальная: видна всем сессиям.
--  Всегда создаётся в tempdb, независимо от текущей БД.
--  Локальная удаляется автоматически при закрытии сессии.
--  Используются редко — засоряют системные таблицы tempdb.

-- локальная временная процедура
CREATE PROC #TempGetDate
AS
    SELECT
        GETDATE()   AS CurrentDateTime,
        DB_NAME()   AS CurrentDatabase,   -- отобразит текущую БД, не tempdb
        @@SPID      AS SessionID;
GO

SELECT 'Вызов локальной временной процедуры #TempGetDate:' AS Info;
EXEC #TempGetDate;
GO

-- временная процедура хранится в tempdb
SELECT 'Временная процедура в sys.objects (tempdb):' AS Info;
SELECT name, type_desc, create_date
FROM   tempdb.sys.objects
WHERE  name LIKE N'#TempGetDate%';
GO

-- явное удаление (или она удалится при закрытии сессии)
DROP PROC #TempGetDate;
GO


--  ПАРАМЕТРИЗОВАННЫЕ ХРАНИМЫЕ ПРОЦЕДУРЫ


--  ВХОДНЫЕ ПАРАМЕТРЫ
--  Процедура принимает до 2100 параметров.
--  Значение по умолчанию позволяет вызывать процедуру без передачи параметра.
--  Входящие значения валидируются в самом начале — «раннее обнаружение ошибок».
--  Можно передавать значения по имени (@param = значение) или по позиции.
--  При передаче по позиции нельзя пропускать параметры в середине списка.
--  Ключевое слово DEFAULT явно задействует значение по умолчанию.

CREATE TABLE Production.Product (
    ProductID         INT           NOT NULL IDENTITY(1,1),
    Name              NVARCHAR(50)  NOT NULL,
    ProductNumber     NVARCHAR(25)  NOT NULL,
    Price             DECIMAL(10,2) NOT NULL,
    DaysToManufacture INT           NOT NULL,
    CONSTRAINT [PK_Product_P2] PRIMARY KEY ([ProductID])
);
GO

INSERT INTO Production.Product (Name, ProductNumber, Price, DaysToManufacture) VALUES
(N'Ноутбук',    N'LT-001', 75000,  3),
(N'Мышь',       N'MS-001',  1500,  0),
(N'Монитор',    N'MN-001', 28000,  2),
(N'Наушники',   N'HS-001',  5000,  1),
(N'Сервер',     N'SV-001', 250000, 7);
GO

-- процедура с входным параметром и значением по умолчанию
CREATE PROC Production.LongLeadProducts
    @MinimumLength INT = 1     -- default value: 1
AS
    -- валидация входного параметра в самом начале
    IF (@MinimumLength < 0)
    BEGIN
        RAISERROR('Invalid lead time.', 14, 1);
        RETURN;
    END

    SELECT Name, ProductNumber, DaysToManufacture
    FROM   Production.Product
    WHERE  DaysToManufacture >= @MinimumLength
    ORDER BY DaysToManufacture DESC, Name;
GO

-- 1. вызов без параметра → используется default = 1
SELECT 'Вызов без параметра (default = 1):' AS Info;
EXEC Production.LongLeadProducts;
GO

-- 2. передача по имени параметра: @parameter = value
SELECT 'Передача по имени @MinimumLength = 3:' AS Info;
EXEC Production.LongLeadProducts @MinimumLength = 3;
GO

-- 3. передача по позиции (без имени параметра)
SELECT 'Передача по позиции (значение 2):' AS Info;
EXEC Production.LongLeadProducts 2;
GO

-- 4. явное ключевое слово DEFAULT — задействует значение по умолчанию
SELECT 'Передача ключевого слова DEFAULT:' AS Info;
EXEC Production.LongLeadProducts DEFAULT;
GO

-- 5. недопустимое значение → RAISERROR + RETURN
BEGIN TRY
    EXEC Production.LongLeadProducts @MinimumLength = -5;
END TRY
BEGIN CATCH
    PRINT 'Входной параметр: отрицательное значение отклонено — ' + ERROR_MESSAGE();
END CATCH
GO

-- Очистка
DROP PROC Production.LongLeadProducts;
DROP TABLE Production.Product;
GO


--  ВЫХОДНЫЕ ПАРАМЕТРЫ (OUTPUT) И ВОЗВРАЩАЕМЫЕ ЗНАЧЕНИЯ (RETURN)
--  OUTPUT — сохраняет изменённое значение переменной после завершения процедуры.
--  Ключевое слово OUTPUT нужно и в CREATE PROCEDURE, и в EXECUTE.
--  Если OUTPUT пропустить при вызове, вычисления выполнятся, но значение не вернётся.
--  RETURN — возвращает единственное целочисленное значение (статус/код ошибки).
--  SQL Server автоматически возвращает RETURN 0, если RETURN явно не указан.
--  SCOPE_IDENTITY() — идентификатор последней вставки в текущей области видимости.

CREATE TABLE HumanResources.Department (
    DepartmentID SMALLINT     NOT NULL IDENTITY(1,1),
    Name         NVARCHAR(50) NOT NULL,
    GroupName    NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_Department] PRIMARY KEY ([DepartmentID])
);
GO

-- процедура с OUTPUT-параметром и кодами RETURN
CREATE PROC HumanResources.AddDepartment
    @Name      NVARCHAR(50),
    @GroupName NVARCHAR(50),
    @DeptID    SMALLINT OUTPUT
AS
    -- пустые строки недопустимы → RETURN -1 (ошибка)
    IF ((@Name = '') OR (@GroupName = ''))
        RETURN -1;

    INSERT INTO HumanResources.Department (Name, GroupName)
    VALUES (@Name, @GroupName);

    SET @DeptID = SCOPE_IDENTITY();
    RETURN 0;   -- успех
GO

-- успешный вызов
DECLARE @dept   SMALLINT,
        @result INT;

EXEC @result = HumanResources.AddDepartment
    N'Разработка', N'Технологии', @dept OUTPUT;

IF (@result = 0)
BEGIN
    PRINT 'Отдел добавлен. Новый DepartmentID = ' + CAST(@dept AS VARCHAR);
    SELECT DepartmentID, Name, GroupName FROM HumanResources.Department;
END
ELSE
    SELECT 'Ошибка вставки (RETURN = ' + CAST(@result AS VARCHAR) + ')' AS Error;
GO

--RETURN -1 при пустых строках
DECLARE @dept   SMALLINT,
        @result INT;

EXEC @result = HumanResources.AddDepartment N'', N'', @dept OUTPUT;
SELECT 'RETURN при пустых полях = ' + CAST(@result AS VARCHAR) AS ReturnValue;
GO

-- вызов БЕЗ ключевого слова OUTPUT
-- вычисления выполнятся, строка вставится, но @dept останется NULL
DECLARE @dept SMALLINT = NULL;
EXEC HumanResources.AddDepartment N'Маркетинг', N'Продажи', @dept;
SELECT 'OUTPUT пропущен при вызове → @dept остаётся NULL:' AS Info,
       @dept AS DeptID;
GO

SELECT 'Содержимое Department:' AS Info;
SELECT * FROM HumanResources.Department;
GO

-- второй вызов: тот же DeptID OUTPUT, проверяем SCOPE_IDENTITY ──
DECLARE @dept   SMALLINT,
        @result INT;

EXEC @result = HumanResources.AddDepartment
    N'ИТ-Безопасность', N'Технологии', @dept OUTPUT;

SELECT 'Второй успешный INSERT, DeptID через SCOPE_IDENTITY = '
       + CAST(@dept AS VARCHAR) AS DeptID;
GO

-- Очистка
DROP PROC HumanResources.AddDepartment;
DROP TABLE HumanResources.Department;
GO


--  УРОК 3: СОЗДАНИЕ ФУНКЦИЙ
--  Функции — подпрограммы для многократно используемой логики.
--  Входные параметры не могут быть типа timestamp, cursor или table.
--  Выходные параметры (OUTPUT) не поддерживаются.
--  ALTER FUNCTION изменяет определение; DROP FUNCTION удаляет функцию.


--  СКАЛЯРНАЯ ФУНКЦИЯ (SCALAR FUNCTION)
--  Возвращает одно значение типа, указанного в RETURNS.
--  Тело обёрнуто в блок BEGIN...END.
--  Синтаксически похожа на встроенные функции COUNT(), MAX() и т.п.
--  Вызывается везде, где допустимо скалярное выражение того же типа данных:
--    — SELECT list, WHERE, HAVING, GROUP BY, ORDER BY
--    — VALUES / SET в INSERT и UPDATE
--    — DEFAULT и CHECK ограничения
--    — Булевы выражения в операторах управления потоком
--    — Выражения CASE, PRINT

CREATE TABLE Production.Product (
    ProductID INT           NOT NULL IDENTITY(1,1),
    Name      NVARCHAR(50)  NOT NULL,
    Price     DECIMAL(10,2) NOT NULL,
    StockQty  INT           NOT NULL,
    CONSTRAINT [PK_Product_SF] PRIMARY KEY ([ProductID])
);
GO

CREATE TABLE Sales.SalesOrderDetail (
    OrderDetailID INT NOT NULL IDENTITY(1,1),
    ProductID     INT NOT NULL,
    OrderQty      INT NOT NULL,
    CONSTRAINT [PK_SOD]         PRIMARY KEY ([OrderDetailID]),
    CONSTRAINT [FK_SOD_Product] FOREIGN KEY ([ProductID])
        REFERENCES Production.Product ([ProductID])
);
GO

INSERT INTO Production.Product (Name, Price, StockQty) VALUES
(N'Ноутбук', 75000, 15),
(N'Мышь',     1500, 200),
(N'Монитор', 28000, 30);

INSERT INTO Sales.SalesOrderDetail (ProductID, OrderQty) VALUES
(1, 3), (1, 2), (2, 10), (2, 5), (3, 4);
GO

-- скалярная функция: суммарное количество продаж по ProductID
CREATE FUNCTION Sales.SumSold(@ProductID INT)
RETURNS INT
AS
BEGIN
    DECLARE @ret INT;

    SELECT @ret = SUM(OrderQty)
    FROM   Sales.SalesOrderDetail
    WHERE  ProductID = @ProductID;

    IF (@ret IS NULL)
        SET @ret = 0;

    RETURN @ret;
END;
GO

-- вызов в SELECT list
SELECT 'Скалярная функция в SELECT list:' AS Info;
SELECT ProductID, Name, Sales.SumSold(ProductID) AS SumSold
FROM   Production.Product;
GO

-- вызов в WHERE
SELECT 'Вызов в WHERE (SumSold > 5):' AS Info;
SELECT Name
FROM   Production.Product
WHERE  Sales.SumSold(ProductID) > 5;
GO

-- вызов в ORDER BY
SELECT 'Вызов в ORDER BY (по убыванию продаж):' AS Info;
SELECT ProductID, Name
FROM   Production.Product
ORDER BY Sales.SumSold(ProductID) DESC;
GO

-- вызов в CASE
SELECT 'Вызов в CASE:' AS Info;
SELECT
    Name,
    CASE
        WHEN Sales.SumSold(ProductID) = 0 THEN N'Нет продаж'
        WHEN Sales.SumSold(ProductID) < 5  THEN N'Мало'
        ELSE                                    N'Хорошо'
    END AS SalesLevel
FROM Production.Product;
GO

-- вызов в GROUP BY / HAVING (через вычисляемое значение в подзапросе)
SELECT 'Вызов в подзапросе с GROUP BY / HAVING:' AS Info;
SELECT Name, TotalSold
FROM (
    SELECT Name, Sales.SumSold(ProductID) AS TotalSold
    FROM   Production.Product
) AS sub
GROUP BY Name, TotalSold
HAVING TotalSold > 0;
GO

-- ALTER FUNCTION — изменение (замена ISNULL)
ALTER FUNCTION Sales.SumSold(@ProductID INT)
RETURNS INT
AS
BEGIN
    DECLARE @ret INT;

    SELECT @ret = SUM(OrderQty)
    FROM   Sales.SalesOrderDetail
    WHERE  ProductID = @ProductID;

    RETURN ISNULL(@ret, 0);   -- короче, чем IF IS NULL / SET
END;
GO

SELECT 'После ALTER FUNCTION (ISNULL вместо IF):' AS Info;
SELECT ProductID, Name, Sales.SumSold(ProductID) AS SumSold
FROM   Production.Product;
GO

-- DROP FUNCTION
DROP FUNCTION Sales.SumSold;
GO

-- Очистка
DROP TABLE Sales.SalesOrderDetail;
DROP TABLE Production.Product;
GO



--  ПОДСТАВЛЯЕМАЯ ТАБЛИЧНАЯ ФУНКЦИЯ (INLINE TABLE-VALUED FUNCTION)
--  Возвращает TABLE — результат одного оператора SELECT.
--  Аналог параметризованного представления (представление не принимает параметры).
--  RETURNS TABLE — тип возврата.
--  Тело НЕ обёртывается в BEGIN...END.
--  RETURN ( ... ) содержит один SELECT в скобках.
--  Те же ограничения на SELECT, что и в представлениях.
--  Вызывается в FROM, как таблица или представление.

CREATE TABLE HumanResources.Employee (
    EmployeeID INT          NOT NULL IDENTITY(1,1),
    ManagerID  INT          NULL,
    FirstName  NVARCHAR(50) NOT NULL,
    LastName   NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_Employee_ITF] PRIMARY KEY ([EmployeeID])
);
GO

INSERT INTO HumanResources.Employee (ManagerID, FirstName, LastName) VALUES
(NULL, N'Директор',  N'Главный'),      -- EmployeeID=1, нет менеджера
(1,    N'Иван',      N'Иванов'),
(1,    N'Мария',     N'Петрова'),
(1,    N'Алексей',   N'Сидоров'),
(NULL, N'Другой',    N'Руководитель'); -- EmployeeID=5, нет менеджера
GO

-- подставляемая табличная функция: сотрудники заданного менеджера
CREATE FUNCTION HumanResources.EmployeesForManager(@ManagerId INT)
RETURNS TABLE
AS
RETURN (
    SELECT FirstName, LastName
    FROM   HumanResources.Employee
    WHERE  ManagerID = @ManagerId
);
GO

-- вызов в FROM
SELECT 'Подчинённые менеджера ID=1:' AS Info;
SELECT * FROM HumanResources.EmployeesForManager(1);
GO

SELECT 'Подчинённые менеджера ID=5 (пустой результат):' AS Info;
SELECT * FROM HumanResources.EmployeesForManager(5);
GO

-- использование в CROSS APPLY — получить всех подчинённых всех менеджеров
SELECT 'CROSS APPLY с подставляемой функцией:' AS Info;
SELECT e.EmployeeID AS ManagerID, fn.FirstName, fn.LastName
FROM   HumanResources.Employee e
CROSS APPLY HumanResources.EmployeesForManager(e.EmployeeID) fn;
GO

-- Очистка
DROP FUNCTION HumanResources.EmployeesForManager;
DROP TABLE HumanResources.Employee;
GO



--  МНОГООПЕРАТОРНАЯ ТАБЛИЧНАЯ ФУНКЦИЯ (MULTI-STATEMENT TABLE-VALUED FUNCTION)
--  Возвращает таблицу, построенную несколькими операторами T-SQL.
--  RETURNS @переменная TABLE (...) — задаёт имя и структуру возвращаемой таблицы.
--  Тело обёрнуто в BEGIN...END.
--  Комбинация хранимой процедуры и представления:
--    — как процедура: сложная логика, множество операторов.
--    — как представление: участвует в FROM оператора SELECT.
--  В отличие от хранимой процедуры — можно использовать в FROM / JOIN.

CREATE TABLE HumanResources.Employee (
    EmployeeID INT          NOT NULL IDENTITY(1,1),
    FirstName  NVARCHAR(50) NOT NULL,
    LastName   NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_Employee_MTF] PRIMARY KEY ([EmployeeID])
);
GO

INSERT INTO HumanResources.Employee (FirstName, LastName) VALUES
(N'Иван',   N'Иванов'),
(N'Мария',  N'Петрова'),
(N'Сергей', N'Кузнецов');
GO

-- многооператорная функция: формат имени задаётся параметром @format
CREATE FUNCTION HumanResources.EmployeeNames(@format NVARCHAR(9))
RETURNS @tbl_Employees TABLE (
    EmployeeID    INT           PRIMARY KEY,
    [Employee Name] NVARCHAR(100)
)
AS
BEGIN
    IF (@format = 'SHORTNAME')
        INSERT @tbl_Employees
        SELECT EmployeeID, LastName
        FROM   HumanResources.Employee;

    ELSE IF (@format = 'LONGNAME')
        INSERT @tbl_Employees
        SELECT EmployeeID, FirstName + N' ' + LastName
        FROM   HumanResources.Employee;

    RETURN;
END;
GO

-- вызов с LONGNAME
SELECT 'Многооператорная функция, LONGNAME:' AS Info;
SELECT * FROM HumanResources.EmployeeNames('LONGNAME');
GO

-- вызов с SHORTNAME
SELECT 'Многооператорная функция, SHORTNAME:' AS Info;
SELECT * FROM HumanResources.EmployeeNames('SHORTNAME');
GO

-- использование в JOIN — сочетаем с исходной таблицей
SELECT 'JOIN с многооператорной функцией:' AS Info;
SELECT e.EmployeeID, n.[Employee Name]
FROM   HumanResources.Employee e
JOIN   HumanResources.EmployeeNames('LONGNAME') n ON e.EmployeeID = n.EmployeeID;
GO

-- Очистка
DROP FUNCTION HumanResources.EmployeeNames;
DROP TABLE HumanResources.Employee;
GO


--  ОБРАБОТКА ОШИБОК

--  TRY...CATCH
--  Блок TRY — код, который потенциально может вызвать ошибку.
--  Блок CATCH — код, выполняемый при ошибке в TRY.
--  CATCH должен начинаться СРАЗУ после END TRY, без промежуточных операторов.
--  Пример недопустимой конструкции:
--    END TRY
--    SELECT * FROM ... ← так нельзя
--    BEGIN CATCH

CREATE TABLE dbo.TableWithKey (
    ColA INT PRIMARY KEY,
    ColB INT
);
GO

CREATE PROCEDURE dbo.AddData
    @a INT,
    @b INT
AS
    BEGIN TRY
        INSERT INTO dbo.TableWithKey VALUES (@a, @b);
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER()  AS ErrorNumber,
            ERROR_MESSAGE() AS [Message];
    END CATCH;
GO

EXEC dbo.AddData 1, 1;   -- успех
EXEC dbo.AddData 2, 2;   -- успех
EXEC dbo.AddData 1, 3;   -- нарушение PK → уходит в CATCH

SELECT 'Таблица после трёх вызовов (строки 1 и 2):' AS Info;
SELECT * FROM dbo.TableWithKey;
GO

-- Очистка
DROP PROC dbo.AddData;
DROP TABLE dbo.TableWithKey;
GO


-- ----------------------------------------------------------------
--  ВСЕ ФУНКЦИИ ERROR_xxx
--  Доступны только внутри блока CATCH.
--
--  ERROR_LINE()      — строка, на которой произошла ошибка
--  ERROR_MESSAGE()   — текст диагностического сообщения
--  ERROR_NUMBER()    — уникальный номер ошибки
--  ERROR_PROCEDURE() — имя процедуры / триггера, где возникла ошибка
--  ERROR_SEVERITY()  — критичность: 1–2 = информация, высокие = серьёзные проблемы
--  ERROR_STATE()     — уникальный статус конкретного условия ошибки

CREATE TABLE dbo.ErrorDemoTable (
    ID  INT PRIMARY KEY,
    Val INT NOT NULL CONSTRAINT [CK_Val_Positive] CHECK (Val > 0)
);
GO

CREATE PROCEDURE dbo.DemoErrors
    @id  INT,
    @val INT
AS
    BEGIN TRY
        INSERT INTO dbo.ErrorDemoTable VALUES (@id, @val);
        PRINT 'Вставка прошла успешно.';
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER()    AS ErrorNumber,
            ERROR_SEVERITY()  AS Severity,
            ERROR_STATE()     AS [State],
            ERROR_LINE()      AS [Line],
            ERROR_PROCEDURE() AS [Procedure],
            ERROR_MESSAGE()   AS [Message];
    END CATCH;
GO

-- нарушение CHECK (Val > 0)
SELECT 'Нарушение CHECK (Val <= 0) — все ERROR_xxx:' AS Info;
EXEC dbo.DemoErrors 1, -5;

-- нарушение PRIMARY KEY
EXEC dbo.DemoErrors 1, 10;    -- успех
SELECT 'Нарушение PRIMARY KEY (дубликат ID=1):' AS Info;
EXEC dbo.DemoErrors 1, 20;
GO

-- Очистка
DROP PROC dbo.DemoErrors;
DROP TABLE dbo.ErrorDemoTable;
GO


-- ----------------------------------------------------------------
--  ОТКАТ ТРАНЗАКЦИЙ
--  Транзакция гарантирует атомарность: либо все операции выполняются, либо ни одна.
--  BEGIN TRAN + COMMIT TRAN внутри TRY.
--  ROLLBACK TRAN внутри CATCH отменяет все операции транзакции.
--
--  БЕЗ транзакции:
--    первая вставка проходит даже когда вторая падает — данные расходятся.
--  С транзакцией:
--    при ошибке откатываются обе вставки — данные остаются согласованными.

CREATE TABLE dbo.TableNoKey   (ColA INT,     ColB INT);
CREATE TABLE dbo.TableWithKey (ColA INT PRIMARY KEY, ColB INT);
GO

-- ── БЕЗ транзакции ────────────────────────────────────────────
CREATE PROCEDURE dbo.AddDataNoTran
    @a INT,
    @b INT
AS
    BEGIN TRY
        INSERT INTO dbo.TableNoKey   VALUES (@a, @b);
        INSERT INTO dbo.TableWithKey VALUES (@a, @b);   -- может упасть по PK
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER()  AS ErrorNumber,
               ERROR_MESSAGE() AS [Message];
    END CATCH;
GO

EXEC dbo.AddDataNoTran 1, 1;
EXEC dbo.AddDataNoTran 2, 2;
EXEC dbo.AddDataNoTran 1, 3;   -- нарушение PK, но первая INSERT уже прошла

SELECT 'TableNoKey без транзакции (3 строки — первая вставка прошла несмотря на ошибку):' AS Info;
SELECT * FROM dbo.TableNoKey;

SELECT 'TableWithKey без транзакции (2 строки — дубликат отклонён):' AS Info;
SELECT * FROM dbo.TableWithKey;
GO

TRUNCATE TABLE dbo.TableNoKey;
TRUNCATE TABLE dbo.TableWithKey;
GO

-- ── С транзакцией ─────────────────────────────────────────────
CREATE PROCEDURE dbo.AddDataWithTran
    @a INT,
    @b INT
AS
    BEGIN TRY
        BEGIN TRAN;
            INSERT INTO dbo.TableNoKey   VALUES (@a, @b);
            INSERT INTO dbo.TableWithKey VALUES (@a, @b);
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        SELECT ERROR_NUMBER()  AS ErrorNumber,
               ERROR_MESSAGE() AS [Message];
    END CATCH;
GO

EXEC dbo.AddDataWithTran 1, 1;
EXEC dbo.AddDataWithTran 2, 2;
EXEC dbo.AddDataWithTran 1, 3;   -- нарушение PK → ROLLBACK обеих вставок

SELECT 'TableNoKey с транзакцией (2 строки — третий вызов полностью откатился):' AS Info;
SELECT * FROM dbo.TableNoKey;

SELECT 'TableWithKey с транзакцией (2 строки):' AS Info;
SELECT * FROM dbo.TableWithKey;
GO

-- Очистка
DROP PROC dbo.AddDataNoTran;
DROP PROC dbo.AddDataWithTran;
DROP TABLE dbo.TableNoKey;
DROP TABLE dbo.TableWithKey;
GO


-- ----------------------------------------------------------------
--  XACT_ABORT И XACT_STATE
--  XACT_ABORT ON — при ошибке в блоке TRY транзакция не откатывается автоматически,
--    а помечается как uncommittable (незавершённая).
--  XACT_STATE() = -1 → незавершённая транзакция: только ROLLBACK.
--  XACT_STATE() =  1 → активная транзакция: можно COMMIT или ROLLBACK.
--  XACT_STATE() =  0 → нет активной транзакции.
--  В блоке CATCH нужно проверять XACT_STATE() и принимать решение о откате / фиксации.

CREATE TABLE dbo.XactDemo (
    ID   INT PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL
);
GO

CREATE PROCEDURE dbo.XactStateDemo
    @id   INT,
    @name NVARCHAR(50)
AS
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;
            INSERT INTO dbo.XactDemo VALUES (@id, @name);
            DECLARE @x INT = 1 / 0;   -- умышленная ошибка (деление на ноль)
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SELECT
            XACT_STATE()    AS XactState,       -- ожидается -1
            ERROR_NUMBER()  AS ErrorNumber,
            ERROR_MESSAGE() AS [Message];

        IF (XACT_STATE()) = -1
        BEGIN
            PRINT 'XACT_STATE = -1: транзакция незавершённая → ROLLBACK';
            ROLLBACK TRAN;
        END
        ELSE IF (XACT_STATE()) = 1
        BEGIN
            PRINT 'XACT_STATE = 1: транзакция активна → COMMIT';
            COMMIT TRAN;
        END
        ELSE
            PRINT 'XACT_STATE = 0: нет активной транзакции';
    END CATCH;
GO

SELECT 'XactDemo ДО вызова (пусто):' AS Info;
SELECT * FROM dbo.XactDemo;

EXEC dbo.XactStateDemo 1, N'Тестовая строка';

SELECT 'XactDemo ПОСЛЕ (строка не должна быть сохранена — откат):' AS Info;
SELECT * FROM dbo.XactDemo;
GO

-- XACT_STATE без XACT_ABORT для сравнения: транзакция будет committable
CREATE PROCEDURE dbo.XactStateNoAbort
AS
    -- XACT_ABORT OFF (по умолчанию)
    BEGIN TRY
        BEGIN TRAN;
            INSERT INTO dbo.XactDemo VALUES (10, N'Без XACT_ABORT');
            -- без XACT_ABORT ON ошибка не переводит транзакцию в -1
            -- SELECT 1/0; — раскомментировать для проверки
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SELECT XACT_STATE() AS XactState_NoAbort;

        IF (XACT_STATE()) = -1
            ROLLBACK TRAN;
        ELSE IF (XACT_STATE()) = 1
            COMMIT TRAN;
    END CATCH;
GO

EXEC dbo.XactStateNoAbort;

SELECT 'XactDemo после успешной вставки без XACT_ABORT:' AS Info;
SELECT * FROM dbo.XactDemo;
GO

-- Очистка
DROP PROC dbo.XactStateDemo;
DROP PROC dbo.XactStateNoAbort;
DROP TABLE dbo.XactDemo;
GO


--  УПРАВЛЕНИЕ КОНТЕКСТОМ ВЫПОЛНЕНИЯ


--  Контекст выполнения — идентичность (пользователь), от имени которой
--  проверяются разрешения при выполнении процедуры / функции.
--  По умолчанию — вызывающий пользователь (CALLER).
--  EXECUTE AS переключает контекст в пределах текущей БД.
--  REVERT — возврат к предыдущему контексту.
--
--  Опции EXECUTE AS:
--    CALLER   — идентичность вызывающего (по умолчанию).
--    SELF     — идентичность пользователя, создавшего / изменившего модуль.
--               Не меняется при смене владельца.
--    OWNER    — идентичность текущего владельца модуля.
--               Меняется при передаче модуля другому пользователю.
--    user_name — явно указанный пользователь БД.
--
--  Цепочка владения (ownership chain):
--    Если таблица и процедура принадлежат РАЗНЫМ владельцам, цепочка разрывается
--    и права на таблицу проверяются у вызывающего.
--    WITH EXECUTE AS 'user_name' решает эту проблему без прямого доступа к таблице.
--
--  Контекст олицетворения по умолчанию работает только в рамках текущей БД.
--  Для межбазового олицетворения — TRUSTWORTHY ON + GRANT AUTHENTICATE.

-- общая таблица для логирования контекста
CREATE TABLE dbo.ContextLog (
    LogID      INT           NOT NULL IDENTITY(1,1),
    Option     NVARCHAR(20)  NOT NULL,
    UserName   NVARCHAR(128) NOT NULL,
    RecordedAt DATETIME      NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_ContextLog] PRIMARY KEY ([LogID])
);
GO

-- пользователи без логина (только в рамках этой БД)
CREATE USER [AppUser]      WITHOUT LOGIN;
CREATE USER [LimitedUser]  WITHOUT LOGIN;
GO

-- AppUser нужен INSERT на ContextLog (для демонстрации EXECUTE AS 'AppUser')
GRANT INSERT ON dbo.ContextLog TO [AppUser];
GO


-- EXECUTE AS CALLER
-- Код выполняется от имени того, кто вызвал процедуру.
-- Это поведение по умолчанию — CALLER.

CREATE PROCEDURE dbo.LogContext_Caller
WITH EXECUTE AS CALLER
AS
    INSERT INTO dbo.ContextLog (Option, UserName)
    VALUES (N'CALLER', USER_NAME());
GO

EXEC dbo.LogContext_Caller;

SELECT 'CALLER — контекст вызывающего пользователя:' AS Info;
SELECT * FROM dbo.ContextLog;
GO

DELETE FROM dbo.ContextLog;
GO


-- EXECUTE AS SELF
-- Код выполняется от имени пользователя, который СОЗДАЛ или изменил модуль.
-- Значение фиксируется в момент CREATE/ALTER и не меняется при смене владельца.

CREATE PROCEDURE dbo.LogContext_Self
WITH EXECUTE AS SELF      -- контекст = создатель процедуры
AS
    INSERT INTO dbo.ContextLog (Option, UserName)
    VALUES (N'SELF', USER_NAME());
GO

EXEC dbo.LogContext_Self;

SELECT 'SELF — контекст создателя процедуры:' AS Info;
SELECT * FROM dbo.ContextLog;
GO

DELETE FROM dbo.ContextLog;
GO


-- EXECUTE AS OWNER
-- Код выполняется от имени текущего владельца модуля.
-- Меняется, если процедуру передают другому пользователю (ALTER AUTHORIZATION).

CREATE PROCEDURE dbo.LogContext_Owner
WITH EXECUTE AS OWNER     -- контекст = текущий владелец модуля
AS
    INSERT INTO dbo.ContextLog (Option, UserName)
    VALUES (N'OWNER', USER_NAME());
GO

EXEC dbo.LogContext_Owner;

SELECT 'OWNER — контекст владельца модуля:' AS Info;
SELECT * FROM dbo.ContextLog;
GO

DELETE FROM dbo.ContextLog;
GO


-- EXECUTE AS 'user_name'
-- Код выполняется от имени явно указанного пользователя БД.
-- Решает проблему разрыва цепочки владения:
-- пользователь Tad вызывает процедуру → внутри она работает как AppUser
-- AppUser имеет SELECT на таблицу → доступ разрешён.
-- Tad не получает прямого доступа к таблице.

-- таблица, доступная только AppUser
CREATE TABLE dbo.SecureData (
    ID   INT          NOT NULL IDENTITY(1,1),
    Data NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_SecureData] PRIMARY KEY ([ID])
);
GO

INSERT INTO dbo.SecureData (Data) VALUES (N'Секретные данные 1'), (N'Секретные данные 2');
GO

-- AppUser получает SELECT на таблицу и INSERT на лог (уже выдан выше)
GRANT SELECT ON dbo.SecureData TO [AppUser];
GO

-- процедура переключается на AppUser, который имеет нужные права
CREATE PROCEDURE dbo.GetSecureData
WITH EXECUTE AS 'AppUser'   -- контекст = AppUser
AS
    INSERT INTO dbo.ContextLog (Option, UserName)
    VALUES (N'user_name', USER_NAME());   -- USER_NAME() покажет AppUser

    SELECT * FROM dbo.SecureData;
GO

-- LimitedUser прямого доступа к SecureData не имеет,
-- но через процедуру (работающую как AppUser) данные получает
GRANT EXECUTE ON dbo.GetSecureData TO [LimitedUser];
GO

SELECT 'Данные через EXECUTE AS AppUser:' AS Info;
EXEC dbo.GetSecureData;

SELECT 'Контекст внутри процедуры (должен быть AppUser):' AS Info;
SELECT * FROM dbo.ContextLog;
GO

DELETE FROM dbo.ContextLog;
GO


-- REVERT — возврат к предыдущему контексту
-- EXECUTE AS как самостоятельный оператор (вне процедуры)
-- временно переключает контекст до выполнения REVERT.

INSERT INTO dbo.ContextLog (Option, UserName)
VALUES (N'Before EXEC AS', USER_NAME());   -- dbo до переключения

-- переключение на LimitedUser
EXECUTE AS USER = 'LimitedUser';
INSERT INTO dbo.ContextLog (Option, UserName)
VALUES (N'Inside EXEC AS', USER_NAME());   -- LimitedUser

-- возврат к исходному контексту
REVERT;
INSERT INTO dbo.ContextLog (Option, UserName)
VALUES (N'After REVERT', USER_NAME());     -- снова dbo

SELECT 'Смена контекста: EXECUTE AS USER + REVERT:' AS Info;
SELECT LogID, Option, UserName, RecordedAt
FROM   dbo.ContextLog
ORDER BY LogID;
GO


-- TRUSTWORTHY (межбазовое олицетворение)
-- По умолчанию EXECUTE AS работает только в текущей БД.
-- Для межбазового олицетворения:
-- 1. Вызывающая БД должна быть помечена TRUSTWORTHY ON.
-- 2. В целевой БД создаётся пользователь с тем же логином, что и dbo.
-- 3. Этому пользователю выдаётся GRANT AUTHENTICATE.

SELECT 'TRUSTWORTHY текущей БД (OFF по умолчанию):' AS Info;
SELECT name, is_trustworthy_on
FROM   sys.databases
WHERE  name = DB_NAME();
GO

-- включение TRUSTWORTHY (первый шаг для межбазового олицетворения)
ALTER DATABASE [T-SQL_lab_7_proc_func] SET TRUSTWORTHY ON;
GO

SELECT 'TRUSTWORTHY после ALTER DATABASE SET TRUSTWORTHY ON:' AS Info;
SELECT name, is_trustworthy_on
FROM   sys.databases
WHERE  name = DB_NAME();
GO

-- возврат в OFF (по соображениям безопасности TRUSTWORTHY оставлять ON не рекомендуется)
ALTER DATABASE [T-SQL_lab_7_proc_func] SET TRUSTWORTHY OFF;
GO



-- Подписание модуля сертификатом (ADD SIGNATURE)
-- Альтернатива TRUSTWORTHY: сертификат как аутентификатор.
-- Преимущество: доверие привязано к конкретному сертификату,
-- а не ко всей вызывающей БД целиком.
--
--  Шаги:
--  1. CREATE CERTIFICATE в вызывающей БД.
--  2. ADD SIGNATURE — подписываем процедуру этим сертификатом.
--  3. Копируем публичную часть сертификата в целевую БД.
--  4. CREATE USER ... FROM CERTIFICATE в целевой БД.
--  5. GRANT нужных прав этому пользователю в целевой БД.

-- вторая БД (целевая)
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'T-SQL_lab_7_target')
BEGIN
    ALTER DATABASE [T-SQL_lab_7_target] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [T-SQL_lab_7_target];
END
GO

CREATE DATABASE [T-SQL_lab_7_target];
GO

-- таблица в целевой БД, к которой нужен доступ из вызывающей
USE [T-SQL_lab_7_target];
GO

CREATE TABLE dbo.TargetData (
    ID   INT          NOT NULL IDENTITY(1,1),
    Info NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_TargetData] PRIMARY KEY ([ID])
);
GO

INSERT INTO dbo.TargetData (Info) VALUES
    (N'Строка из целевой БД — 1'),
    (N'Строка из целевой БД — 2');
GO


-- Шаг 1: CREATE CERTIFICATE в вызывающей БД
USE [T-SQL_lab_7_proc_func];
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'YourStr0ngP@ssword!';
GO

CREATE CERTIFICATE CrossDbCert
    WITH SUBJECT = N'Сертификат для межбазового доступа',
         EXPIRY_DATE = '2026-12-12';
GO


-- Шаг 2: процедура, которую будем подписывать
-- Внутри — обращение к таблице в целевой БД.
-- Без подписи / TRUSTWORTHY вызов упадёт из-за недопустимого контекста.

CREATE PROCEDURE dbo.ReadTargetData
WITH EXECUTE AS SELF      -- выполняется от имени создателя процедуры
AS
    SELECT * FROM [T-SQL_lab_7_target].dbo.TargetData;
GO

-- ADD SIGNATURE — «подписываем» процедуру сертификатом
ADD SIGNATURE TO dbo.ReadTargetData BY CERTIFICATE CrossDbCert;
GO


-- Шаг 3: копирование публичной части сертификата в целевую БД
-- выгрузка публичной части в переменную,
-- затем создаём идентичный сертификат в целевой БД.
-- (В реальном окружении через BACKUP CERTIFICATE ... TO FILE
-- здесь прямое копирование через CERTENCODED для простоты.)

DECLARE @certBin  VARBINARY(MAX) = CERTENCODED(CERT_ID('CrossDbCert'));
DECLARE @sql      NVARCHAR(MAX);

SET @sql = N'
    IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = N''CrossDbCert_Copy'')
        DROP CERTIFICATE CrossDbCert_Copy;

    CREATE CERTIFICATE CrossDbCert_Copy
        FROM BINARY = ' + CONVERT(NVARCHAR(MAX), @certBin, 1) + N';
';

EXEC [T-SQL_lab_7_target].sys.sp_executesql @sql;
GO


-- Шаг 4: CREATE USER FROM CERTIFICATE в целевой БД
EXEC [T-SQL_lab_7_target].sys.sp_executesql
    N'
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''CertUser'')
        DROP USER CertUser;

    CREATE USER CertUser FROM CERTIFICATE CrossDbCert_Copy;
    ';
GO


-- Шаг 5: GRANT нужных прав пользователю сертификата
EXEC [T-SQL_lab_7_target].sys.sp_executesql
    N'GRANT SELECT ON dbo.TargetData TO CertUser;';
GO

-- GRANT AUTHENTICATE — разрешает сертификатному пользователю
-- валидировать контекст олицетворения в целевой БД
EXEC [T-SQL_lab_7_target].sys.sp_executesql
    N'GRANT AUTHENTICATE TO CertUser;';
GO


-- Проверка: вызов процедуры
SELECT 'Данные из целевой БД через подписанную процедуру:' AS Info;
EXEC dbo.ReadTargetData;
GO

-- сертификат и подпись видны в системных представлениях
SELECT 'Сертификат в вызывающей БД:' AS Info;
SELECT name, subject, expiry_date
FROM   sys.certificates
WHERE  name = N'CrossDbCert';

SELECT 'Подпись на процедуре:' AS Info;
SELECT
    OBJECT_NAME(cp.major_id) AS ProcedureName,
    c.name                   AS CertificateName,
    cp.class_desc            AS SignedObjectType
FROM  sys.crypt_properties cp
JOIN  sys.certificates     c  ON c.thumbprint = cp.thumbprint
WHERE OBJECT_NAME(cp.major_id) = N'ReadTargetData';
GO


-- Очистка
USE [T-SQL_lab_7_proc_func];
GO

DROP PROC  dbo.ReadTargetData;
DROP CERTIFICATE CrossDbCert;
DROP MASTER KEY;
GO

DROP CERTIFICATE CrossDbCert;
GO

USE master;
GO

ALTER DATABASE [T-SQL_lab_7_target] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [T-SQL_lab_7_target];
GO


-- Очистка всего
DROP PROC dbo.LogContext_Caller;
DROP PROC dbo.LogContext_Self;
DROP PROC dbo.LogContext_Owner;
DROP PROC dbo.GetSecureData;
DROP TABLE dbo.SecureData;
DROP TABLE dbo.ContextLog;
DROP USER  [AppUser];
DROP USER  [LimitedUser];
GO