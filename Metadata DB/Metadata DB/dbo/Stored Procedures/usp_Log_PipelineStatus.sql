CREATE PROC [dbo].[usp_Log_PipelineStatus] 
@In_PipelineRunID UNIQUEIDENTIFIER,
@In_PipelineName [VARCHAR](100),
@In_PipelineStatus [VARCHAR](50),
@In_ExecutionStartTime [DATETIME],
@In_ExecutionEndTime [DATETIME],
@In_ErrorMessage VARCHAR(4000) = ''
AS
BEGIN


DECLARE @PipelineId INT

SELECT @PipelineId = [PipelineId]
FROM T_Pipelines WHERE PipelineName = @In_PipelineName

IF (@In_PipelineStatus = 'InProgress')
BEGIN
	INSERT INTO Audit.PipelineStatusDetails
	(
	[PipelineId]
	,[RunId]
	,[PipelineName]
	,[PipelineStatus]
	,[ExecutionStartTime]
	,[ExecutionEndTime]
	
	)
	SELECT
	@PipelineId ,
	@In_PipelineRunID,
	@In_PipelineName ,
	@In_PipelineStatus ,
	getdate(),
	NULL

END

ELSE
BEGIN

UPDATE Audit.PipelineStatusDetails
SET [ExecutionEndTime] = getdate(),
[PipelineStatus] = @In_PipelineStatus,
ErrorMessage = @In_ErrorMessage
WHERE PipelineId = @PipelineId AND ExecutionEndTime IS NULL
AND [RunId] = @In_PipelineRunID

END
END
GO


