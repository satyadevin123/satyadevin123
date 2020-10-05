
CREATE PROCEDURE usp_UpdatePipelineTablesQuery
(@PipelineId INT, @TableName NVARCHAR(300), @SchemaName NVARCHAR(30),@IsIncremental VARCHAR(3),@RefreshBasedOn VARCHAR(255))
AS
BEGIN

DECLARE @ColList VARCHAR(8000)

SELECT @ColList = ' '

SELECT @ColList = @ColList + tps.ColumnName + ','
FROM 
T_Pipeline_SourceColumnDetails tps
INNER JOIN T_Pipeline_Tables_ToBeMoved tpt
ON tps.PipelineSourceId = tpt.PipelineSourceId
WHERE pipelineid = @PipelineId AND TableName = @TableName AND SchemaName = @SchemaName

SELECT @ColList = CASE WHEN @ColList = ' ' THEN '*' ELSE SUBSTRING(@ColList,1,LEN(@ColList)-1) END

UPDATE T_Pipeline_Tables_ToBeMoved
SET Query = 'SELECT '+ @ColList +' FROM ' + @SchemaName + '.'+@TableName 
,ColumnList = SUBSTRING(@ColList,1,LEN(@ColList)-1) 
,BuildQuery = CASE WHEN @RefreshBasedOn <> '' THEN 'SELECT '+ SUBSTRING(@ColList,1,LEN(@ColList)-1) +' FROM ' + @SchemaName + '.'+@TableName ELSE NULL END
WHERE pipelineid = @PipelineId AND TableName = @TableName AND SchemaName = @SchemaName



END