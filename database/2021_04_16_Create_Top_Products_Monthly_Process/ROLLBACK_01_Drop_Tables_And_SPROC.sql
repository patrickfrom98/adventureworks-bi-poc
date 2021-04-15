USE [BusinessMetricsStg]
GO
DROP TABLE [Extract].[TopProductsMonthly]
GO
DROP TABLE [Transform].[TopProductsMonthly]
GO

USE [BusinessMetrics]
GO
DROP TABLE [Sales].[TopProductsMonthly]
GO
DROP PROCEDURE [Sales].[uspTopProductsMonthly]
GO
