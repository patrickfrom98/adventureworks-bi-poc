USE [BusinessMetricsStg]
GO

IF OBJECT_ID('Extract.TopProductsMonthly', 'U') IS NOT NULL
	DROP TABLE [Extract].[TopProductsMonthly]
GO

CREATE TABLE [Extract].[TopProductsMonthly] (
	[Id]            BIGINT IDENTITY(1,1) NOT NULL,
	[ProductId]     INT                  NOT NULL,
	[ProductName]   NVARCHAR(50)         NOT NULL,
	[OrderQty]      INT                  NOT NULL,
	[LineTotal]     NUMERIC(38, 6)       NOT NULL,
	[InsertDate]    DATETIME2            NOT NULL
	CONSTRAINT [PK_Extract_TopProductsMonthly_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

IF OBJECT_ID('Transform.TopProductsMonthly', 'U') IS NOT NULL
	DROP TABLE [Transform].[TopProductsMonthly]
GO

CREATE TABLE [Transform].[TopProductsMonthly] (
	[Id]            BIGINT IDENTITY(1,1) NOT NULL,
	[Month]         INT                  NOT NULL,
	[Year]          INT                  NOT NULL,
	[ProductId]     INT                  NOT NULL,
	[ProductName]   NVARCHAR(50)         NOT NULL,
	[AmountOrdered] INT                  NOT NULL,
	[TotalRevenue]  NUMERIC(38, 6)       NOT NULL,
	[InsertDate]    DATETIME2            NOT NULL
	CONSTRAINT [PK_Transform_TopProductsMonthly_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [BusinessMetrics]
GO

IF OBJECT_ID('Sales.TopProductsMonthly', 'U') IS NOT NULL
	DROP TABLE [Sales].[TopProductsMonthly]
GO

CREATE TABLE [Sales].[TopProductsMonthly] (
	[Id]            BIGINT IDENTITY(1,1) NOT NULL,
	[Month]         INT NOT NULL,
	[Year]          INT NOT NULL,
	[ProductId]     INT NOT NULL,
	[ProductName]   NVARCHAR(50) NOT NULL,
	[AmountOrdered] INT NOT NULL,
	[TotalRevenue]  NUMERIC(38, 6) NOT NULL,
	[InsertDate]    DATETIME2 NOT NULL
	CONSTRAINT [PK_Sales_TopProductsMonthly_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

IF OBJECT_ID('Sales.uspTopProductsMonthly', 'P') IS NOT NULL
	DROP PROCEDURE [Sales].[uspTopProductsMonthly]
GO

CREATE PROCEDURE [Sales].[uspTopProductsMonthly]
(
	@DateParam DATE
)
AS
BEGIN
	DECLARE @RollbackFlag BIT = 1

	BEGIN TRY
		SET NOCOUNT ON

	  --#===============================================================================
	  --# STEP 0 - Setup
	  --#===============================================================================
		-- Paramaters
		DECLARE @Date            DATE        = ISNULL(LTRIM(RTRIM(@DateParam)), CONVERT(DATE, SYSDATETIME()))

		-- General Variables
		DECLARE @Year            CHAR(4)     = YEAR(@Date)
		DECLARE @Month           NVARCHAR(2) = MONTH(DATEADD(MONTH, -1, @Date)) --Always process the previous months data

		-- Error Trapping Variables
		DECLARE @ERROR_MESSAGE   NVARCHAR(4000)
		DECLARE @ERROR_NUMBER	 INT     
		DECLARE @ERROR_SEVERITY	 INT 
		DECLARE @ERROR_STATE	 INT 
		DECLARE @ERROR_PROCEDURE NVARCHAR(126) 
		DECLARE @ERROR_LINE		 INT

		-- Logging Variables
		DECLARE @RunId           UNIQUEIDENTIFIER = NEWID()
		DECLARE @ServerName      NVARCHAR(50)     = SUBSTRING(@@SERVERNAME, 1, 50)
		DECLARE @ProcessName     NVARCHAR(50)     = ISNULL(OBJECT_NAME(@@PROCID), 'uspTopProductsMonthly')
		DECLARE @ExecutingUser   NVARCHAR(50)     = SYSTEM_USER
		DECLARE @LogType         CHAR(1)
		DECLARE @Message         NVARCHAR(4000)


	  --#===============================================================================
	  --# STEP 1 - Extract
	  --#===============================================================================
	    SET @Message = 'Starting extract step.'
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message

		INSERT INTO [BusinessMetricsStg].[Extract].[TopProductsMonthly] (
			[ProductId],
			[ProductName],
			[OrderQty],
			[LineTotal],
			[InsertDate]
		)
		SELECT pd.[ProductId],
			   pd.[Name],
			   sd.[OrderQty],
			   sd.[LineTotal],
			   SYSDATETIME()
		FROM [AdventureWorks2019].[Sales].[SalesOrderHeader] sh
		INNER JOIN [AdventureWorks2019].[Sales].[SalesOrderDetail] sd ON sh.[SalesOrderID] = sd.[SalesOrderID]
		INNER JOIN [AdventureWorks2019].[Production].[Product] pd ON sd.[ProductID] = pd.[ProductID]
		WHERE CONVERT(VARCHAR, [OrderDate], 112) IN (
			SELECT [DateId] 
			FROM [dim].[Date]
			WHERE [Year] = @Year AND
					[Month] = @Month
		)

		SET @Message = CONCAT('Finished extract step. ', @@ROWCOUNT, ' rows moved into extract table.')
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message


	  --#===============================================================================
	  --# STEP 2 - Transform
	  --#===============================================================================
	    SET @Message = 'Starting transform step.'
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message

		INSERT INTO [BusinessMetricsStg].[Transform].[TopProductsMonthly] (
			[Month],
			[Year],
			[ProductId],
			[ProductName],
			[AmountOrdered],
			[TotalRevenue],
			[InsertDate]
		)
		SELECT @Month,
			   @Year,
			   [ProductId],
			   [ProductName],
			   SUM([OrderQty]) AS 'AmountOrdered',
			   SUM([LineTotal]) AS 'TotalRevenue',
			   SYSDATETIME()
		FROM [BusinessMetricsStg].[Extract].[TopProductsMonthly]
		GROUP BY [ProductId], [ProductName]

		SET @Message = CONCAT('Finished transform step. ', @@ROWCOUNT, ' rows moved into transform table.')
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message


	  --#===============================================================================
	  --# STEP 3 - Load
	  --#===============================================================================
	    SET @Message = 'Starting Load Step.'
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message

		BEGIN TRANSACTION
			INSERT INTO [Sales].[TopProductsMonthly] (
				[Month],
				[Year],
				[ProductId],
				[ProductName],
				[AmountOrdered],
				[TotalRevenue],
				[InsertDate]
			)
			SELECT [Month],
				   [Year],
				   [ProductId],
				   [ProductName],
				   [AmountOrdered],
				   [TotalRevenue],
				   SYSDATETIME()
			FROM [BusinessMetricsStg].[Transform].[TopProductsMonthly]

			DECLARE @Rows INT = @@ROWCOUNT -- Otherwise @@ROWCOUNT returns 0 for logging table below

			SET @RollBackFlag = 0
		COMMIT TRANSACTION

		SET @Message = CONCAT('Finished load step. ', @Rows, ' rows moved into load table.')
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'S', @MessageParam = @Message
	END TRY
	BEGIN CATCH
		SELECT @ERROR_MESSAGE = ERROR_MESSAGE(), 
			   @ERROR_NUMBER = ERROR_NUMBER(),
			   @ERROR_SEVERITY = ERROR_SEVERITY(),
			   @ERROR_STATE = ERROR_STATE(),
			   @ERROR_PROCEDURE = ERROR_PROCEDURE(),
			   @ERROR_LINE = ERROR_LINE()

		IF @RollbackFlag = 1
			ROLLBACK TRANSACTION

		SET @Message = CONCAT('Error Number: ', @ERROR_NUMBER, '. Error Severity: ', @ERROR_SEVERITY, '. Error State: ', @ERROR_STATE, '. Error Procedure: ', @ERROR_PROCEDURE, '. Error Line: ', @ERROR_LINE, '. Error Message: ', @ERROR_MESSAGE, '.')
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'E', @MessageParam = @Message

		RAISERROR (
			@ERROR_MESSAGE, 
			@ERROR_SEVERITY,
			@ERROR_STATE
		)
		RETURN
	END CATCH
END
GO