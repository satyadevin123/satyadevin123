CREATE PROCEDURE [dbo].[usp_InsertPipelineActivityParameters]
(@PipelineId INT)

AS

    DECLARE @LkpActName VARCHAR(55)
    DECLARE @ForeachActName NVARCHAR(300) 
    DECLARE @CPActName NVARCHAR(300)
    DECLARE @MetaLS VARCHAR(260)


    SET @LkpActName = 'LKP_'+CAST(@PipelineId AS VARCHAR)
    SET @CPActName = 'CP_'+CAST(@PipelineId AS VARCHAR)
    SET @ForeachActName = 'Foreach_SourceEntity_'+CAST(@PipelineId AS VARCHAR)

--Truncate table [T_Pipeline_Activity_Parameters]

    INSERT INTO [dbo].[T_Pipeline_Activity_Parameters]

    SELECT 
            '$'+ISNULL(TPS.ActivityName,TLA.ActivityStandardName)+'_'+ParameterName
            ,CASE    WHEN ParameterName = 'dependentActivityName' 
                        THEN CASE WHEN DEPTLA.ActivityName IS NULL THEN '' ELSE DEPTLA.ActivityName END
                    WHEN ParameterName LIKE '%ActivityName%' 
                        THEN CASE WHEN TPS.ActivityName IS NULL THEN TLA.Activitystandardname ELSE TPS.ActivityName END
                    WHEN ParameterName = 'dependson' 
                        THEN CASE WHEN DEPTLA.ActivityName IS NULL THEN '' ELSE DEPTLA.ActivityName END
                    WHEN ParameterName = 'dependencyConditions' 
                        THEN TPS.DependencyCondition
                    WHEN ParameterName LIKE '%SPParameters%' AND tla.ActivityName = 'Custom Logging' AND TPS.ActivityName LIKE '%InProgress%' 
                        THEN REPLACE(ParameterValue,'$pipelinestatus','InProgress') 
                    WHEN ParameterName LIKE '%SPParameters%' AND tla.ActivityName = 'Custom Logging' AND TPS.ActivityName LIKE '%Succeeded%' 
                        THEN REPLACE(ParameterValue,'$pipelinestatus','Succeeded')
                    WHEN ParameterName LIKE '%SPParameters%' AND tla.ActivityName = 'Custom Logging' AND TPS.ActivityName like '%Failed%' 
                        THEN 
                                REPLACE(ParameterValue,'$pipelinestatus','Failed') + 
                                   ',                           ""In_ErrorMessage"": {                             
                                   ""value"": ""@activity('''+DEPTLA.ActivityName +''').Error.Message"",            
                                   ""type"": ""string""                          }   '
                    ELSE ParameterValue
            END AS ParameterValue
            ,TPS.[PipelineActivityId]
            ,TP.[PipelineId]
    FROM    [dbo].[T_Pipelines] TP
            JOIN [dbo].[T_Pipeline_Activities] TPS ON TPS.[PipelineId] = TP.[PipelineId]
            JOIN [dbo].[T_List_Activities] TLA ON TLA.[ActivityId] = TPS.[ActivityID]
            JOIN [dbo].[T_List_Activity_Parameters] TLAP ON TLAP.[ActivityId] = TLA.[ActivityId]
            LEFT JOIN [dbo].[T_Pipeline_Activities] DEPTLA ON TPS.DependsOn= DEPTLA.[PipelineActivityId]
    WHERE 
            TPS.PipelineId = @PipelineId

    SELECT  @MetaLS = 'LS_'+LinkedServiceName
    FROM    dbo.T_Pipeline_LinkedServices
    WHERE   LinkedServiceName like '%metadata%'

    UPDATE  dbo.[T_Pipeline_Activity_Parameters]
    SET     ParameterValue = @MetaLS
    WHERE   ParameterName LIKE '%MetadataDBLinkedServiceName%' AND [PipelineId] = @PipelineId

GO


