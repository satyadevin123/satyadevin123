
CREATE PROCEDURE dbo.usp_TruncateParameterTables
(
	@PipelineName VARCHAR(140)
)
AS
BEGIN

	DECLARE @PipelineId INT

	SELECT	@PipelineId = PipelineId 
	FROM	dbo.T_Pipelines 
	WHERE	PipelineName = @PipelineName

	DELETE	FROM dbo.T_Pipeline_DataSet_Parameters 
	WHERE	PipelineId = @PipelineId

	DELETE	FROM dbo.T_Pipeline_Activity_Parameters 
	WHERE	PipelineId = @PipelineId

	DELETE	FROM dbo.[T_Pipeline_Activities] 
	WHERE	PipelineId = @PipelineId

	DELETE	FROM T_Pipeline_SourceColumnDetails
	WHERE	PipelineSourceId IN 
			(SELECT PipelineSourceId FROM [T_Pipeline_Tables_ToBeMoved] WHERE [PipelineID] = @PipelineId )

	UPDATE	dbo.[T_Pipeline_Tables_ToBeMoved] 
	SET		IsActive = 0
	WHERE	[PipelineID] = @PipelineId

END