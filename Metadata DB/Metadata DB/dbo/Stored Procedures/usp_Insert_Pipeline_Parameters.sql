CREATE procedure [dbo].[usp_Insert_Pipeline_Parameters]
as

TRuncate table [T_Pipeline_LinkedService_Parameters]
TRuncate table [T_Pipeline_DataSet_Parameters]
TRuncate table [T_Pipeline_Activity_Parameters]

insert into [dbo].[T_Pipeline_LinkedService_Parameters]

select parameterName, ParameterValue, TPLS.LinkedServiceId, TP.id
FROM [dbo].[T_Pipelines] TP
JOIN [dbo].[T_Pipeline_LinkedServices]TPLS ON TPLS.pipelineid = TP.ID
JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.ID = TPLS.LinkedServiceId
JOIN [dbo].[T_List_LinkedService_Parameters] TLLP ON TLLP.LinkedServiceId = TLL.ID

insert into [dbo].[T_Pipeline_DataSet_Parameters]

select parameterName, ParameterValue, TPD.DataSetID, TP.id
FROM [dbo].[T_Pipelines] TP
JOIN [dbo].[T_Pipeline_DataSets] TPD ON TPD.pipelineid = TP.ID
JOIN [dbo].[T_List_DataSets] TLD ON TLD.ID = TPD.DatasetId
JOIN [dbo].[T_List_DataSet_Parameters] TLDP ON TLDP.DataSetID = TLD.ID

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

--insert into [dbo].[T_Pipeline_Activity_Parameters]

--select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+parameterName
--, case when parametername like '%activityname%' then CASE WHEN TPS.Activityname IS NULL THEN TLA.Activitystandardname ELSE TPS.Activityname END
--when parametername ='dependenson' then DEPTLA.ActivityStandardName
--when parametername ='dependencyConditions' then 'Success'
--when ParameterName='dependentactivityname' then (select ActivityName from [T_List_Activities] where id =TPS.Child_Activity)
--when ParameterName='activityjsoncode' then (select code from [T_List_Activities] where id =TPS.Child_Activity)
--else parametervalue
--end as ParameterValue, TPS.Id, TP.id
--FROM [dbo].[T_Pipelines] TP
--JOIN [dbo].[T_Pipelines_steps] TPS ON TPS.pipelineid = TP.ID
--JOIN [dbo].[T_List_Activities] TLA ON TLA.ID = TPS.Child_Activity
--JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.ID
--LEFT JOIN [dbo].[T_List_Activities] DEPTLA ON TPS.DependsOn= DEPTLA.id



--Where TLA.ID=4

------insert into [dbo].[T_Pipeline_Activity_Parameters]
------select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+parameterName
------, case when parametername ='Lookupactivityname' then CASE WHEN TPS.Activityname IS NULL THEN TLA.Activitystandardname ELSE TPS.Activityname END
------when parametername ='dependenson' then DEPTLA.ActivityStandardName
------when parametername ='dependencyConditions' then 'Success'
------else parametervalue
------end as ParameterValue, TPS.Id, TP.id
------FROM [dbo].[T_Pipelines] TP
------JOIN [dbo].[T_Pipelines_steps] TPS ON TPS.pipelineid = TP.ID
------JOIN [dbo].[T_List_Activities] TLA ON TLA.ID = TPS.Activity_ID
------JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.ID
------LEFT JOIN [dbo].[T_List_Activities] DEPTLA ON TPS.DependsOn= DEPTLA.id
------Where TLA.ID=2

------insert into [dbo].[T_Pipeline_Activity_Parameters]
------select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+parameterName
------, case when parametername ='CopyActivityName' then CASE WHEN TPS.Activityname IS NULL THEN TLA.Activitystandardname ELSE TPS.Activityname END
------when parametername ='dependenson' then DEPTLA.ActivityStandardName
------when parametername ='dependencyConditions' then 'Success'
------else parametervalue
------end as ParameterValue, TPS.Id, TP.id
------FROM [dbo].[T_Pipelines] TP
------JOIN [dbo].[T_Pipelines_steps] TPS ON TPS.pipelineid = TP.ID
------JOIN [dbo].[T_List_Activities] TLA ON TLA.ID = TPS.Activity_ID
------JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.ID
------LEFT JOIN [dbo].[T_List_Activities] DEPTLA ON TPS.DependsOn= DEPTLA.id
------Where TLA.ID=3


--insert into [dbo].[T_Pipeline_Activity_Parameters]
--select '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+parameterName
--, case when parametername ='CopyActivityName' then CASE WHEN TPS.Activityname IS NULL THEN TLA.Activitystandardname ELSE TPS.Activityname END
--when parametername ='dependenson' then DEPTLA.ActivityStandardName
--when parametername ='dependencyConditions' then 'Success'
--else parametervalue
--end as ParameterValue, TPS.Id As ActivityId, TP.id
--FROM [dbo].[T_Pipelines] TP
--JOIN [dbo].[T_Pipelines_steps] TPS ON TPS.pipelineid = TP.ID
--JOIN [dbo].[T_List_Activities] TLA ON TLA.ID = TPS.Activity_ID
--JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.ID
--LEFT JOIN [dbo].[T_List_Activities] DEPTLA ON TPS.Child_Activity= DEPTLA.id
--Where TLA.ID=4