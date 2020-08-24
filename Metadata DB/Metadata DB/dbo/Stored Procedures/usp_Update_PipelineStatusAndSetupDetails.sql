
CREATE PROC [dbo].[usp_Update_PipelineStatusAndSetupDetails] @in_InsertedRecords [Int],@in_UpdatedRecords [Int],@in_EntityName [VARCHAR](200),@in_LastRefreshedDateTime [DATETIME],@in_ProcessingCompletionDate [DATETIME] AS
BEGIN

UPDATE Config.ConfigurationDetails
SET Config.ConfigurationDetails.ProcessingCompletionDate=@in_ProcessingCompletionDate,Config.ConfigurationDetails.IsRestart=0
FROM [Audit].[PipelineStatusDetails] P
WHERE  Config.ConfigurationDetails.EntityName=@in_EntityName
AND ISNULL(Config.ConfigurationDetails.ProcessingCompletionDate,'')<@in_ProcessingCompletionDate
 AND P.PipelineStatus='CopyToADLS Completed'


UPDATE Config.ConfigurationDetails
SET LastRefreshedDateTime=@in_LastRefreshedDateTime
WHERE  EntityName=@in_EntityName
AND ISNULL(LastRefreshedDateTime,'')<@in_LastRefreshedDateTime


UPDATE [Audit].[PipelineStatusDetails] 
SET PipelineStatus='Success',ExecutionEndTime=GETDATE(),TotalRecords=CopiedRowCount,
InsertedRecords=@in_InsertedRecords,UpdatedRecords=@in_UpdatedRecords,NoImpactRecords=CopiedRowCount-(ISNULL(@in_InsertedRecords,0)+ISNULL(@in_UpdatedRecords,0))
WHERE  PipelineStatus='CopyToADLS Completed' AND EntityName=@in_EntityName




END