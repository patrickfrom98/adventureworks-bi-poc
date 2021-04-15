USE [BusinessMetrics]
GO

CREATE SCHEMA [Dim]
GO

IF OBJECT_ID('Dim.Date', 'U') IS NOT NULL 
	DROP TABLE [Dim].[Date]; 
GO

CREATE TABLE [Dim].[Date] (
	[DateID]                 INT NOT NULL,
	[Date]                   DATE NOT NULL,
	[Day]                    TINYINT NOT NULL,
	[DaySuffix]              CHAR(2) NOT NULL,
	[Weekday]                TINYINT NOT NULL,
	[WeekDayName]            VARCHAR(10) NOT NULL,
	[WeekDayNameShort]       CHAR(3) NOT NULL,
	[WeekDayNameFirstLetter] CHAR(1) NOT NULL,
	[DOWInMonth]             TINYINT NOT NULL,
	[DayOfYear]              SMALLINT NOT NULL,
	[WeekOfMonth]            TINYINT NOT NULL,
	[WeekOfYear]             TINYINT NOT NULL,
	[Month]                  TINYINT NOT NULL,
	[MonthName]              VARCHAR(10) NOT NULL,
	[MonthNameShort]         CHAR(3) NOT NULL,
	[MonthNameFirstLetter]   CHAR(1) NOT NULL,
	[Quarter]                TINYINT NOT NULL,
	[QuarterName]            VARCHAR(6) NOT NULL,
	[Year]                   INT NOT NULL,
	[YearMonth]              CHAR(6) NOT NULL,
	[MMYYYY]                 CHAR(6) NOT NULL,
	[MonthYear]              CHAR(7) NOT NULL,
	[IsWeekend]              BIT NOT NULL,
	[IsHoliday]              BIT NOT NULL,
	[HolidayName]            VARCHAR(20) NULL,
	[SpecialDays]            VARCHAR(20) NULL,
	[FinancialYear]          INT NULL,
	[FinancialQuater]        INT NULL,
	[FinancialMonth]         INT NULL,
	[FirstDateofYear]        DATE NULL,
	[LastDateofYear]         DATE NULL,
	[FirstDateofQuater]      DATE NULL,
	[LastDateofQuater]       DATE NULL,
	[FirstDateofMonth]       DATE NULL,
	[LastDateofMonth]        DATE NULL,
	[FirstDateofWeek]        DATE NULL,
	[LastDateofWeek]         DATE NULL,
	[CurrentYear]            SMALLINT NULL,
	[CurrentQuater]          SMALLINT NULL,
	[CurrentMonth]           SMALLINT NULL,
	[CurrentWeek]            SMALLINT NULL,
	[CurrentDay]             SMALLINT NULL,
	PRIMARY KEY CLUSTERED (
		[DateID] ASC
	) WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

TRUNCATE TABLE [dim].[Date]
GO

DECLARE @CurrentDate DATE = '1990-01-01'
DECLARE @EndDate DATE = '2030-12-31'

WHILE @CurrentDate < @EndDate
BEGIN
	INSERT INTO [dim].[Date] (
		[DateID],
		[Date],
		[Day],
		[DaySuffix],
		[Weekday],
		[WeekDayName],
		[WeekDayNameShort],
		[WeekDayNameFirstLetter],
		[DOWInMonth],
		[DayOfYear],
		[WeekOfMonth],
		[WeekOfYear],
		[Month],
		[MonthName],
		[MonthNameShort],
		[MonthNameFirstLetter],
		[Quarter],
		[QuarterName],
		[Year],
		[YearMonth],
		[MMYYYY],
		[MonthYear],
		[IsWeekend],
		[IsHoliday],
		[FirstDateofYear],
		[LastDateofYear],
		[FirstDateofQuater],
		[LastDateofQuater],
		[FirstDateofMonth],
		[LastDateofMonth],
		[FirstDateofWeek],
		[LastDateofWeek]
	)
	SELECT [DateId] = YEAR(@CurrentDate) * 10000 + MONTH(@CurrentDate) * 100 + DAY(@CurrentDate),
		   [Date] = @CurrentDate,
           [Day] = DAY(@CurrentDate),
           [DaySuffix] = CASE WHEN DAY(@CurrentDate) = 1 OR DAY(@CurrentDate) = 21 OR DAY(@CurrentDate) = 31 THEN 'st'
		                      WHEN DAY(@CurrentDate) = 2 OR DAY(@CurrentDate) = 22 THEN 'nd'
							  WHEN DAY(@CurrentDate) = 3 OR DAY(@CurrentDate) = 23 THEN 'rd'
							  ELSE 'th'
                         END,
           [Weekday] = DATEPART(dw, @CurrentDate),
		   [WeekDayName] = DATENAME(dw, @CurrentDate),
		   [WeekDayNameShort] = UPPER(LEFT(DATENAME(dw, @CurrentDate), 3)),
		   [WeekDayNameFirstLetter] = LEFT(DATENAME(dw, @CurrentDate), 1),
		   [DOWInMonth] = DAY(@CurrentDate),
		   [DayOfYear] = DATENAME(dy, @CurrentDate),
		   [WeekOfMonth] = DATEPART(WEEK, @CurrentDate) - DATEPART(WEEK, DATEADD(MM, DATEDIFF(MM, 0, @CurrentDate), 0)) + 1,
		   [WeekOfYear] = DATEPART(wk, @CurrentDate),
		   [Month] = MONTH(@CurrentDate),
		   [MonthName] = DATENAME(mm, @CurrentDate),
		   [MonthName_Short] = UPPER(LEFT(DATENAME(mm, @CurrentDate), 3)),
		   [MonthName_FirstLetter] = LEFT(DATENAME(mm, @CurrentDate), 1),
		   [Quarter] = DATEPART(q, @CurrentDate),
           [QuarterName] = CASE WHEN DATENAME(qq, @CurrentDate) = 1 THEN 'First'
                                WHEN DATENAME(qq, @CurrentDate) = 2 THEN 'second'
                                WHEN DATENAME(qq, @CurrentDate) = 3 THEN 'third'
                                WHEN DATENAME(qq, @CurrentDate) = 4 THEN 'fourth'
                           END,
           [Year] = YEAR(@CurrentDate),
           [YearMonth] = CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + RIGHT('0' + CAST(MONTH(@CurrentDate) AS VARCHAR(2)), 2),
           [MMYYYY] = RIGHT('0' + CAST(MONTH(@CurrentDate) AS VARCHAR(2)), 2) + CAST(YEAR(@CurrentDate) AS VARCHAR(4)),
           [MonthYear] = CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + UPPER(LEFT(DATENAME(mm, @CurrentDate), 3)),
           [IsWeekend] = CASE WHEN DATENAME(dw, @CurrentDate) = 'Sunday' OR DATENAME(dw, @CurrentDate) = 'Saturday' THEN 1
                              ELSE 0
                         END,
           [IsHoliday] = 0,
           [FirstDateofYear] = CAST(CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + '-01-01' AS DATE),
           [LastDateofYear] = CAST(CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + '-12-31' AS DATE),
           [FirstDateofQuater] = DATEADD(qq, DATEDIFF(qq, 0, GETDATE()), 0),
           [LastDateofQuater] = DATEADD(dd, - 1, DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) + 1, 0)),
           [FirstDateofMonth] = CAST(CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + '-' + CAST(MONTH(@CurrentDate) AS VARCHAR(2)) + '-01' AS DATE),
           [LastDateofMonth] = EOMONTH(@CurrentDate),
           [FirstDateofWeek] = DATEADD(dd, - (DATEPART(dw, @CurrentDate) - 1), @CurrentDate),
           [LastDateofWeek] = DATEADD(dd, 7 - (DATEPART(dw, @CurrentDate)), @CurrentDate)

	SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END
GO

--Update Holiday information
UPDATE [dim].[Date]
SET [IsHoliday] = 1,
    [HolidayName] = 'Christmas'
WHERE [Month] = 12 AND
      [DAY] = 25
GO

UPDATE [dim].[Date]
SET SpecialDays = 'Valentines Day'
WHERE [Month] = 2 AND
      [DAY] = 14
GO

--Update current date information
UPDATE [dim].[Date]
SET CurrentYear = DATEDIFF(yy, GETDATE(), DATE),
    CurrentQuater = DATEDIFF(q, GETDATE(), DATE),
    CurrentMonth = DATEDIFF(m, GETDATE(), DATE),
    CurrentWeek = DATEDIFF(ww, GETDATE(), DATE),
    CurrentDay = DATEDIFF(dd, GETDATE(), DATE)
GO
