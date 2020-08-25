﻿CREATE PROCEDURE usp_insertpipelinesteps
(@PipelineId INT, @LkpActivityName NVARCHAR(200), @CpyActivityName NVARCHAR(200), @ForeachActivityName NVARCHAR(200))
AS 
BEGIN
declare @dependsonid int
declare @childid int
    
	
	INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName)
    SELECT @PipelineId,id,0,0,1,@LkpActivityName 
    FROM dbo.T_List_Activities where ActivityName = 'Lookup Activity'

    
    INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName)
    SELECT @PipelineId,id,0,0,1,@CpyActivityName FROM dbo.T_List_Activities where ActivityName = 'Copy Activity'

      SELECT @dependsonid = tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
    on tps.activity_id = tla.id
    where tla.activityname = 'Lookup Activity' and tps.pipelineid = @PipelineId and tps.activityname = @LkpActivityName

    
    SELECT @childid = tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
    on tps.activity_id = tla.id
    where tla.activityname = 'Copy Activity' and tps.pipelineid = @PipelineId and tps.activityname = @CpyActivityName


INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName)
    SELECT @PipelineId,id,@dependsonid,@childid,1,@ForeachActivityName
    FROM dbo.T_List_Activities where ActivityName = 'For Each Activity'

END
