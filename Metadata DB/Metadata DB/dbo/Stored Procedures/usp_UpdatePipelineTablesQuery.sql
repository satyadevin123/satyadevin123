
CREATE PROCEDURE usp_UpdatePipelineTablesQuery
(@PipelineId INT, @TableName NVARCHAR(300), @SchemaName NVARCHAR(30),@IsIncremental VARCHAR(3),@RefreshBasedOn VARCHAR(255))
AS
BEGIN

DECLARE @ColList VARCHAR(8000)
DECLARE @NameString VARCHAR(500)

SELECT @ColList = ' '

SELECT @ColList = @ColList + tps.ColumnName + ','
FROM 
T_Pipeline_SourceColumnDetails tps
INNER JOIN T_Pipeline_Tables_ToBeMoved tpt
ON tps.PipelineSourceId = tpt.PipelineSourceId
WHERE [PipelineID] = @PipelineId AND TableName = @TableName AND ISNULL(SchemaName,'') = ISNULL(@SchemaName,'')

SELECT @ColList = CASE WHEN @ColList = ' ' THEN '*' ELSE SUBSTRING(@ColList,1,LEN(@ColList)-1) END


SELECT @NameString = CASE WHEN @SchemaName IS NULL OR @SchemaName = '' THEN @TableName ELSE @SchemaName + '.'+@TableName END

UPDATE T_Pipeline_Tables_ToBeMoved
SET Query = 'SELECT '+ @ColList +' FROM ' + @NameString
,ColumnList = SUBSTRING(@ColList,1,LEN(@ColList)-1) 
,BuildQuery = CASE WHEN @RefreshBasedOn <> '' THEN 'SELECT '+ SUBSTRING(@ColList,1,LEN(@ColList)-1) +' FROM ' + @NameString ELSE NULL END
,CntQuery = 'SELECT COUNT(1) AS Cnt FROM ' + @NameString
WHERE [PipelineID] = @PipelineId AND TableName = @TableName AND ISNULL(SchemaName,'') = ISNULL(@SchemaName,'')



END