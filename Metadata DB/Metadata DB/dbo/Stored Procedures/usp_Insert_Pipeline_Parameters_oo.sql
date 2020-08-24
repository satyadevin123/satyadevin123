

CREATE procedure [dbo].[usp_Insert_Pipeline_Parameters_oo]
as

TRuncate table [T_Pipeline_Activity_Parameters]

insert into [dbo].[T_Pipeline_Activity_Parameters]

select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+parameterName
, case when parametername like '%activityname%' then CASE WHEN TPS.Activityname IS NULL THEN TLA.Activitystandardname ELSE TPS.Activityname END
when parametername ='dependenson' then DEPTLA.ActivityStandardName
when parametername ='dependencyConditions' then 'Succeeded'
when ParameterName='dependentactivityname' then (select ActivityName from [T_List_Activities] where id =TPS.Child_Activity)
--when ParameterName='activityjsoncode' then (select code from [T_List_Activities] where id =TPS.Child_Activity)
else parametervalue
end as ParameterValue, TPS.Id, TP.id
FROM [dbo].[T_Pipelines] TP
JOIN [dbo].[T_Pipelines_steps] TPS ON TPS.pipelineid = TP.ID
JOIN [dbo].[T_List_Activities] TLA ON TLA.ID = TPS.Activity_ID
JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.ID
LEFT JOIN [dbo].[T_List_Activities] DEPTLA ON TPS.DependsOn= DEPTLA.id