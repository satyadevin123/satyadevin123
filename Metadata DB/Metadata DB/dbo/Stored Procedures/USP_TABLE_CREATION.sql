CREATE PROC [dbo].[USP_TABLE_CREATION]
AS
BEGIN

--------------------------SCHEMA CREATION---------------------------------------------------
IF OBJECT_ID('tempdb..#temp_schemacheck') IS NOT NULL DROP TABLE #temp_schemacheck
CREATE TABLE #temp_schemacheck(SCH_ID INT IDENTITY(1,1),
[SCHEMA_NAME] VARCHAR(200),
SCHEMA_QUERY VARCHAR(2000)
)

INSERT INTO #temp_schemacheck
SELECT DISTINCT [DatabaseName], 'CREATE SCHEMA '+[DatabaseName] AS SCHEMA_QUERY
FROM [dbo].[IMS_EMR_2019Q4]
WHERE DatabaseName NOT IN (
SELECT  schema_name
FROM    information_schema.schemata)


--SELECT * FROM #temp_schemacheck

DECLARE @loop INT = (SELECT COUNT(*) FROM #temp_schemacheck)
       ,@i INT = 1


WHILE   @i <= @loop
BEGIN
    DECLARE @sql_code1 VARCHAR(8000) = (SELECT SCHEMA_QUERY FROM #temp_schemacheck WHERE SCH_ID=@i);
    EXEC (@sql_code1);

    SET     @i +=1;
END


--------------------------------JOINING THE TERADATA DATA TYPES AND SQL TABLE FORMATS----------------------------------------

IF OBJECT_ID('tempdb..#temp_tablejoin') IS NOT NULL DROP TABLE #temp_tablejoin  
CREATE TABLE #temp_tablejoin([DatabaseName] VARCHAR(1000)
      ,[TableName] VARCHAR(1000)
      ,[Columnname] VARCHAR(1000)
      ,[ColumnLength] INT
      ,[Nullable] VARCHAR(20)
      ,[ColumnID] INT
	  ,[SQL Server Data Type] VARCHAR(50))  
  
INSERT INTO #temp_tablejoin   
SELECT * FROM(
SELECT [DatabaseName]
      ,[TableName]
      ,[Columnname]
      ,B.[ColumnLength]
      ,CASE WHEN [Nullable] = 'Y' THEN 'NULL' ELSE 'NOT NULL' END AS [Nullable]
      ,[ColumnID]
	  ,CASE WHEN [SQL Server Data Type] = 'Varchar' OR [SQL Server Data Type] = 'Char' THEN [SQL Server Data Type]+'('+CAST(B.[ColumnLength] AS nvarchar(255))+')'
	  ELSE [SQL Server Data Type]
	  END AS 
	  [SQL Server Data Type]
  FROM [dbo].[Teradata_SQL_DataTypes] A
  RIGHT JOIN 
  (SELECT *
	FROM [dbo].[IMS_EMR_2019Q4]
	WHERE [DatabaseName]+'.'+[TableName] NOT IN (
	SELECT  TABLE_SCHEMA+'.'+TABLE_NAME
	FROM    information_schema.TABLES)
  )
  B
  ON A.[Teradata ColumnType] = B.[ColumnType]
  WHERE [ColumnType] <> 'D'

  UNION
  SELECT [DatabaseName]
      ,[TableName]
      ,[Columnname]
      ,B.[ColumnLength]
      ,CASE WHEN [Nullable] = 'Y' THEN 'NULL' ELSE 'NOT NULL' END AS [Nullable]
      ,[ColumnID]
	  ,CASE WHEN B.[ColumnFormat] IS NULL THEN 'Decimal(18,2)' ELSE [SQL Server Data Type] END AS [SQL Server Data Type]
  FROM [dbo].[Teradata_SQL_DataTypes] A
  RIGHT JOIN 
  (SELECT *
	FROM [dbo].[IMS_EMR_2019Q4]
	WHERE [DatabaseName]+'.'+[TableName] NOT IN (
	SELECT  TABLE_SCHEMA+'.'+TABLE_NAME
	FROM    information_schema.TABLES)
  )B

  ON A.[Teradata ColumnType] = B.[ColumnType]
  AND A.[ColumnFormat]=B.[ColumnFormat]
  WHERE [ColumnType] = 'D'
  ) A
  ORDER BY [DatabaseName],[TableName],[ColumnID]

--SELECT * FROM #temp_tablejoin 
----------------------------------------CREATE/ALTER TABLE QUERY FORMATION-----------------------------------------------

IF OBJECT_ID('tempdb..#temp_tabledef') IS NOT NULL DROP TABLE #temp_tabledef
CREATE TABLE #temp_tabledef( ID INT IDENTITY (1,1)
	  ,[DatabaseName] VARCHAR(1000)
      ,[TableName] VARCHAR(1000)
	  ,[ColumnID] INT
      ,[Columnname] VARCHAR(1000)
      ,[SQL Server Data Type] VARCHAR(50)
	  ,[Nullable] VARCHAR(20)
      ,CREATE_QUERY VARCHAR(8000)
	  )  
  
INSERT INTO #temp_tabledef  

SELECT T1.[DatabaseName],T1.[TableName],T1.[ColumnID], T2.[Columnname],
T2.[SQL Server Data Type],T2.[Nullable],
'CREATE TABLE ['+ T1.DatabaseName + '].['+ T1.TableName +'] ('+T2.[Columnname]+' '+T2.[SQL Server Data Type] + ' ' +T2.[Nullable] +')' AS CREATE_QUERY
FROM

(SELECT [DatabaseName],[TableName],MIN([ColumnID]) [ColumnID] FROM #temp_tablejoin GROUP BY [DatabaseName],[TableName]) T1
LEFT JOIN
#temp_tablejoin T2
ON T1.DatabaseName=T2.DatabaseName AND
T1.TableName=T2.TableName AND
T1.ColumnID = T2.ColumnID

UNION

SELECT T3.[DatabaseName],T3.[TableName], T3.[ColumnID], [Columnname],[SQL Server Data Type],[Nullable],
'ALTER TABLE ['+T3.[DatabaseName]+'].['+T3.[TableName]+'] ADD '+[Columnname]+' '+[SQL Server Data Type]+' '+Nullable AS CREATE_QUERY
FROM #temp_tablejoin T3
INNER JOIN
(
SELECT [DatabaseName],[TableName], ColumnID FROM #temp_tablejoin
EXCEPT
SELECT [DatabaseName],[TableName],MIN(ColumnID) ColumnID FROM #temp_tablejoin GROUP BY [DatabaseName],[TableName]
) T4
ON T3.ColumnID = T4.ColumnID
AND T3.DatabaseName=T4.DatabaseName AND T3.TableName=T4.TableName

--SELECT * FROM #temp_tabledef


--------------------------RUN THE CREATE/ALTER STATEMENTS------------------------------------------------
DECLARE @nbr_statements INT = (SELECT COUNT(*) FROM #temp_tabledef)
       ,@incr INT = 1


WHILE   @incr <= @nbr_statements
BEGIN
    DECLARE @sql_code2 VARCHAR(8000) = (SELECT CREATE_QUERY FROM #temp_tabledef WHERE ID=@incr);
    EXEC (@sql_code2);

    SET     @incr +=1;
END



END