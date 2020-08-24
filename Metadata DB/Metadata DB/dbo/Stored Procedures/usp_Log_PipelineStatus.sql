

CREATE PROC [dbo].[usp_Log_PipelineStatus] @In_PipelineID [VARCHAR](100),@In_PipelineName [VARCHAR](100),@In_PipelineStatus [VARCHAR](50),@In_ExecutionStartTime [DATETIME],@In_ExecutionEndTime [DATETIME],@In_EntityName [VARCHAR](200) AS
BEGIN

	INSERT INTO audit.PipelineStatusDetails
	(
	[PipelineId]
	,[PipelineName]
	,[PipelineStatus]
	,[ExecutionStartTime]
	,[ExecutionEndTime]
	,[EntityName]
	)
	SELECT
	@In_PipelineID ,
	@In_PipelineName ,
	@In_PipelineStatus ,
	@In_ExecutionStartTime,
	@In_ExecutionEndTime,
	@In_EntityName

END