
CREATE PROCEDURE [dbo].[usp_UpdateMaxRefreshDate]
(
@TableName VARCHAR(255),
@SchemaName VARCHAR(255),
@PipelineName VARCHAR(255),
@MaxRefreshDateTime VARCHAR(30)
)
AS
BEGIN

SELECT @MaxRefreshDateTime = CASE WHEN @MaxRefreshDateTime = 'NULL' THEN '' ELSE @MaxRefreshDateTime END


UPDATE tpt
SET
tpt.LastRefreshedDateTime = CAST(@MaxRefreshDateTime AS datetime)
FROM
t_pipeline_tables_tobemoved tpt
INNER JOIN t_pipelines tp
ON tp.PipelineId = tpt.PipelineId
WHERE tp.PipelineName = @PipelineName
AND tpt.TableName = @TableName AND tpt.SchemaName = @SchemaName

END
GO


