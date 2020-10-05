
CREATE PROCEDURE dbo.usp_TruncateParameterTables
(@PipelineName VARCHAR(200))
AS
BEGIN

DECLARE @PipelineId INT

SELECT @PipelineId = PipelineId FROM T_Pipelines WHERE PipelineName = @PipelineName

DELETE FROM dbo.t_pipeline_dataset_parameters WHERE PipelineId = @PipelineId
DELETE FROM dbo.t_pipeline_activity_parameters WHERE PipelineId = @PipelineId
DELETE FROM dbo.[T_Pipeline_Activities] WHERE PipelineId = @PipelineId
--DELETE FROM dbo.T_Pipeline_DataSets WHERE PipelineId = @PipelineId
Delete from T_Pipeline_SourceColumnDetails
where PipelineSourceId in (select PipelineSourceId from [T_Pipeline_Tables_ToBeMoved] where pipelineid = @PipelineId )

DELETE FROM dbo.[T_Pipeline_Tables_ToBeMoved] WHERE PipelineId = @PipelineId

END