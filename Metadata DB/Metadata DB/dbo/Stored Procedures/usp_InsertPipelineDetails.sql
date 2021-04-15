 CREATE PROCEDURE usp_InsertPipelineDetails
(
	@PipelineName VARCHAR(140)
)
AS
BEGIN

	DECLARE @AlreadyExists BIT

	SELECT 
			@AlreadyExists = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
	FROM	dbo.T_Pipelines 
	WHERE	PipelineName = @PipelineName

	IF	(@AlreadyExists = 0)
	BEGIN
		INSERT INTO dbo.T_Pipelines 
		(
		PipelineName
		,Enabled
		,EmailNotificationEnabled)
		VALUES
		(
		@PipelineName
		, 1
		, 1
		)
	END
	
END
