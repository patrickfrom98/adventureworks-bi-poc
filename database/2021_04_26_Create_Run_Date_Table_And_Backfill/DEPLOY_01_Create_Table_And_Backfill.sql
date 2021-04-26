USE [EtlTools]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.RunDate', 'U') IS NOT NULL
	DROP TABLE [dbo].[RunDate]
GO

CREATE TABLE [dbo].[RunDate] (
	[Id]              BIGINT IDENTITY(1,1) NOT NULL,
	[Date]            DATE                 NOT NULL,
	[ReplacementDate] DATE                 NOT NULL,
    CONSTRAINT [PK_dbo_RunDate_Id] PRIMARY KEY CLUSTERED (
	    [Id] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

DECLARE @DateParam DATE = '2020-01-01'

WHILE @DateParam < '2022-01-01'
BEGIN
	INSERT INTO [dbo].[RunDate] (
		[Date],
		[ReplacementDate]
	)
	SELECT @DateParam,
	       DATEADD(YEAR, -8, @DateParam)

	SELECT @DateParam
	SET @DateParam = DATEADD(DAY, 1, @DateParam)
END
GO
