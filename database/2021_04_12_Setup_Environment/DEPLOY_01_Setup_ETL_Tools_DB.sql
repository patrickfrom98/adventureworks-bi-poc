USE [master]
GO

IF DB_ID('EtlTools') IS NOT NULL
	DROP DATABASE [EtlTools]
GO

CREATE DATABASE [EtlTools]
GO