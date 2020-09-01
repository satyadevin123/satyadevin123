
CREATE procedure [dbo].[usp_Insert_Pipeline_Parameters]
(@LkpActName NVARCHAR(300),@ForeachActName NVARCHAR(300), @CPActName NVARCHAR(300),@PipelineId INT)
as

--TRuncate table [T_Pipeline_Activity_Parameters]

insert into [dbo].[T_Pipeline_Activity_Parameters]

select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+parameterName
, case 
when ParameterName='dependentactivityname' 
then CASE WHEN DEPTLA.Activityname IS NULL THEN '' ELSE DEPTLA.Activityname END
when parametername like '%activityname%' then CASE WHEN TPS.Activityname IS NULL THEN TLA.Activitystandardname ELSE TPS.Activityname END
when parametername ='dependson' then CASE WHEN DEPTLA.Activityname IS NULL THEN '' ELSE DEPTLA.Activityname END
when parametername ='dependencyConditions' then TPS.DependencyCondition
when ParameterName like '%SPParameters%' and tla.ActivityName = 'Custom Logging' 
and TPS.Activityname like '%InProgress%' then REPLACE(ParameterValue,'$pipelinestatus','InProgress') 
when ParameterName like '%SPParameters%' and tla.ActivityName = 'Custom Logging' 
and TPS.Activityname like '%Succeeded%' then REPLACE(ParameterValue,'$pipelinestatus','Succeeded')
when ParameterName like '%SPParameters%' and tla.ActivityName = 'Custom Logging' 
and TPS.Activityname like '%Failed%' then 
REPLACE(ParameterValue,'$pipelinestatus','Failed') + 
   ',                           ""In_ErrorMessage"": {                             
   ""value"": ""@activity('''+DEPTLA.Activityname +''').Error.Message"",            
   ""type"": ""string""                          }   '
   	 else parametervalue
end as ParameterValue, TPS.Id, TP.id
FROM [dbo].[T_Pipelines] TP
JOIN [dbo].[T_Pipelines_steps] TPS ON TPS.pipelineid = TP.ID
JOIN [dbo].[T_List_Activities] TLA ON TLA.ID = TPS.Activity_ID
JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.ID
LEFT JOIN [dbo].[T_Pipelines_steps] DEPTLA ON TPS.DependsOn= DEPTLA.id
WHERE 
--TPS.Activityname IN (@LkpActName,@ForeachActName,@CPActName)
TPS.PipelineId = @PipelineId


UPDATE [T_Pipeline_Activity_Parameters]
SET Parametervalue = REPLACE(@LkpActName,'LKP_','')
WHERE ParameterName like '%MetadataDBLinkedServiceName%' AND pipelineid = @PipelineId
GO


