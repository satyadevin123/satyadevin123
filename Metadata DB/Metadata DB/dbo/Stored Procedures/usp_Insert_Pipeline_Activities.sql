
CREATE procedure [dbo].[usp_Insert_Pipeline_Activities]  
as  
begin

Truncate table dbo.t_pipelines_steps


INSERT INTO dbo.t_pipelines_steps VALUES
(1,1,2,0,0,1,'LKP_AzureSQLDB'),
(2,1,4,1,3,1,'foreachAzureSQLDBtable'),
(3,1,3,0,0,1,'CP_AzureSQL_ADLS_Parquet')

end