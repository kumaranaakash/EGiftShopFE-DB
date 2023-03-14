CREATE DATABASE EGiftshop;
USE EGiftshop;

CREATE TABLE Users(ID INT IDENTITY(1,1) PRIMARY KEY, FirstName VARCHAR(100), LastName VARCHAR(100), Password VARCHAR(100),
Email VARCHAR(100), Fund DECIMAL(18,2), Type VARCHAR(100), Status INT, CreatedOn Datetime);

CREATE TABLE Products(ID INT IDENTITY(1,1) PRIMARY KEY, Name VARCHAR(100), UnitPrice DECIMAL(18,2),
Discount DECIMAL(18,2), Quantity INT, ImageUrl VARCHAR(1000), Status INT)

CREATE TABLE Cart(ID INT IDENTITY(1,1) PRIMARY KEY, UserId INT, ProductID INT, UnitPrice DECIMAL(18,2), Discount DECIMAL(18,2),
Quantity INT, TotalPrice DECIMAL(18,2))

CREATE TABLE Orders(ID INT IDENTITY(1,1) PRIMARY KEY, UserID INT, OrderNo VARCHAR(100), OrderTotal DECIMAL(18,2), OrderStatus VARCHAR(100),
CreatedOn DATETIME)

CREATE TABLE OrderItems(ID INT IDENTITY(1,1) PRIMARY KEY, OrderID INT, ProductID INT, UnitPrice DECIMAL(18,2), Discount DECIMAL(18,2),
Quantity INT ,TotalPrice DECIMAL(18,2));

INSERT INTO Users(FirstName, LastName, Email, Password, Type,Status,CreatedOn)
VALUES('admin','admin','admin','admin','admin',1,GETDATE())

SELECT * FROM Users;
SELECT * FROM Cart;
SELECT * FROM Products;
SELECT * FROM Orders;
SELECT * FROM OrderItems;
Select * From Products;


--DELETE FROM Cart;
--DELETE FROM Orders;
--DELETE FROM OrderItems;

UPDATE OrderItems SET ProductID = 15 WHERE ID =14;  
UPDATE OrderItems SET ProductID = 16 WHERE ID =15;
UPDATE OrderItems SET ProductID = 17 WHERE ID =16;
UPDATE OrderItems SET ProductID = 18 WHERE ID =17;
UPDATE OrderItems SET ProductID = 19 WHERE ID =18;

  EXEC sp_viewUser 0,'Email' 
  UPDATE CART SET ProductID = 9 WHERE ID = 1; UPDATE CART SET ProductID = 10 WHERE ID = 2;
  UPDATE CART SET ProductID = 13 WHERE ID = 3; UPDATE CART SET ProductID = 14 WHERE ID = 4;
  INSERT INTO Cart(UserId,ProductID,UnitPrice,Discount,Quantity,TotalPrice) VALUES(1,1,100,5,10,450);	
  INSERT INTO Cart(UserId,ProductID,UnitPrice,Discount,Quantity,TotalPrice) VALUES(1,2,50,10,5,237.5);	
  INSERT INTO Cart(UserId,ProductID,UnitPrice,Discount,Quantity,TotalPrice) VALUES(2,1,100,5,1,500);	
  INSERT INTO Cart(UserId,ProductID,UnitPrice,Discount,Quantity,TotalPrice) VALUES(2,2,200,10,2,360);	
 

GO

CREATE PROC sp_register
(
  @ID INT = NULL, 
  @FirstName VARCHAR(100) = NULL, 
  @LastName VARCHAR(100) = NULL, 
  @Password VARCHAR(100) = NULL,
  @Email VARCHAR(100) = NULL, 
  @Fund DECIMAL(18,2) = NULL, 
  @Type VARCHAR(100) = NULL, 
  @Status INT = NULL, 
  @ActionType VARCHAR(100) = NULL
)

AS
BEGIN
	IF @ActionType = 'Add'
	BEGIN
		INSERT INTO Users(FirstName,LastName,Password,Email,Fund,Type,Status,CreatedOn)
		VALUES(@FirstName,@LastName,@Password,@Email,@Fund,@Type,@Status,GETDATE())
	END
	IF @ActionType = 'Update'
	BEGIN
		UPDATE Users SET FirstName = @FirstName,LastName = @LastName,Password = @Password
		WHERE Email = @Email;
	END
	IF @ActionType = 'AddFund'
	BEGIN
		UPDATE Users SET Fund = @Fund WHERE Email = @Email;
	END
END;
go
CREATE PROC sp_login(@Email VARCHAR(100), @Password VARCHAR(100))
AS
BEGIN
	SELECT * FROM Users WHERE Email = @Email AND Password = @Password AND Status = 1;
END;
go
CREATE PROC sp_viewUser(@ID INT = null, @Email VARCHAR(100) = null)
AS
BEGIN
	IF @ID IS NOT null AND @ID != 0
	BEGIN
		SELECT * FROM Users WHERE ID = @ID AND Status = 1;
	END
	IF @Email IS NOT null AND @Email != ''
	BEGIN
		SELECT * FROM Users WHERE Email = @Email AND Status = 1;
	END
END;
go
CREATE PROC sp_AddToCart(@ID INT, @Email VARCHAR(100) = null, @UnitPrice DECIMAL(18,2) = NULL, @Discount DECIMAL(18,2) = NULL
,@Quantity INT  = NULL,@TotalPrice DECIMAL(18,2)  = NULL)
AS
BEGIN
        DECLARE @UserId INT;
		DECLARE @UnitPrice_ DECIMAL(18,2);
		DECLARE @Discount_ DECIMAL(18,2);
		DECLARE @TotalPrice_ DECIMAL(18,2);
		SET @UserId = (SELECT ID FROM Users WHERE Email = @Email);
		SET @UnitPrice_ = (SELECT UnitPrice FROM Products WHERE ID = @ID);
		SET @Discount_ = (SELECT (UnitPrice * @Quantity * Discount)/ 100 FROM Products WHERE ID = @ID);
		SET @TotalPrice_ = (SELECT (UnitPrice * @Quantity) - @Discount_ FROM Products WHERE ID = @ID);
		
		IF NOT EXISTS(SELECT 1 FROM Cart WHERE UserId = @UserId AND ProductID = @ID)
		BEGIN
			INSERT INTO Cart(UserId,ProductID,UnitPrice,Discount,Quantity,TotalPrice)
			VALUES(@UserId,@ID,@UnitPrice_,@Discount_,@Quantity,@TotalPrice_);	
		END
		ELSE
		BEGIN
			UPDATE Cart SET Quantity = (Quantity + @Quantity) WHERE UserId = @UserId AND ProductID = @ID;
		END
END

EXEC sp_PlaceOrder 2
go
CREATE PROC sp_PlaceOrder(@Email VARCHAR(100))
AS
BEGIN
	DECLARE @OrderNO VARCHAR(100);
	DECLARE @OrderID INT;
	DECLARE @OrderTotal DECIMAL(18,2);
	DECLARE @UserID INT;
	SET @OrderNO =	(SELECT NEWID());
	SET @UserID = (SELECT ID FROM Users WHERE Email = @Email);

	IF OBJECT_ID('tempdb..#TempOrder') IS NOT NULL DROP TABLE #TempOrder; 
	
	SELECT * INTO #TempOrder 
	FROM Cart WHERE UserId = @UserID;

	SET @OrderTotal = (SELECT SUM(TotalPrice) from #TempOrder);

	INSERT INTO Orders(UserID,OrderNo,OrderTotal,OrderStatus,CreatedOn)
	VALUES(@UserID,@OrderNO,@OrderTotal,'Pending',GETDATE());

	SET @OrderID = (SELECT ID FROM Orders WHERE OrderNo = @OrderNO);

	INSERT INTO OrderItems(OrderID,ProductID,UnitPrice,Discount,Quantity,TotalPrice)
	SELECT @OrderID, ProductID,UnitPrice,Discount,Quantity,TotalPrice FROM #TempOrder;

	DELETE FROM Cart WHERE UserId = @UserID;
END

go

CREATE PROC sp_OrderList(@Type VARCHAR(100), @Email VARCHAR(100) = null, @ID INT)
AS
BEGIN
	IF @Type = 'Admin'
	BEGIN
		SELECT O.ID,OrderNo,OrderTotal,OrderStatus,CONVERT(NVARCHAR,O.CreatedOn,107) AS CreatedOn
		,CONCAT(U.FirstName,' ',U.LastName ) AS CustomerName
		FROM Orders O INNER JOIN Users U
		ON U.ID = O.UserID;
	END	
	IF @Type = 'User'
	BEGIN
		SELECT O.ID,OrderNo,OrderTotal,OrderStatus,CONVERT(NVARCHAR,O.CreatedOn,107) AS CreatedOn
		,CONCAT(U.FirstName,' ',U.LastName ) AS CustomerName
		FROM Orders O INNER JOIN Users U
		ON U.ID = O.UserID
		WHERE U.Email = @Email;
	END	
	IF @Type = 'UserItems'
	BEGIN
		SELECT 
		O.ID, O.OrderNo,O.OrderTotal,O.OrderStatus, M.Name AS ProductName,M.UnitPrice,OI.Quantity,OI.TotalPrice 
		,CONVERT(NVARCHAR,O.CreatedOn,107) AS CreatedOn ,CONCAT(U.FirstName,' ',U.LastName ) AS CustomerName
		, M.ImageUrl
		FROM Orders O 
		INNER JOIN Users U ON U.ID = O.UserID
		INNER JOIN OrderItems OI ON OI.OrderID = O.ID
		INNER JOIN Products M ON M.ID = OI.ProductID
		WHERE O.ID = @ID;
	END	
END

go
CREATE PROC sp_AddUpdateProduct(@ID INT = null, @Name VARCHAR(100) = null, @UnitPrice DECIMAL(18,2) = null
,@Discount DECIMAL(18,2)  = null,@Quantity INT  = null,@ImageUrl VARCHAR(100) = null,@Status INT = null
, @Type VARCHAR(100) = null)
AS
BEGIN
	IF @Type = 'Add'
	BEGIN
		INSERT INTO Products(Name,UnitPrice,Discount,Quantity,ImageUrl,Status)
		VALUES(@Name,@UnitPrice,@Discount,@Quantity,@ImageUrl,@Status)
	END
	IF @Type = 'Update'
	BEGIN
		UPDATE Products SET Name=@Name,UnitPrice=@UnitPrice,Discount=@Discount,Quantity=@Quantity		
		WHERE ID = @ID;
	END
	IF @Type = 'Delete'
	BEGIN
		UPDATE Products SET Status = 0 WHERE ID = @ID;
	END
	IF @Type = 'Get'
	BEGIN
		SELECT * FROM Products WHERE Status = 1;
	END
	IF @Type = 'GetByID'
	BEGIN
		SELECT * FROM Products WHERE ID = @ID;
	END
END
go
CREATE PROC sp_UserList
AS
BEGIN
	SELECT ID, FirstName, LastName, Email, CASE WHEN Fund IS NULL THEN 0.00 ELSE FUND END AS FUND
	, CONVERT(NVARCHAR,CreatedON,107) AS OrderDate, Status, Password  FROM Users WHERE Status = 1 AND Type != 'Admin';
END;

go
CREATE PROC sp_updateOrderStatus(@OrderNo VARCHAR(100) = NULL, @OrderStatus VARCHAR(100) = NULL)
AS
BEGIN
	UPDATE Orders SET OrderStatus = @OrderStatus WHERE OrderNo = @OrderNo;
END
go
CREATE PROC sp_CartList(@Email VARCHAR(100))
AS
BEGIN
    IF @Email != 'Admin'
	BEGIN
		SELECT C.ID, M.Name,  M.UnitPrice, M.Discount, C.Quantity, C.TotalPrice, M.ImageUrl FROM Cart C 
		INNER JOIN Products M ON M.ID = C.ProductID
		INNER JOIN Users U ON U.ID = C.UserId
		WHERE U.Email =  @Email;
	END
	ELSE
	BEGIN
		SELECT M.ID, M.Name, M.UnitPrice, M.Discount, M.Quantity, M.ImageUrl , 0 AS TotalPrice FROM Products M;
	END
END;
