 CREATE PROCEDURE usp_InsertPipelineDetails
(@PipelineName nvarchar(300))
AS
BEGIN
	INSERT INTO dbo.T_Pipelines 
	(PipelineName, Enabled, EmailNotificationEnabled)
	VALUES
	(@PipelineName, 1, 1)
END
