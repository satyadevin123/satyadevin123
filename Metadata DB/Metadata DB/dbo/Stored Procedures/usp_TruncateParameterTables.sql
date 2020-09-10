
CREATE PROCEDURE dbo.usp_TruncateParameterTables
AS
BEGIN
truncate table dbo.t_pipeline_linkedservice_parameters
truncate table dbo.t_pipeline_dataset_parameters
truncate table dbo.t_pipeline_activity_parameters
truncate table dbo.[T_Pipeline_Activities]

DELETE FROM dbo.t_pipeline_datasets
truncate table dbo.t_pipeline_linkedservices
truncate table dbo.[T_Pipeline_Tables_ToBeMoved]
truncate table dbo.t_pipelineparameters
delete  from dbo.t_pipelines
END