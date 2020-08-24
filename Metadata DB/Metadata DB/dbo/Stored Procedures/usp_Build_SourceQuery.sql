CREATE PROC [dbo].[usp_Build_SourceQuery]  AS
BEGIN

DECLARE @SQL VARCHAR(MAX),
		@Query VARCHAR(8000),
		@LastRefreshedBasedOn VARCHAR(200),
		@LastRefreshedDateTime VARCHAR(200),
		@Count INT,
		@RowNumber INT,
		@ID INT

SELECT ID,Query,LastRefreshedBasedOn,LastRefreshedDateTime,IsIncremental,IsWhereCondition,ROW_NUMBER() OVER( ORDER BY ID DESC) AS ROWNUM 
INTO #SetupConfigDetails
FROM Config.ConfigurationDetails
WHERE  IsActive=1 AND IsIncremental=1


SELECT @Count=COUNT(1) FROM #SetupConfigDetails
SET @RowNumber=1

WHILE(@RowNumber<=@Count)
BEGIN

SELECT @Query=  Query FROM #SetupConfigDetails WHERE ROWNUM=@RowNumber
SELECT @LastRefreshedBasedOn=  LastRefreshedBasedOn FROM #SetupConfigDetails WHERE ROWNUM=@RowNumber
SELECT @LastRefreshedDateTime=  LastRefreshedDateTime FROM #SetupConfigDetails WHERE ROWNUM=@RowNumber

IF EXISTS (SELECT 1 FROM #SetupConfigDetails WHERE IsIncremental=1 AND IsWhereCondition=0 AND RowNum= @RowNumber)
BEGIN

SET @SQL=@Query+' Where '+ @LastRefreshedBasedOn + '>' +''''+@LastRefreshedDateTime+''''

END

IF EXISTS (SELECT 1 FROM #SetupConfigDetails WHERE IsIncremental=1 AND IsWhereCondition=1 AND RowNum= @RowNumber)
BEGIN

SET @SQL=@Query+' AND '+ @LastRefreshedBasedOn + '>' +''''+@LastRefreshedDateTime+''''

END

SELECT @ID=ID FROM #SetupConfigDetails WHERE RowNum=@RowNumber

UPDATE Config.ConfigurationDetails
SET BuildQuery=@SQL
WHERE ID=@ID

SET @RowNumber=@RowNumber+1

END

DROP TABLE #SetupConfigDetails


END