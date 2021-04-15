USE [master]
GO

IF DB_ID('BusinessMetricsStg') IS NOT NULL
	DROP DATABASE [BusinessMetricsStg]
GO

CREATE DATABASE [BusinessMetricsStg]
GO

IF DB_ID('BusinessMetrics') IS NOT NULL
	DROP DATABASE [BusinessMetrics]
GO

CREATE DATABASE [BusinessMetrics]
GO