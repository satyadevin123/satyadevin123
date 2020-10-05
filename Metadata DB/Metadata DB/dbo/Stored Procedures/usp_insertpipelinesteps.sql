
CREATE PROCEDURE [dbo].[usp_insertpipelinesteps]
(@PipelineId INT, @sourcelinkedservicename nvarchar(200),@WithSchema VARCHAR(3)='no')
AS 
BEGIN
declare @dependsonid int
declare @childid int
declare @childid2 int
declare @failedactivityname nvarchar(200)
declare @llinkedserviceid int
declare @LkpActivityName NVARCHAR(200)
declare @FELkpActivityName NVARCHAR(200)
declare @CpyActivityName NVARCHAR(200)
declare @CpySchemaActivityName NVARCHAR(200)
declare @ForeachActivityName NVARCHAR(200)
DECLARE @type VARCHAR(200)
DECLARE @GettokenActivityName NVARCHAR(200)
declare @childactstring varchar(100)

SET @LkpActivityName = 'LKP_'+CAST(@PipelineId AS VARCHAR)
SET @FELkpActivityName = 'FE_LKP'
SET @CpyActivityName = 'CP_'+CAST(@PipelineId AS VARCHAR)
SET @CpySchemaActivityName = 'SchemaCP_'+CAST(@PipelineId AS VARCHAR)
SET @ForeachActivityName = 'Foreach_SourceEntity_'+CAST(@PipelineId AS VARCHAR)


select @type = TLL.LinkedServiceName
from T_Pipeline_LinkedServices TPL
INNER JOIN T_List_LinkedServices TLL
ON TPL.LinkedServiceId  = TLL.LinkedServiceId
where TPL.[LinkedServiceName] = @sourcelinkedservicename

IF (@WithSchema = 'yes')
BEGIN

INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],0,0,1,@CpySchemaActivityName,'' FROM dbo.T_List_Activities where ActivityName = 'Copy Activity'
	AND ISNULL(SourceType,@type)=@type

SELECT @childid2 = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Copy Activity' and tps.pipelineid = @PipelineId and tps.activityname = @CpySchemaActivityName
	AND ISNULL(SourceType,@type)=@type

    UPDATE [T_Pipeline_Activities]
    SET ChildActivity = ChildActivity +','+cast(@childid2 as varchar)
    where PipelineId = @PipelineId AND Activityname = @ForeachActivityName

END
ElSE
BEGIN

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],0,0,1,'SPPipelineInprogressActivity','' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging' AND ISNULL(SourceType,@type)=@type
	
	SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Custom Logging' and tps.pipelineid = @PipelineId and tps.activityname = 'SPPipelineInprogressActivity'

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	AND ISNULL(SourceType,@type)=@type

	if(@type = 'RestService')
	begin

    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,'GetSPNKey','Succeeded' FROM dbo.T_List_Activities where ActivityName = 'Get SPNKey from Vault'
	AND ISNULL(SourceType,@type)=@type

    SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Get SPNKey from Vault' and tps.pipelineid = @PipelineId and tps.activityname = 'GetSPNKey'

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	AND ISNULL(SourceType,@type)=@type

    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,'GetToken','Succeeded' FROM dbo.T_List_Activities where ActivityName = 'Get Token'
	AND ISNULL(SourceType,@type)=@type

    SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Get Token' and tps.pipelineid = @PipelineId and tps.activityname = 'GetToken'
	
    SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	AND ISNULL(SourceType,@type)=@type


    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@CpyActivityName,'Succeeded' FROM dbo.T_List_Activities where ActivityName = 'Copy Activity'
	AND ISNULL(SourceType,@type)=@type

	SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Copy Activity' and tps.pipelineid = @PipelineId and tps.activityname = @CpyActivityName

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)
	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging' AND ISNULL(SourceType,@type)=@type

    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,'SPPipelineSucceededActivity' ,'Succeeded'
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	AND ISNULL(SourceType,@type)=@type


	END

	if(@type != 'RestService')
	begin

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@LkpActivityName,'Succeeded' 
    FROM dbo.T_List_Activities where ActivityName = 'Lookup Activity'
	AND ISNULL(SourceType,@type)=@type
  
    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],0,0,1,@FELkpActivityName,'' FROM dbo.T_List_Activities where ActivityName = 'Lookup Activity'
	AND ISNULL(SourceType,@type)=@type

    SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Lookup Activity' and tps.pipelineid = @PipelineId and tps.activityname = @FELkpActivityName

    
    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@CpyActivityName,'Succeeded' FROM dbo.T_List_Activities where ActivityName = 'Copy Activity'
	AND ISNULL(SourceType,@type)=@type

    
    SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Lookup Activity' and tps.pipelineid = @PipelineId and tps.activityname = @LkpActivityName

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)
	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging' AND ISNULL(SourceType,@type)=@type


	SELECT @childid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Copy Activity' and tps.pipelineid = @PipelineId and tps.activityname = @CpyActivityName
	AND ISNULL(SourceType,@type)=@type

    
    declare @childid3 int
    
    declare @childid4 int
    SELECT @childid3 = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Lookup Activity' and tps.pipelineid = @PipelineId and tps.activityname = @FELkpActivityName
	AND ISNULL(SourceType,@type)=@type

	
    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@childid,0,1,'SP_CopyActivityLogging','Succeeded' FROM dbo.T_List_Activities where ActivityName = 'Copy Activity Logging'
	AND ISNULL(SourceType,@type)=@type
    
    declare @childid1 int
    SELECT @childid1 = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Copy Activity Logging' and tps.pipelineid = @PipelineId and tps.activityname = 'SP_CopyActivityLogging'
	AND ISNULL(SourceType,@type)=@type

    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@childid1,0,1,'SP_MaxRefreshUpdate','Succeeded' FROM dbo.T_List_Activities 
    where ActivityName = 'Update max refresh'
	AND ISNULL(SourceType,@type)=@type
    
    SELECT @childid4 = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'Update max refresh' and tps.pipelineid = @PipelineId and tps.activityname = 'SP_MaxRefreshUpdate'
	AND ISNULL(SourceType,@type)=@type

    
    if (@childid2='' or @childid2 is null)
    set @childactstring = cast(@childid as varchar)+','+cast(@childid1 as varchar)+','+cast(@childid3 as varchar)+','+cast(@childid4 as varchar) 
    else
    set @childactstring = cast(@childid as varchar)+','+cast(@childid1 as varchar)+','+cast(@childid3 as varchar)+','+cast(@childid4 as varchar)+','+cast(@childid2 as varchar) 
    

    INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,@childactstring,1,@ForeachActivityName,'Succeeded'
    FROM dbo.T_List_Activities where ActivityName = 'For Each Activity'
	AND ISNULL(SourceType,@type)=@type

    
    SELECT @dependsonid = tps.[PipelineActivityId] from [dbo].[T_Pipeline_Activities] tps inner join dbo.t_list_activities tla 
    on tps.[ActivityID] = tla.[ActivityId]
    where tla.activityname = 'For Each Activity' and tps.pipelineid = @PipelineId and tps.activityname = @ForeachActivityName

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	AND ISNULL(SourceType,@type)=@type

	INSERT INTO dbo.[T_Pipeline_Activities] (PipelineId,[ActivityID],DependsOn,[ChildActivity],EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,[ActivityId],@dependsonid,0,1,'SPPipelineSucceededActivity' ,'Succeeded'
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	AND ISNULL(SourceType,@type)=@type

	end

	
    
	
END


END
GO


