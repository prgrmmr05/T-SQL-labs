  USE [T-SQL_lab_3_Shop];
GO

DROP TABLE IF EXISTS Items;

CREATE TABLE Items (
    ItemId INT IDENTITY PRIMARY KEY,
    Title NVARCHAR(150) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL
);

INSERT INTO Items (Title, Cost, Stock) VALUES
('Smartphone', 45000.00, 8),
('Headphones', 3500.00, 25),
('Tablet', 38000.00, 6);

-- Исходная таблица
SELECT * FROM Items;

DECLARE @data XML = (
    SELECT Title, Cost, Stock
    FROM Items
    FOR XML PATH('Item'), ROOT('Inventory'), TYPE
);

-- XML после формирования
SELECT @data AS XML_After_Creation;


-- Удалить Headphones

IF @data.exist('/Inventory/Item[Title = "Headphones"]') = 1
BEGIN
    SET @data.modify('delete (/Inventory/Item[Title = "Headphones"])[1]');
END

SELECT @data AS XML_After_Delete_Headphones;

-- Изменить Smartphone

IF @data.exist('/Inventory/Item[Title = "Smartphone"]') = 1
BEGIN
    DECLARE @phoneCost DECIMAL(10,2) =
        @data.value('(/Inventory/Item[Title="Smartphone"]/Cost)[1]', 'DECIMAL(10,2)');

    DECLARE @phoneStock INT =
        @data.value('(/Inventory/Item[Title="Smartphone"]/Stock)[1]', 'INT');

    SET @data.modify('delete (/Inventory/Item[Title="Smartphone"])[1]');

    SET @data.modify('
        insert <Item>
                 <Title>Smartphone</Title>
                 <Cost>{sql:variable("@phoneCost") * 1.5}</Cost>
                 <Stock>{sql:variable("@phoneStock") + 3}</Stock>
               </Item>
        as last into (/Inventory)[1]
    ');
END

SELECT @data AS XML_After_Update_Smartphone;


-- Добавить Printer

SET @data.modify('
    insert <Item>
             <Title>Printer</Title>
             <Cost>22000.00</Cost>
             <Stock>10</Stock>
           </Item>
    as last into (/Inventory)[1]
');

SET @data.modify('
    replace value of (/Inventory/Item[Title="Printer"]/Cost/text())[1]
    with 18000
');

SELECT @data AS XML_After_Insert_Printer;


-- Фильтрация XML

SELECT @data.query('/Inventory/Item[Title = "Tablet" or Title = "Printer"]')
       AS XML_Filter_Tablet_Printer;


-- Перезаполнить таблицу

TRUNCATE TABLE Items;

INSERT INTO Items (Title, Cost, Stock)
SELECT
    X.c.value('(Title/text())[1]', 'NVARCHAR(150)'),
    X.c.value('(Cost/text())[1]', 'DECIMAL(10,2)'),
    X.c.value('(Stock/text())[1]', 'INT')
FROM @data.nodes('/Inventory/Item') AS X(c);

-- Таблица после восстановления
SELECT * FROM Items;
