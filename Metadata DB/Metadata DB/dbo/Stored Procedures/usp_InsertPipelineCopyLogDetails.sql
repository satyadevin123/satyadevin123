
CREATE PROCEDURE [dbo].[usp_InsertPipelineCopyLogDetails]
(
	@In_PipelineRunID UNIQUEIDENTIFIER,
	@In_RowsCopied BIGINT,
	@In_RowsRead BIGINT,
	@In_Duration INT,
	@In_Status VARCHAR(40),
	@In_StartTime DATETIME,
	@In_EndTime DATETIME,
	@In_EntityName VARCHAR(128)
)
AS 
BEGIN
	INSERT INTO Audit.[pipeline_Copy_Activity_log]
	(
		[RunId]
		,[rowsCopied]
		,[RowsRead]
		,[copyDuration_in_secs]
		,[Execution_Status]
		,[CopyActivity_Start_Time]
		,[CopyActivity_End_Time]
		,[EntityName]
	)
	SELECT 
		@In_PipelineRunID
		,@In_RowsCopied
		,@In_RowsRead
		,@In_Duration
		,@In_Status
		,@In_StartTime
		,@In_EndTime
		,@In_EntityName


END
GO


