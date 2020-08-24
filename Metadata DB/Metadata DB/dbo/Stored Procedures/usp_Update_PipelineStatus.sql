
CREATE PROC [dbo].[usp_Update_PipelineStatus] @In_PipelineID [VARCHAR](100),@In_ExecutionEndTime [DATETIME],@In_PipelineStatus [VARCHAR](50),@In_CopyToADLSTime [int],@In_CopiedRowCount [int],@In_EntityName [VARCHAR](200) AS
BEGIN

	UPDATE audit.PipelineStatusDetails
	SET PipelineStatus=@In_PipelineStatus , ExecutionEndTime=@In_ExecutionEndTime ,CopyToADLSTimeInSeconds=@In_CopyToADLSTime,CopiedRowCount=@In_CopiedRowCount
	WHERE EntityName=@In_EntityName AND  PipeLineStatus='CopyToADLS InProgress'

END