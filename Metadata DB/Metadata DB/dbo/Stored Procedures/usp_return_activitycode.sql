CREATE procedure [dbo].[usp_return_activitycode] 
@PipelineID Int
as

declare @pipelinename nvarchar(100)

select @pipelinename = PipelineName
from T_Pipelines where [PipelineId] = @PipelineID

DECLARE @activity_code TABLE (ID INT IDENTITY(1,1),ActivityJsoncode NVARCHAR(MAX),PipelineActivityId INT)
INSERT INTO @activity_code
SELECT 
CASE WHEN RowNumber >1 THEN ','+ Replace(Code,' ','')
ELSE Replace(Code,' ','') END

		,PipelineActivityId 
FROM
(
SELECT 
 ROW_NUMBER() OVER(ORDER BY TPS.[PipelineActivityId]) AS RowNumber
				,
CASE WHEN X.ParentActivity IS NULL THEN
REPLACE(REPLACE(TLS.[JsonCode],'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_'),'$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_master_','$') 
ELSE
REPLACE( 
REPLACE(REPLACE(TLS.[JsonCode],'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_'),'$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_master_','$') 
,'$'+TPS.ActivityName+'_'+'activityJsoncode',X.AfterCode)
END AS Code,
PipelineActivityId

				--,ISNULL(TPS.ActivityName,TLS.ActivityStandardName) AS ActivityName
				--,tls.ActivityName As ListActivityName
				--,tps.ParentActivity
	FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipeline_Activities] TPS on TP.[PipelineId] = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.[ActivityId] = TPS.[ActivityID]
		LEFT JOIN
		(
SELECT
STRING_AGG(
CASE WHEN ListActivityName ='IFCondition' THEN
REPLACE(REPLACE(Code,'$'+ActivityName+'_'+'ifTrueActivityCode',code1),'$'+ActivityName+'_'+'ifFalseActivityCode',code2) 
ELSE Code
END ,','
)AS AfterCode
,
ParentActivity
FROM
(
SELECT 
REPLACE(REPLACE(TLS.[JsonCode],'$','$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_'),'$'+ISNULL(TPS.ActivityName,TLS.ActivityStandardName)+'_master_','$') AS Code
				,ISNULL(TPS.ActivityName,TLS.ActivityStandardName) AS ActivityName
				,code1
				,code2
				,tls.ActivityName As ListActivityName
				,tps.ParentActivity
	FROM [dbo].[T_Pipelines] TP
		JOIN [dbo].[T_Pipeline_Activities] TPS on TP.[PipelineId] = TPS.PipelineiD
		JOIN [dbo].[T_List_Activities] TLS on TLS.[ActivityId] = TPS.[ActivityID]
		CROSS APPLY (select dbo.usp_return_childcode(TPS.pipelineactivityid, TPS.IfActivity)) t(code1)
		CROSS APPLY (select dbo.usp_return_childcode(TPS.pipelineactivityid, TPS.ElseActivity)) t1(code2)
		WHERE TP.[PipelineId] = @PipelineID
) as a 
where ParentActivity is not null
group by ParentActivity

) AS X
ON X.ParentActivity = TPS.PipelineActivityId
WHERE TP.[PipelineId] = @PipelineID
AND TPS.ParentActivity IS NULL
AND TPS.PipelineActivityId
NOT IN
(
SELECT t1.value FROM T_Pipeline_Activities t
CROSS APPLY
(
SELECT value from string_split(t.IfActivity,',')
UNION ALL
SELECT value from string_split(t.ElseActivity,',')
) as t1
))
as tt

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


