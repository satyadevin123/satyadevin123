
CREATE procedure [dbo].[usp_return_activitycode] 
@PipelineID Int
as

declare @pipelinename nvarchar(100)

select @pipelinename = PipelineName
from T_Pipelines where [PipelineId] = @PipelineID

DECLARE @activity_code TABLE (ID INT IDENTITY(1,1),ActivityJsoncode VARCHAR(MAX),PipelineActivityId INT)
INSERT INTO @activity_code

SELECT 
		CASE WHEN A.RowNumber >1 THEN CASE WHEN ISNULL(A.[ChildActivity],'0')<>'0' THEN ','+REPLACE(A.Code,'$'+ActivityName+'_'+'activityJsoncode',code1) ELSE ','+A.Code END 
		ELSE CASE WHEN ISNULL(A.[ChildActivity],'0')<>'0' THEN REPLACE(A.Code,'$'+ActivityName+'_'+'activityJsoncode',code1) ELSE A.Code END END AS Code
		,A.PipelineActivityId 
		
FROM (
		SELECT 
				 ROW_NUMBER() OVER(ORDER BY TPS.[PipelineActivityId]) AS RowNumber
				,REPLACE(REPLACE(TLS.[JsonCode],'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_'),'$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_master_','$') AS Code
				,TPS.[PipelineActivityId] AS PipelineActivityId
				,TPS.EmailNotificationEnabled
				,TPS.[ChildActivity]
				,CASE WHEN TPS.[PipelineActivityId] IN (select distinct cast(value as int) from T_Pipeline_Activities tpa
cross apply (select value from string_split(tpa.ChildActivity,',') ) as a
where value <> 0
) THEN 'Yes' ELSE 'No' END AS IsChildActivity
				,ISNULL(TPS.ActivityName,TLS.ActivityStandardName) AS ActivityName
				,code1
		FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipeline_Activities] TPS on TP.[PipelineId] = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.[ActivityId] = TPS.[ActivityID]
		CROSS APPLY (select dbo.usp_return_childcode(TPS.pipelineactivityid, TPS.childactivity)) t(code1)
		WHERE TP.[PipelineId] = @PipelineID
		) A
WHERE A.IsChildActivity='No'

Declare @configvalues varchar(8000)
select @configvalues=coalesce(@configvalues+ ',','')+'"'+ConfigName+'":"'+configvalue+'"' from [dbo].[T_ConfigurationDetails]

insert into @activity_code select ', {
                "name": "Execute Send Mail for failed activity '+CAST(PS.[PipelineActivityId] AS nvarchar)+'",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "'+ISNULL(PS1.Activityname,LS.ActivityStandardName)+'",
                        "dependencyConditions": ["Succeeded"]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "Sendmail",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true,
                    "parameters": {
					"EmailTo": "$EmailTo",
                        "Activity": "'+ISNULL(REPLACE(LOWER(PS.Activityname),'_',''),LS.ActivityStandardName)+'",
                        "Message": "failed at activity '+ISNULL(REPLACE(LOWER(PS.Activityname),'_',''),LS.ActivityStandardName)+'",
						"PipelineName": "'+@pipelinename+'"
				}
                }
            }
        ',
		
		NULL FROM [dbo].[T_Pipelines] P
INNER JOIN [dbo].[T_Pipeline_Activities] PS on P.[PipelineId] = PS.PipelineiD
INNER JOIN [dbo].[T_Pipeline_Activities] PS1 on PS.PipelineId = PS1.PipelineiD AND PS.[PipelineActivityId] = PS1.DependsOn
AND ps1.DependencyCondition = 'Failed'
INNER JOIN [dbo].[T_List_Activities] LS on LS.[ActivityId] = PS.[ActivityID]
WHERE PS.EmailNotificationEnabled=1
and ps.[PipelineActivityId] not in 
(select distinct cast(value as int) from T_Pipeline_Activities tpa
cross apply (select value from string_split(tpa.ChildActivity,',') ) as a
where value <> 0 and tpa.PipelineId = @PipelineID)
AND ps1.Activityname like '%SPPipelineFailedActivity%'
AND P.PipelineId = @PipelineID

SELECT ActivityJsoncode FROM @activity_code
GO


