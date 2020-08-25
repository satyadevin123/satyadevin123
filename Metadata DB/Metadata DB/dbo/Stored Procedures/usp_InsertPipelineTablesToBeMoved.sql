
CREATE PROCEDURE usp_InsertPipelineTablesToBeMoved
(@PipelineId INT, @TableName NVARCHAR(300), @SchemaName NVARCHAR(30), @LinkedServiceId INT)
AS
BEGIN
INSERT INTO dbo.t_pipeline_tables_tobemoved
(pipelineid,Table_Name,Schema_Name,linkedserviceid) 
VALUES (@PipelineId,@TableName ,@SchemaName,@LinkedServiceId)

END