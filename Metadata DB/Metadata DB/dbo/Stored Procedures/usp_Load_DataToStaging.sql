
CREATE PROC [dbo].[usp_Load_DataToStaging] @in_EntityName [VARCHAR](200) AS
BEGIN

/*Declare Variables*/
DECLARE @sql NVARCHAR(MAX),
@ColumnList VARCHAR(MAX),
@StagingTable VARCHAR(200),
@ExternalTable VARCHAR(200),
@IsIncremental BIT,
@StoragePath VARCHAR(200),
@sqlAlterExternalTable NVARCHAR(MAX),
@CreateExternalTableScript VARCHAR(8000),
@DropExternalTableScript VARCHAR(800),
@BatchID VARCHAR(100) ,
@sqlBatchUpdate NVARCHAR(MAX)


SELECT * INTO #SetupConfigDetails 
FROM config.ConfigurationDetails
WHERE  EntityName=@in_EntityName

/*Assign Variables*/
SELECT @ColumnList= ColumnList FROM #SetupConfigDetails
SELECT @ExternalTable= ExternalTableName FROM #SetupConfigDetails
SELECT @StagingTable= StagingTableName FROM #SetupConfigDetails
SELECT @IsIncremental= IsIncremental FROM #SetupConfigDetails
SELECT @StoragePath= StoragePath FROM #SetupConfigDetails
SELECT @CreateExternalTableScript= CreateExternalTableScript FROM #SetupConfigDetails


SELECT @BatchID =MAX(ID) FROM [Audit].[PipelineStatusDetails] 
WHERE  EntityName=@in_EntityName AND PipeLineStatus='CopyToADLS InProgress'

/*ALTER The EXTERNAL TABLE Location Path*/

--SET @sqlAlterExternalTable='IF EXISTS ( SELECT * FROM sys.external_tables WHERE object_id = OBJECT_ID('''+@ExternalTable+''') )
--    DROP EXTERNAL TABLE ' +  @ExternalTable +'
--'+ @CreateExternalTableScript + 'WITH (DATA_SOURCE = [fssADLS],LOCATION ='''+@StoragePath+ +'/'+@in_EntityName+  ''',FILE_FORMAT = [uncompressedcsv],REJECT_TYPE = VALUE,REJECT_VALUE = 0)'

--EXEC sp_executesql @sqlAlterExternalTable;


/*Incremental Logic*/
IF @IsIncremental=1
BEGIN

SET @sql=N'INSERT INTO '+  @StagingTable +' ( '+ @ColumnList +' ) ' +' SELECT ' + @ColumnList + ' FROM ' + @ExternalTable

END
ELSE
BEGIN

SET @sql=N' DELETE FROM ' + @StagingTable + ' INSERT INTO '+  @StagingTable +' ( '+ @ColumnList +' ) ' +' SELECT ' + @ColumnList + ' FROM ' + @ExternalTable


END
    EXEC sp_executesql @sql;

       /*Execute the  query to update the batchid in staging table.*/
       SET @sqlBatchUpdate='UPDATE ' + @StagingTable + ' SET BATCHID= '+ @BatchID + ' WHERE BATCHID IS NULL '
       EXEC sp_executesql @sqlBatchUpdate

DROP TABLE  #SetupConfigDetails

END