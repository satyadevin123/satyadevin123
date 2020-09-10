
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
                "name": "Execute Send Mail for lkp'+CAST(PS.[PipelineActivityId] AS nvarchar)+'",
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


--INSERT INTO @activity_code SELECT ', {
--                "name": "Execute Send Mail for '+ISNULL(CPS.Activityname,LS.ActivityStandardName)+'",
--                "type": "ExecutePipeline",
--                "dependsOn": [
--                    {
--                        "activity": "'+ISNULL(CPS.Activityname,LS.ActivityStandardName)+'",
--                        "dependencyConditions": [
--                            "'+'Failed'+'"
--                        ]
--                    }
--                ],
--                "userProperties": [],
--                "typeProperties": {
--                    "pipeline": {
--                        "referenceName": "Sendmail",
--                        "type": "PipelineReference"
--                    },
--                    "waitOnCompletion": true,
--                    "parameters": {'+''+'}
--                }
--            }
--        ',NULL FROM [dbo].[T_Pipelines] P
--INNER JOIN [dbo].[T_Pipelines_Steps] PS ON P.Id = PS.PipelineiD
--INNER JOIN [dbo].[T_Pipelines_Steps] CPS ON CPS.ID= PS.Child_Activity
--INNER JOIN [dbo].[T_List_Activities] LS ON LS.ID = PS.Child_Activity
--WHERE PS.EmailNotificationEnabled=1


SELECT ActivityJsoncode FROM @activity_code


--SELECT 
--				 ROW_NUMBER() OVER(ORDER BY TPS.ID) AS RowNumber
--				,CASE WHEN TPS.Child_Activity IS NULL OR TPS.Child_Activity='' THEN REPLACE(TLS.Code,'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_') 
--					  WHEN TPS.Child_Activity IS NOT NULL THEN REPLACE(REPLACE(TLS.Code,'$activityjsoncode',ChildTLS.Code),'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_') END AS Code
--				,TPS.id AS PipelineActivityId
--				,TPS.EmailNotificationEnabled
--				,TPS.Child_Activity
--				,CASE WHEN TPS.ID IN (SELECT Child_Activity FROM [dbo].[T_Pipelines_Steps]) THEN 'Yes' ELSE 'No' END AS IsChildActivity
--				,TPS.ActivityName
--		FROM [dbo].[T_Pipelines] TP
--		JOIN [dbo].[T_Pipelines_Steps] TPS on TP.Id = TPS.PipelineiD
--		JOIN [dbo].[T_List_Activities] TLS on TLS.ID = TPS.Activity_ID
--		LEFT JOIN [dbo].[T_List_Activities] ChildTLS on ChildTLS.ID = TPS.Child_Activity
--		WHERE TP.ID = 1


--		select * from [T_Pipelines_Steps]
--		update [T_Pipelines_Steps] set Activityname='foreachAzureSQLDBtable' where ID =2

--		insert into [T_Pipelines_Steps] select 3,1, 3,0,0,1,'CP_AzureSQL_ADLS_Parquet'
--		DECLARE @LevelTable TABLE (Code VARCHAR(MAX),PipelineActivityId INT,EmailNotificationEnabled INT,Child_Activity INT, ActivityName VARCHAR(500),Level INT)

--		;WITH CTE AS 
--		(
			
--		SELECT 
				 
--				 TLS.Code
--				,TPS.id AS PipelineActivityId
--				,TPS.EmailNotificationEnabled
--				,TPS.Child_Activity
--				,TPS.ActivityName
--				,0 AS Level
--		FROM [dbo].[T_Pipelines] TP
--		JOIN [dbo].[T_Pipelines_Steps] TPS on TP.Id = TPS.PipelineiD
--		JOIN [dbo].[T_List_Activities] TLS on TLS.ID = TPS.Activity_ID
--		WHERE TP.ID = 1 AND TPS.Child_Activity IS NULL OR TPS.Child_Activity=''
--		UNION ALL
--		SELECT 
				
--				 TLS.Code
--				,TPS.id AS PipelineActivityId
--				,TPS.EmailNotificationEnabled
--				,TPS.Child_Activity
--				,TPS.ActivityName
--				,Level+1 AS Level
			
--		FROM CTE C
--		JOIN [dbo].[T_Pipelines_Steps] TPS on TPS.Child_Activity = C.PipelineActivityId
--		JOIN  [dbo].[T_List_Activities] TLS on TLS.ID = TPS.Activity_ID
			
--		)
--	INSERT INTO @LevelTable
--	SELECT * FROM CTE

--	SELECT * FROM @LevelTable
GO


