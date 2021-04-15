
CREATE PROCEDURE usp_UpdateLinkedServiceParameters
(
	@ParameterName nvarchar(300)
	,@ParameterValue VARCHAR(MAX)
	, @LinkedServiceId INT
)
AS
BEGIN
	UPDATE
			[dbo].[T_Pipeline_LinkedService_Parameters]
	SET		ParameterValue = @ParameterValue 
	WHERE	LinkedServerId = @LinkedServiceId
			AND  ParameterName = @ParameterName
END
