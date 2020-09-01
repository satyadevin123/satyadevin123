
CREATE PROCEDURE [dbo].[usp_insertpipelinesteps]
(@PipelineId INT, @LkpActivityName NVARCHAR(200), @CpyActivityName NVARCHAR(200), @ForeachActivityName NVARCHAR(200))
AS 
BEGIN
declare @dependsonid int
declare @childid int
declare @failedactivityname nvarchar(200)

	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,0,0,1,'SPPipelineInprogressActivity','' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	
	SELECT @dependsonid = tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
    on tps.activity_id = tla.id
    where tla.activityname = 'Custom Logging' and tps.pipelineid = @PipelineId and tps.activityname = 'SPPipelineInprogressActivity'

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)

	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'


	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,@dependsonid,0,1,@LkpActivityName,'Succeeded' 
    FROM dbo.T_List_Activities where ActivityName = 'Lookup Activity'

  
    INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,0,0,1,@CpyActivityName,'' FROM dbo.T_List_Activities where ActivityName = 'Copy Activity'

    SELECT @dependsonid = tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
    on tps.activity_id = tla.id
    where tla.activityname = 'Lookup Activity' and tps.pipelineid = @PipelineId and tps.activityname = @LkpActivityName

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)


	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'

	SELECT @childid = tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
    on tps.activity_id = tla.id
    where tla.activityname = 'Copy Activity' and tps.pipelineid = @PipelineId and tps.activityname = @CpyActivityName

	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,@dependsonid,@childid,1,@ForeachActivityName,'Succeeded'
    FROM dbo.T_List_Activities where ActivityName = 'For Each Activity'

    SELECT @dependsonid = tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
    on tps.activity_id = tla.id
    where tla.activityname = 'For Each Activity' and tps.pipelineid = @PipelineId and tps.activityname = @ForeachActivityName

	SET @failedactivityname = CONCAT('SPPipelineFailedActivity',@dependsonid)

	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,@dependsonid,0,1,@failedactivityname,'Failed' 
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'


    INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName,DependencyCondition)
    SELECT @PipelineId,id,@dependsonid,0,1,'SPPipelineSucceededActivity' ,'Succeeded'
    FROM dbo.T_List_Activities where ActivityName = 'Custom Logging'
	
	



END
GO


