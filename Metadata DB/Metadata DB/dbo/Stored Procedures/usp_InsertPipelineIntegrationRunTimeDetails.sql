﻿CREATE PROCEDURE [dbo].usp_InsertPipelineIntegrationRunTimeDetails
(
	@IRName VARCHAR(63)
	,@IRType VARCHAR(20)
)
AS
BEGIN

	DECLARE @AlreadyExists BIT

	SELECT	@AlreadyExists = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
	FROM	dbo.T_Pipeline_IntegrationRunTime
	WHERE	IntegrationRunTimeName = @IRName

	IF (@AlreadyExists = 0)
	BEGIN
	INSERT INTO dbo.T_Pipeline_IntegrationRunTime 
	(
		IntegrationRunTimeName
		,IntegrationRunTimeType
	) 
	VALUES
	(
		@IRName
		,@IRType
	)
	END
END
GO