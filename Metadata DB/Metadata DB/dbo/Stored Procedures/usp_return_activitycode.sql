
CREATE procedure [dbo].[usp_return_activitycode] 
@PipelineID Int
as

declare @pipelinename nvarchar(100)

select @pipelinename = PipelineName
from T_Pipelines where [PipelineId] = @PipelineID

DECLARE @activity_code TABLE (ID INT IDENTITY(1,1),ActivityJsoncode VARCHAR(MAX),PipelineActivityId INT)
INSERT INTO @activity_code

SELECT 
		CASE WHEN A.RowNumber >1 THEN CASE WHEN ISNULL(A.[ChildActivity],0)<>0 THEN ','+REPLACE(A.Code,'$'+ActivityName+'_'+'activityJsoncode',B.Code) ELSE ','+A.Code END 
		ELSE CASE WHEN ISNULL(A.[ChildActivity],0)<>0 THEN REPLACE(A.Code,'$'+ActivityName+'_'+'activityJsoncode',B.Code) ELSE A.Code END END AS Code
		,A.PipelineActivityId 
		
FROM (
		SELECT 
				 ROW_NUMBER() OVER(ORDER BY TPS.[PipelineActivityId]) AS RowNumber
				,REPLACE(REPLACE(TLS.[JsonCode],'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_'),'$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_master_','$') AS Code
				,TPS.[PipelineActivityId] AS PipelineActivityId
				,TPS.EmailNotificationEnabled
				,TPS.[ChildActivity]
				,CASE WHEN TPS.[PipelineActivityId] IN (SELECT [ChildActivity] FROM [dbo].[T_Pipeline_Activities]) THEN 'Yes' ELSE 'No' END AS IsChildActivity
				,ISNULL(TPS.ActivityName,TLS.ActivityStandardName) AS ActivityName
		FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipeline_Activities] TPS on TP.[PipelineId] = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.[ActivityId] = TPS.[ActivityID]
		WHERE TP.[PipelineId] = @PipelineId
) A
LEFT JOIN (
		SELECT 
				 ROW_NUMBER() OVER(ORDER BY TPS.[PipelineActivityId]) AS RowNumber
				,CASE WHEN TPS.[ChildActivity] IS NULL OR TPS.[ChildActivity]='' THEN REPLACE(TLS.[JsonCode],'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_') 
					  WHEN TPS.[ChildActivity] IS NOT NULL THEN REPLACE(REPLACE(REPLACE(TLS.[JsonCode],'$activityjsoncode',ChildTLS.[JsonCode]),'$','$'+ISNULL(TPS.ActivityName,ChildTLS.ActivityStandardName)+'_'),'$'+ISNULL(TPS.ActivityName,ChildTLS.ActivityStandardName)+'_master_','$') END AS Code
				,TPS.[PipelineActivityId] AS PipelineActivityId
				,TPS.EmailNotificationEnabled
				,CASE WHEN TPS.[PipelineActivityId] IN (SELECT [ChildActivity] FROM [dbo].[T_Pipeline_Activities]) THEN 'Yes' ELSE 'No' END AS IsChildActivity
		FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipeline_Activities] TPS on TP.[PipelineId] = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.[ActivityId] = TPS.[ActivityID]
		LEFT JOIN [dbo].[T_List_Activities] ChildTLS on ChildTLS.[ActivityId] = TPS.[ChildActivity]
		WHERE TP.[PipelineId] = @PipelineId AND CASE WHEN TPS.[PipelineActivityId] IN (SELECT [ChildActivity] FROM [dbo].[T_Pipeline_Activities]) THEN 'Yes' ELSE 'No' END ='Yes'
) B ON A.[ChildActivity] = B.PipelineActivityId
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
and ps.[PipelineActivityId] not in (select  [ChildActivity] from [T_Pipeline_Activities] where PipelineId = @PipelineID)
AND ps1.Activityname like '%SPPipelineFailedActivity%'
AND P.PipelineId = @PipelineID

SELECT ActivityJsoncode FROM @activity_code
GO


