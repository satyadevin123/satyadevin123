
CREATE PROCEDURE usp_InsertPipelineTablesToBeMoved
(@PipelineId INT, @TableName NVARCHAR(300), @SchemaName NVARCHAR(30))
AS
BEGIN
INSERT INTO dbo.[T_Pipeline_Tables_ToBeMoved]
(pipelineid,[TableName],[SchemaName]) 
VALUES (@PipelineId,@TableName ,@SchemaName)

END