/***
Yijun Zhang
1.	Create a stored procedure named spPriceRange that accepts two optional parameters. 
The procedure should return a result set consisting of Product Id, Product Name, Product Description, 
and List Price from the product and product description tables for each product within the price range, 
sorted with largest price first. The parameter @PriceMin and @PriceMax are parameters used to specify the 
requested range of prices. If the minimum price is not provided use the minimum non-zero price in the product table. 
If the maximum price is not provided use the maximum price in the product table.
***/

use AdventureWorks;
go

create procedure spPriceRange 
	@PriceMin money,
	@PriceMax money
as
begin
	if @PriceMin is null
		BEGIN
		select p.Name Product_Name, d.Description, p.ListPrice
		from Production.Product p
			join Production.ProductModel m
				on p.ProductModelID = m.ProductModelID
			join Production.ProductModelProductDescriptionCulture dc
				on m.ProductModelID = dc.ProductModelID
			join Production.ProductDescription d
				on dc.ProductDescriptionID = d.ProductDescriptionID
		where p.ListPrice > (select MIN(ListPrice) from Production.Product where ListPrice <> 0) and
				p.ListPrice < @PriceMax
		END

	if @PriceMax is null 
		BEGIN
		select p.Name Product_Name, d.Description, p.ListPrice
		from Production.Product p
			join Production.ProductModel m
				on p.ProductModelID = m.ProductModelID
			join Production.ProductModelProductDescriptionCulture dc
				on m.ProductModelID = dc.ProductModelID
			join Production.ProductDescription d
				on dc.ProductDescriptionID = d.ProductDescriptionID
		where p.ListPrice > @PriceMin and
				p.ListPrice < (select Max(ListPrice) from Production.Product)
		END

	if @PriceMax is not null and @PriceMin is not null
		BEGIN
		select p.Name Product_Name, d.Description, p.ListPrice
		from Production.Product p
			join Production.ProductModel m
				on p.ProductModelID = m.ProductModelID
			join Production.ProductModelProductDescriptionCulture dc
				on m.ProductModelID = dc.ProductModelID
			join Production.ProductDescription d
				on dc.ProductDescriptionID = d.ProductDescriptionID
		where p.ListPrice > @PriceMin and
				p.ListPrice < @PriceMax
		END;
end;


/***
2.	Code calls to the stored procedure created in exercise 1 that returns products with a price 
a.	between $100 and $300. 
b.	Below $1000 (do not specify a minimum value)
c.	Above $1000 (do not specify a maximum value)
***/

exec spPriceRange @PriceMin = 100, @PriceMax = 300;

exec spPriceRange @PriceMin = null, @PriceMax = 1000;

exec spPriceRange @PriceMin = 1000, @PriceMax = null;


/***
3.	Create a user-defined function fnSalesPersonName that will return for any sales 
order header the name of the sales person (concatenated string containing First, Middle and Last Name) 
of the salesperson associated with a sales order id (or ¡®N/A¡¯ if there is no salesperson) retrieved 
from the person table as specified in the SalesOrderHeader table. The parameter should be the sales 
order id with the function returning a string containing the appropriate sales person¡¯s name. 
***/

create function fnSalesPersonName
	(@SalesOrderID int)
returns nvarchar(50)
as
begin
	declare @name varchar(50); 
	select @name = p.FirstName + ' ' + p.MiddleName + ' ' + p.LastName
	from Person.Person p
		join Sales.SalesPerson sp
			on p.BusinessEntityID = sp.BusinessEntityID
		join Sales.SalesOrderHeader sh
			on sp.BusinessEntityID = sh.SalesPersonID
	where sh.SalesOrderID = @SalesOrderID
	return isnull(@name, 'N/A')
	end;

/***
4.	Code calls to the function created in exercise 3 that returns the sales order id and 
associated salesperson id for a variety of orders.
***/

select dbo.fnSalesPersonName(43727) as Name;

select dbo.fnSalesPersonName(44286) as Name;

select dbo.fnSalesPersonName(44512) as Name;

23153.2339
/***
5.	Create an update trigger that will update the modified date of a record in the salesorderheader 
table to the current date in the event of an update to a record in that table. 
***/

create trigger salesorderheaderUpdateTR
on Sales.SalesOrderHeader
after update
as 
	begin
		update sales.SalesOrderHeader
			set ModifiedDate = GETDATE()
		where Sales.SalesOrderHeader.SalesOrderID = (SELECT inserted.[SalesOrderID] FROM inserted)
	end;



/***
6.	Code calls to update one or records in the sales order header table. Query the affected records to verify the modified date has been appropriately updated.
***/
update Sales.SalesOrderHeader
set Comment = 'M16 assignment'
where SalesOrderID = 43659;




/***
7.	Write a SELECT statement that returns an XML document that contains all of the sales orders in the sales order header table 
that have more than one line item in the sales order detail table. This document should include one element for each record in the sales order header 
(sales order id. Sales order number and order date), and one nested element for each corresponding record in the sales order detail table 
(sales order detail id, product id, and order quantity).
***/

select  SalesOrderID, SalesOrderNumber, OrderDate
from Sales.SalesOrderHeader
FOR XML auto

select SalesOrderDetailID, ProductID, OrderQty
from Sales.SalesOrderDetail
for XML auto

select top 10 SalesOrderID, SalesOrderNumber, OrderDate,
	(select top 2 SalesOrderDetailID, ProductID, OrderQty
	from Sales.SalesOrderDetail 
	where Sales.SalesOrderDetail.SalesOrderID = Sales.SalesOrderHeader.SalesOrderID
	for XML auto, type) Sales_order_detail
from Sales.SalesOrderHeader
for XML auto, type