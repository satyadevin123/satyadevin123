

CREATE procedure [dbo].[usp_return_activitycode_bkup1] 
@PipelineID Int
as

declare @pipelinename nvarchar(100)

select @pipelinename = PipelineName
from T_Pipelines where id = @PipelineID

DECLARE @activity_code TABLE (ID INT IDENTITY(1,1),ActivityJsoncode VARCHAR(MAX),PipelineActivityId INT)
INSERT INTO @activity_code

SELECT 
		CASE WHEN A.RowNumber >1 THEN CASE WHEN ISNULL(A.Child_Activity,0)<>0 THEN ','+REPLACE(A.Code,'$'+ActivityName+'_'+'activityJsoncode',B.Code) ELSE ','+A.Code END 
		ELSE CASE WHEN ISNULL(A.Child_Activity,0)<>0 THEN REPLACE(A.Code,'$'+ActivityName+'_'+'activityJsoncode',B.Code) ELSE A.Code END END AS Code
		,A.PipelineActivityId 
		
FROM (
		SELECT 
				 ROW_NUMBER() OVER(ORDER BY TPS.ID) AS RowNumber
				,REPLACE(TLS.Code,'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_') AS Code
				,TPS.id AS PipelineActivityId
				,TPS.EmailNotificationEnabled
				,TPS.Child_Activity
				,CASE WHEN TPS.ID IN (SELECT Child_Activity FROM [dbo].[T_Pipelines_Steps]) THEN 'Yes' ELSE 'No' END AS IsChildActivity
				,ISNULL(TPS.ActivityName,TLS.ActivityStandardName) AS ActivityName
		FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipelines_Steps] TPS on TP.Id = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.ID = TPS.Activity_ID
		WHERE TP.ID = @PipelineId
) A
LEFT JOIN (
		SELECT 
				 ROW_NUMBER() OVER(ORDER BY TPS.ID) AS RowNumber
				,CASE WHEN TPS.Child_Activity IS NULL OR TPS.Child_Activity='' THEN REPLACE(TLS.Code,'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_') 
					  WHEN TPS.Child_Activity IS NOT NULL THEN REPLACE(REPLACE(TLS.Code,'$activityjsoncode',ChildTLS.Code),'$','$'+ISNULL(TPS.ActivityName,ChildTLS.ActivityStandardName)+'_') END AS Code
				,TPS.id AS PipelineActivityId
				,TPS.EmailNotificationEnabled
				,CASE WHEN TPS.ID IN (SELECT Child_Activity FROM [dbo].[T_Pipelines_Steps]) THEN 'Yes' ELSE 'No' END AS IsChildActivity
		FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipelines_Steps] TPS on TP.Id = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.ID = TPS.Activity_ID
		LEFT JOIN [dbo].[T_List_Activities] ChildTLS on ChildTLS.ID = TPS.Child_Activity
		WHERE TP.ID = @PipelineId AND CASE WHEN TPS.ID IN (SELECT Child_Activity FROM [dbo].[T_Pipelines_Steps]) THEN 'Yes' ELSE 'No' END ='Yes'
) B ON A.Child_Activity = B.PipelineActivityId
WHERE A.IsChildActivity='No'
Declare @configvalues varchar(8000)
select @configvalues=coalesce(@configvalues+ ',','')+'"'+ConfigName+'":"'+configvalue+'"' from [dbo].[T_ConfigurationDetails]

insert into @activity_code select ', {
                "name": "Execute Send Mail for '+ISNULL(REPLACE(LOWER(PS.Activityname),'_',''),LS.ActivityStandardName)+'",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "'+ISNULL(PS.Activityname,LS.ActivityStandardName)+'",
                        "dependencyConditions": [
                            "'+'Failed'+'"
                        ]
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
					"EmailTo": "satyadevi.nimmakayala@winwire.com",
                        "Activity": "'+ISNULL(REPLACE(LOWER(PS.Activityname),'_',''),LS.ActivityStandardName)+'",
                        "Message": "failed at activity '+ISNULL(REPLACE(LOWER(PS.Activityname),'_',''),LS.ActivityStandardName)+'"
				}
                }
            }
        ',
		
		NULL FROM [dbo].[T_Pipelines] P
INNER JOIN [dbo].[T_Pipelines_Steps] PS on P.Id = PS.PipelineiD
INNER JOIN [dbo].[T_List_Activities] LS on LS.ID = PS.Activity_ID
WHERE PS.EmailNotificationEnabled=1
and ps.id not in (select  Child_Activity from T_Pipelines_steps where PipelineId = @PipelineID)



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