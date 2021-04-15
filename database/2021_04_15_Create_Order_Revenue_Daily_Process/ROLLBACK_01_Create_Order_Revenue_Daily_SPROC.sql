USE [BusinessMetricsStg]
GO
DROP TABLE [Transform].[OrderRevenueDaily]
GO
DROP TABLE [Extract].[OrderRevenueDaily]
GO
DROP SCHEMA [Transform]
GO
DROP SCHEMA [Extract]
GO

USE [BusinessMetrics]
GO
DROP PROCEDURE [Sales].[uspOrderRevenueDaily]
GO
DROP TABLE [Sales].[OrderRevenueDaily]
GO
DROP SCHEMA [Sales]
GO