USE [BusinessMetricsStg]
GO

CREATE SCHEMA [Extract]
GO

CREATE SCHEMA [Transform]
GO

CREATE TABLE [Extract].[OrderRevenueDaily] (
	[Id] BIGINT NOT NULL,
	[OrderDate] [DATETIME2] NOT NULL,
	[SubTotal] [MONEY] NOT NULL,
	[TaxAmt] [MONEY] NOT NULL,
	[Freight] [MONEY] NOT NULL,
	[TotalDue] AS (ISNULL(([SubTotal] + [TaxAmt]) + [Freight], (0))),
	[InsertDate] [DATETIME2] NOT NULL,
	CONSTRAINT [PK_Extract_OrderRevenueDaily_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [Transform].[OrderRevenueDaily] (
	[Id] BIGINT IDENTITY(1,1) NOT NULL,
	[DateId] BIGINT NOT NULL,
	[TotalRevenue] MONEY NOT NULL,
	[InsertDate] [DATETIME2] NOT NULL
	CONSTRAINT [PK_Transform_OrderRevenueDaily_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [BusinessMetrics]
GO

CREATE SCHEMA [Sales]
GO

CREATE TABLE [Sales].[OrderRevenueDaily] (
	[Id] BIGINT IDENTITY(1,1) NOT NULL,
	[DateId] BIGINT NOT NULL,
	[TotalRevenue] MONEY NOT NULL,
	[InsertDate] DATETIME2 NOT NULL
	CONSTRAINT [PK_Sales_OrderRevenueDaily_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('Sales.uspOrderRevenueDaily', 'P') IS NOT NULL 
	DROP PROCEDURE [Sales].[uspOrderRevenueDaily]
GO

CREATE PROCEDURE [Sales].[uspOrderRevenueDaily]
(
	@Date DATE
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
		DECLARE @StartOfPeriod   DATETIME2        = @Date
		DECLARE @EndOfPeriod     DATETIME2        = DATEADD(DAY, 1, @StartOfPeriod)

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
		DECLARE @ProcessName     NVARCHAR(50)     = ISNULL(OBJECT_NAME(@@PROCID), 'uspOrderRevenueDaily')
		DECLARE @ExecutingUser   NVARCHAR(50)     = SYSTEM_USER
		DECLARE @LogType         CHAR(1)
		DECLARE @Message         NVARCHAR(4000)


	  --#===============================================================================
	  --# STEP 1 - Extract
	  --#===============================================================================
	    SET @Message = 'Starting extract step.'
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message
		
		TRUNCATE TABLE [BusinessMetricsStg].[Extract].[OrderRevenueDaily]

		INSERT INTO [BusinessMetricsStg].[Extract].[OrderRevenueDaily] (
		   [Id],
		   [OrderDate],
		   [SubTotal],
		   [TaxAmt],
		   [Freight],
		   [InsertDate]
		)
		SELECT [SalesOrderID],
			   [OrderDate],
			   [SubTotal],
			   [TaxAmt],
			   [Freight],
			   SYSDATETIME()
		FROM [AdventureWorks2019].[Sales].[SalesOrderHeader]
		WHERE [OrderDate] >= @StartOfPeriod AND
			  [OrderDate] < @EndOfPeriod

	    SET @Message = CONCAT('Finished extract step. ', @@ROWCOUNT, ' rows moved into extract table.')
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message


	  --#===============================================================================
	  --# STEP 2 - Transform
	  --#===============================================================================
	    SET @Message = 'Starting transform step.'
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message
		
		TRUNCATE TABLE [BusinessMetricsStg].[Transform].[OrderRevenueDaily]

		INSERT INTO [BusinessMetricsStg].[Transform].[OrderRevenueDaily] (
			[DateId],
			[TotalRevenue],
			[InsertDate]
		)
		SELECT [DateId] = (SELECT TOP 1 [DateId] FROM [dim].[Date] WHERE [Date] = @Date),
			   SUM([TotalDue]),
			   SYSDATETIME()
		FROM [BusinessMetricsStg].[Extract].[OrderRevenueDaily]

	    SET @Message = CONCAT('Finished transform step. ', @@ROWCOUNT, ' rows moved into transform table.')
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message


	  --#===============================================================================
	  --# STEP 3 - Load
	  --#===============================================================================
	    SET @Message = 'Starting Load Step.'
		EXECUTE [EtlTools].[dbo].[uspLogEtlEvent] @RunId, @ServerName, @ProcessName, @ExecutingUser, @LogTypeParam = 'I', @MessageParam = @Message

		BEGIN TRANSACTION
			INSERT INTO [Sales].[OrderRevenueDaily] (
				[DateId],
				[TotalRevenue],
				[InsertDate]
			)
			SELECT [DateId],
				   [TotalRevenue],
				   SYSDATETIME()
			FROM [BusinessMetricsStg].[Transform].[OrderRevenueDaily]

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
