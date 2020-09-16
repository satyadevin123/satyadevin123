

CREATE procedure [dbo].[usp_Insert_Pipeline_Parameters]
(@PipelineId INT)
as
declare @LkpActName NVARCHAR(300),@ForeachActName NVARCHAR(300), @CPActName NVARCHAR(300)

SET @LkpActName = 'LKP_'+CAST(@PipelineId AS VARCHAR)
SET @CPActName = 'CP_'+CAST(@PipelineId AS VARCHAR)
SET @ForeachActName = 'Foreach_SourceEntity_'+CAST(@PipelineId AS VARCHAR)

--TRuncate table [T_Pipeline_Activity_Parameters]

insert into [dbo].[T_Pipeline_Activity_Parameters]

select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+ParameterName
, case 
when ParameterName='dependentActivityName' 
then CASE WHEN DEPTLA.ActivityName IS NULL THEN '' ELSE DEPTLA.ActivityName END
when ParameterName like '%ActivityName%' then CASE WHEN TPS.ActivityName IS NULL THEN TLA.Activitystandardname ELSE TPS.ActivityName END
when ParameterName ='dependson' then CASE WHEN DEPTLA.ActivityName IS NULL THEN '' ELSE DEPTLA.ActivityName END
when ParameterName ='dependencyConditions' then TPS.DependencyCondition
when ParameterName like '%SPParameters%' and tla.ActivityName = 'Custom Logging' 
and TPS.ActivityName like '%InProgress%' then REPLACE(ParameterValue,'$pipelinestatus','InProgress') 
when ParameterName like '%SPParameters%' and tla.ActivityName = 'Custom Logging' 
and TPS.ActivityName like '%Succeeded%' then REPLACE(ParameterValue,'$pipelinestatus','Succeeded')
when ParameterName like '%SPParameters%' and tla.ActivityName = 'Custom Logging' 
and TPS.ActivityName like '%Failed%' then 
REPLACE(ParameterValue,'$pipelinestatus','Failed') + 
   ',                           ""In_ErrorMessage"": {                             
   ""value"": ""@activity('''+DEPTLA.ActivityName +''').Error.Message"",            
   ""type"": ""string""                          }   '
   	 else ParameterValue
end as ParameterValue, TPS.[PipelineActivityId], TP.[PipelineId]
FROM [dbo].[T_Pipelines] TP
JOIN [dbo].[T_Pipeline_Activities] TPS ON TPS.[PipelineId] = TP.[PipelineId]
JOIN [dbo].[T_List_Activities] TLA ON TLA.[ActivityId] = TPS.[ActivityID]
JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.[ActivityId]
LEFT JOIN [dbo].[T_Pipeline_Activities] DEPTLA ON TPS.DependsOn= DEPTLA.[PipelineActivityId]
WHERE 
--TPS.ActivityName IN (@LkpActName,@ForeachActName,@CPActName)
TPS.PipelineId = @PipelineId

DECLARE @MetaLS VARCHAR(200)

SELECT @MetaLS = 'LS_'+LinkedServiceName
FROM T_Pipeline_LinkedServices
WHERE LinkedServiceName like '%metadata%'

UPDATE [T_Pipeline_Activity_Parameters]
SET ParameterValue = @MetaLS
WHERE ParameterName like '%MetadataDBLinkedServiceName%' AND [PipelineId] = @PipelineId

GO


