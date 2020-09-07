
CREATE PROCEDURE usp_InsertPipelineTablesToBeMoved
(@PipelineId INT, @TableName NVARCHAR(300), @SchemaName NVARCHAR(30), @LinkedServiceId INT)
AS
BEGIN
INSERT INTO dbo.[T_Pipeline_Tables_ToBeMoved]
(pipelineid,[TableName],[SchemaName],linkedserviceid) 
VALUES (@PipelineId,@TableName ,@SchemaName,@LinkedServiceId)

END