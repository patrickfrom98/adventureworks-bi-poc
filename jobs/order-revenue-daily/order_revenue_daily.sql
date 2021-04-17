USE [BusinessMetrics]
GO

DECLARE @Date DATE = (
	SELECT TOP 1 [ReplacementDate]
	FROM [EtlTools].[dbo].[RunDate]
	WHERE [Date] = CONVERT(DATE, SYSDATETIME())
)

EXECUTE [Sales].[uspOrderRevenueDaily] @Date
GO