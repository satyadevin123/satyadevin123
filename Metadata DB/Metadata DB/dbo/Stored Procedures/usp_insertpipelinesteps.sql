CREATE PROCEDURE [dbo].[usp_insertpipelinesteps]
(@PipelineId INT, @sourcelinkedservicename nvarchar(200),@WithSchema VARCHAR(3)='no')
AS 
BEGIN

DECLARE @type VARCHAR(200)

select @type = TLL.LinkedServiceName
from T_Pipeline_LinkedServices TPL
INNER JOIN T_List_LinkedServices TLL
ON TPL.LinkedServiceId  = TLL.LinkedServiceId
where TPL.[LinkedServiceName] = @sourcelinkedservicename

declare @LkpActivityName NVARCHAR(200)
declare @FELkpActivityName NVARCHAR(200)
declare @FELkpCntActivityName NVARCHAR(200)
declare @CpyActivityName NVARCHAR(200)
declare @CpySchemaActivityName NVARCHAR(200)
declare @ForeachActivityName NVARCHAR(200)
declare @IfActivityName VARCHAR(200)

SET @LkpActivityName = 'LKP_'+CAST(@PipelineId AS VARCHAR)
SET @FELkpActivityName = 'FE_LKP'
SET @FELkpCntActivityName = 'FE_LKP_CNT'
SET @CpyActivityName = 'CP_'+CAST(@PipelineId AS VARCHAR)
SET @CpySchemaActivityName = 'SchemaCP_'+CAST(@PipelineId AS VARCHAR)
SET @ForeachActivityName = 'Foreach_SourceEntity_'+CAST(@PipelineId AS VARCHAR)
SET @IfActivityName = 'IfCondition'


declare @pipelinesteps table
(
ID INT ,
ActivityName varchar(255),
ActivityType VARCHAR(100),
ChildActivity VARCHAR(MAX),
DependsOnActivityName VARCHAR(255),
DependencyCondition VARCHAR(30),
IfActivity VARCHAR(MAX),
ElseActivity VARCHAR(MAX),
ParentActivity VARCHAR(255)
)

IF(@type = 'RestService')
BEGIN

insert into @pipelinesteps (ID,ActivityName,ActivityType,ChildActivity,DependsOnActivityName,DependencyCondition)
values
(1,'SPPipelineInprogressActivity','Custom Logging',NULL,NULL,NULL),
(2,'SPPipelineFailedActivity1','Custom Logging',NULL,'SPPipelineInprogressActivity','Failed'),
(3,'GetSPNKey','Get SPNKey from Vault',NULL,'SPPipelineInprogressActivity','Succeeded'),
(4,'SPPipelineFailedActivity2','Custom Logging',NULL,'GetSPNKey','Failed'),
(5,'GetToken','Get Token',NULL,'GetSPNKey','Succeeded'),
(6,'SPPipelineFailedActivity3','Custom Logging',NULL,'GetToken','Failed'),
(7,@CpyActivityName,'Copy Activity',NULL,'GetToken','Succeeded'),
(8,'SPPipelineFailedActivity4','Custom Logging',NULL,@CpyActivityName,'Failed'),
(9,'SPPipelineSucceededActivity','Custom Logging',NULL,@CpyActivityName,'Succeeded')

END

IF(@type != 'RestService')
BEGIN
IF (@WithSchema = 'no')
BEGIN

insert into @pipelinesteps 
(ID,ActivityName,ActivityType,ChildActivity,DependsOnActivityName,DependencyCondition,IfActivity,ElseActivity,ParentActivity)
values
(1,'SPPipelineInprogressActivity','Custom Logging',NULL,NULL,NULL,NULL,NULL,NULL),
(2,'SPPipelineFailedActivity1','Custom Logging',NULL,'SPPipelineInprogressActivity','Failed',NULL,NULL,NULL),
(3,@LkpActivityName,'Lookup Activity',NULL,'SPPipelineInprogressActivity','Succeeded',NULL,NULL,NULL),
(4,'SPPipelineFailedActivity2','Custom Logging',NULL,@LkpActivityName,'Failed',NULL,NULL,NULL),
(5,@FELkpActivityName,'Lookup Activity',NULL,NULL,NULL,NULL,NULL,@ForeachActivityName),
(6,@FELkpCntActivityName,'Lookup Activity',NULL,@FELkpActivityName,'Succeeded',NULL,NULL,@ForeachActivityName),
(7,@IfActivityName,'IfCondition',NULL,@FELkpCntActivityName,'Succeeded',CONCAT(@CpyActivityName,',','SP_CopyActivityLogging',',','SP_MaxRefreshUpdate'),'SP_CopyActivityLoggingNoDeltaRecords',@ForeachActivityName),
(8,@CpyActivityName,'Copy Activity',NULL,NULL,NULL,NULL,NULL,NULL),
(9,'SP_CopyActivityLogging','Copy Activity Logging',NULL,@CpyActivityName,'Succeeded',NULL,NULL,NULL),
(10,'SP_MaxRefreshUpdate','Update max refresh',NULL,'SP_CopyActivityLogging','Succeeded',NULL,NULL,NULL),
(11,'SP_CopyActivityLoggingNoDeltaRecords','Copy Activity Logging',NULL,NULL,NULL,NULL,NULL,NULL),
(12,'SPPipelineFailedActivity3','Custom Logging',NULL,@ForeachActivityName,'Failed',NULL,NULL,NULL),
(13,'SPPipelineSucceededActivity','Custom Logging',NULL,@ForeachActivityName,'Succeeded',NULL,NULL,NULL),
(14,@ForeachActivityName,'For Each Activity',CONCAT(@IfActivityName,',',@FELkpCntActivityName,',',@FELkpActivityName),@LkpActivityName,'Succeeded',NULL,NULL,NULL)
END

IF (@WithSchema = 'yes')
BEGIN

insert into @pipelinesteps
values
(15,@CpySchemaActivityName,'Copy Activity',NULL,NULL,NULL,NULL,NULL,NULL)


END

END

select * from @pipelinesteps

insert into t_pipeline_activities
(pipelineid,activityid,emailnotificationenabled,activityname)
select 
@Pipelineid,tla.ActivityId,1,p.ActivityName
from @pipelinesteps p 
inner join dbo.T_List_Activities tla 
on tla.ActivityName = p.ActivityType
	AND ISNULL(SourceType,@type)=@type
	order by ID

UPDATE tpa
SET DependsOn = tpa1.PipelineActivityId,
DependencyCondition = p.DependencyCondition
FROM t_pipeline_activities tpa
INNER JOIN @pipelinesteps p
ON tpa.activityname = p.activityname
INNER JOIN t_pipeline_activities tpa1
ON tpa1.ActivityName = p.DependsOnActivityName
AND tpa.PipelineId = tpa1.PipelineId
WHERE tpa.PipelineId = @PipelineId

IF (@WithSchema='no')
begin
UPDATE tpa
SET tpa.childactivity = a.val 
FROM 
t_pipeline_activities tpa INNER JOIN 
(select tpa.ActivityName,string_agg(tpa1.PipelineActivityId, ',') as val
from
 t_pipeline_activities tpa
INNER JOIN @pipelinesteps p
ON tpa.activityname = p.activityname
CROSS APPLY string_split(p.ChildActivity,',') t

INNER JOIN t_pipeline_activities tpa1
ON tpa1.ActivityName = t.value
AND tpa.PipelineId = tpa1.PipelineId
WHERE tpa.PipelineId = @PipelineId

AND p.ChildActivity IS NOT NULL
group by tpa.ActivityName
) a
on tpa.ActivityName = a.ActivityName
WHERE tpa.PipelineId = @PipelineId


UPDATE tpa
SET tpa.IfActivity = a.val 
FROM 
t_pipeline_activities tpa INNER JOIN 
(select tpa.ActivityName,string_agg(tpa1.PipelineActivityId, ',') as val
from
 t_pipeline_activities tpa
INNER JOIN @pipelinesteps p
ON tpa.activityname = p.activityname
CROSS APPLY string_split(p.IfActivity,',') t

INNER JOIN t_pipeline_activities tpa1
ON tpa1.ActivityName = t.value
AND tpa.PipelineId = tpa1.PipelineId

WHERE tpa.PipelineId = @PipelineId
AND p.IfActivity IS NOT NULL
group by tpa.ActivityName
) a
on tpa.ActivityName = a.ActivityName
WHERE tpa.PipelineId = @PipelineId



UPDATE tpa
SET tpa.ElseActivity = a.val 
FROM 
t_pipeline_activities tpa INNER JOIN 
(select tpa.ActivityName,string_agg(tpa1.PipelineActivityId, ',') as val
from
 t_pipeline_activities tpa
INNER JOIN @pipelinesteps p
ON tpa.activityname = p.activityname
CROSS APPLY string_split(p.ElseActivity,',') t

INNER JOIN t_pipeline_activities tpa1
ON tpa1.ActivityName = t.value
AND tpa.PipelineId = tpa1.PipelineId

WHERE tpa.PipelineId = @PipelineId
AND p.ElseActivity IS NOT NULL
group by tpa.ActivityName
) a
on tpa.ActivityName = a.ActivityName
WHERE tpa.PipelineId = @PipelineId

end
else
begin

declare @childschemaid int
select @childschemaid = PipelineActivityId
from T_Pipeline_Activities 
where PipelineId = @PipelineId and Activityname = @CpySchemaActivityName

UPDATE T_Pipeline_Activities
set IfActivity = IfActivity+','+cast(@childschemaid as varchar)
where PipelineId = @PipelineId and Activityname = @IfActivityName


end

UPDATE TPA
SET TPA.ParentActivity = tpa1.PipelineActivityId
FROM
 T_Pipeline_Activities tpa1
INNER JOIN @pipelinesteps p
ON tpa1.Activityname = p.ParentActivity
INNER JOIN T_Pipeline_Activities tpa
on tpa.Activityname = p.ActivityName
END
GO


