USE [EtlTools]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.EtlLogs', 'U') IS NOT NULL 
	DROP TABLE [dbo].[EtlLogs] 
GO

CREATE TABLE [dbo].[EtlLogs] (
	[Id]            BIGINT IDENTITY(1,1) NOT NULL,
	[RunId]         UNIQUEIDENTIFIER NOT NULL,
	[ServerName]    NVARCHAR(50) NOT NULL,
	[ProcessName]   NVARCHAR(50) NOT NULL,
	[ExecutingUser] NVARCHAR(50) NOT NULL,
	[LogType]       CHAR(1) NOT NULL,
	[Message]       NVARCHAR(4000) NOT NULL,
	[InsertDate]    DATETIME2 NOT NULL
	CONSTRAINT [PK_Dbo_EtlLogs_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

IF OBJECT_ID('dbo.uspLogEtlEvent', 'P') IS NOT NULL 
	DROP PROCEDURE [dbo].[uspLogEtlEvent]
GO

CREATE PROCEDURE [dbo].[uspLogEtlEvent] 
(
	@RunIdParam UNIQUEIDENTIFIER,
	@ServerNameParam NVARCHAR(50),
	@ProcessNameParam NVARCHAR(50),
	@ExecutingUserParam NVARCHAR(50),
	@LogTypeParam CHAR(1),
	@MessageParam NVARCHAR(4000)
)
AS
BEGIN
	DECLARE @RollbackFlag AS BIT = 1

	BEGIN TRY
		SET NOCOUNT ON

		-- Error Trapping Variables
		DECLARE @ERROR_MESSAGE	 INT     
		DECLARE @ERROR_SEVERITY	 INT 
		DECLARE @ERROR_STATE	 INT 

		-- Setup Variables
		DECLARE @RunId         UNIQUEIDENTIFIER = @RunIDParam
		DECLARE @ServerName    NVARCHAR(50)     = @ServerNameParam
		DECLARE @ProcessName   NVARCHAR(50)     = @ProcessNameParam
		DECLARE @ExecutingUser NVARCHAR(50)     = @ExecutingUserParam
		DECLARE @LogType       CHAR(1)          = @LogTypeParam
		DECLARE @Message       NVARCHAR(4000)   = @MessageParam

		BEGIN TRANSACTION
			INSERT INTO [dbo].[EtlLogs] (
				[RunId],
				[ServerName],
				[ProcessName],
				[ExecutingUser],
				[LogType],
				[Message],
				[InsertDate]
			)
			SELECT @RunId,
				   @ServerName,
				   @ProcessName,
				   @ExecutingUser,
				   @LogType,
				   CASE 
						WHEN @LogType = 'S' THEN 'Success! ' + @Message
						WHEN @LogType = 'I' THEN 'Information! ' + @Message
						WHEN @LogType = 'W' THEN 'Warning! ' + @Message
						WHEN @LogType = 'E' THEN 'Error! ' + @Message
						ELSE 'Event Type Not Known! Message: ' + @Message
				   END,
				   SYSDATETIME()

			SET @RollbackFlag = 0
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT @ERROR_MESSAGE = ERROR_MESSAGE(),
		       @ERROR_SEVERITY = ERROR_SEVERITY(),
		       @ERROR_STATE = ERROR_STATE()

		IF @RollbackFlag = 1
			ROLLBACK TRANSACTION

		RAISERROR (
			@ERROR_MESSAGE,
			@ERROR_SEVERITY,
			@ERROR_STATE
		)
		RETURN
	END CATCH
END
GO