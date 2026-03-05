

/* 
0
*/

DECLARE @xml0 XML
DECLARE @h0 INT

SET @xml0 = '
<Store>
  <Product id="1" name="Keyboard" category="Peripherals" price="2500.00" stock="15"/>
  <Product id="2" name="Mouse" category="Peripherals" price="1200.00" stock="30"/>
  <Product id="3" name="Monitor" category="Peripherals" price="15000.00" stock="8"/>
  <Product id="4" name="USB Cable" category="Accessories" price="500.00" stock="100"/>
  <Product id="5" name="HDMI Cable" category="Accessories" price="800.00" stock="60"/>
</Store>'

EXEC sp_xml_preparedocument @h0 OUTPUT, @xml0


SELECT *
FROM OPENXML(@h0, '/Store/Product', 0)
WITH (
    ProductID INT '@id',
    Name NVARCHAR(50) '@name',
    Category NVARCHAR(50) '@category',
    Price DECIMAL(10,2) '@price',
    Stock INT '@stock'
)

EXEC sp_xml_removedocument @h0
GO



/*
1
*/

DECLARE @xml1 XML
DECLARE @h1 INT

SET @xml1 = '
<Company>
  <Employee ID="1" Name="Ivan Petrov" Position="Manager" Salary="1500" Department="Sales"/>
  <Employee ID="2" Name="Petr Ivanov" Position="Analyst" Salary="900" Department="Finance"/>
  <Employee ID="3" Name="Anna Smirnova" Position="Developer" Salary="2000" Department="IT"/>
  <Employee ID="4" Name="Oleg Sidorov" Position="Support" Salary="800" Department="IT"/>
</Company>'

EXEC sp_xml_preparedocument @h1 OUTPUT, @xml1

SELECT *
FROM OPENXML(@h1, '/Company/Employee', 1)
WITH (
    EmployeeID INT '@ID',
    FullName NVARCHAR(100) '@Name',
    Position NVARCHAR(50) '@Position',
    Salary MONEY '@Salary',
    Department NVARCHAR(50) '@Department'
)

EXEC sp_xml_removedocument @h1
GO



/*
2
*/

DECLARE @xml2 XML
DECLARE @h2 INT

SET @xml2 = '
<Orders>
  <Order>
    <OrderID>1001</OrderID>
    <Customer>Ivan Petrov</Customer>
    <City>Moscow</City>
    <Total>3500.00</Total>
  </Order>
  <Order>
    <OrderID>1002</OrderID>
    <Customer>Petr Ivanov</Customer>
    <City>Saint Petersburg</City>
    <Total>1200.00</Total>
  </Order>
  <Order>
    <OrderID>1003</OrderID>
    <Customer>Anna Smirnova</Customer>
    <City>Kazan</City>
    <Total>8700.00</Total>
  </Order>
</Orders>'

EXEC sp_xml_preparedocument @h2 OUTPUT, @xml2

SELECT *
FROM OPENXML(@h2, '/Orders/Order', 2)
WITH (
    OrderID INT 'OrderID',
    Customer NVARCHAR(100) 'Customer',
    City NVARCHAR(50) 'City',
    Total DECIMAL(10,2) 'Total'
)

EXEC sp_xml_removedocument @h2
GO



/*
8
*/

DECLARE @xml8 XML
DECLARE @h8 INT

SET @xml8 = '
<Library>
  <Book id="1" isbn="9780001">
    <Title>SQL Basics</Title>
    <Author>Ivan Petrov</Author>
    <Year>2020</Year>
    <Price>1200.00</Price>
  </Book>
  <Book id="2" isbn="9780002">
    <Title>XML Advanced</Title>
    <Author>Petr Ivanov</Author>
    <Year>2022</Year>
    <Price>1800.00</Price>
  </Book>
  <Book id="3" isbn="9780003">
    <Title>Database Design</Title>
    <Author>Anna Smirnova</Author>
    <Year>2021</Year>
    <Price>2200.00</Price>
  </Book>
</Library>'

EXEC sp_xml_preparedocument @h8 OUTPUT, @xml8

SELECT *
FROM OPENXML(@h8, '/Library/Book', 8)
WITH (
    BookID INT '@id',
    ISBN NVARCHAR(20) '@isbn',
    Title NVARCHAR(100) 'Title',
    Author NVARCHAR(100) 'Author',
    Year INT 'Year',
    Price DECIMAL(10,2) 'Price'
)

EXEC sp_xml_removedocument @h8
GO