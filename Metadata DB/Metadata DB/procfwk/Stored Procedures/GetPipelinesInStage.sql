﻿CREATE PROCEDURE [procfwk].[GetPipelinesInStage]
	(
	@StageId INT
	)
AS

SET NOCOUNT ON;

BEGIN

	SELECT 
		[PipelineId], 
		[PipelineName],
		[DataFactoryName],
		[ResourceGroupName]
	FROM 
		[procfwk].[CurrentExecution]
	WHERE 
		[StageId] = @StageId
		AND ISNULL([PipelineStatus],'') <> 'Success'
	ORDER BY
		[PipelineId] ASC

END