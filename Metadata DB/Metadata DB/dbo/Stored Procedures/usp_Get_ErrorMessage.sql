CREATE PROC [dbo].[usp_Get_ErrorMessage] @in_PipelineID [VARCHAR](250) AS
BEGIN
SELECT ErrorDescription From Audit.ExceptionLogDetails Where PipelineID=@in_PipelineID 
END