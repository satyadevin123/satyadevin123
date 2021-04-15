
CREATE PROCEDURE [dbo].[usp_UpdateMaxRefreshDate]
(
	@TableName VARCHAR(128),
	@SchemaName VARCHAR(30),
	@PipelineName VARCHAR(140),
	@MaxRefreshDateTime VARCHAR(30)
)
AS
BEGIN

	SELECT @MaxRefreshDateTime = CASE WHEN @MaxRefreshDateTime = 'NULL' THEN '' ELSE @MaxRefreshDateTime END

	UPDATE	tpt
	SET		tpt.LastRefreshedDateTime = CAST(@MaxRefreshDateTime AS datetime)
	FROM	dbo.T_Pipeline_Tables_ToBeMoved tpt
			INNER JOIN t_pipelines tp
			ON tp.PipelineId = tpt.PipelineId
	WHERE	tp.PipelineName = @PipelineName
			AND tpt.TableName = @TableName 
			AND tpt.SchemaName = @SchemaName

END
GO


