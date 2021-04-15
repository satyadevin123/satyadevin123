
CREATE PROCEDURE [dbo].[usp_GetKeyVaultReferedParameters]
( @PipelineLinkedServiceId INT)
AS 
BEGIN

	SELECT	TLLP.ParameterName,
			TLLP.KeyVaultReferenceDescription
	FROM	T_Pipeline_LinkedServices TPL
			INNER JOIN T_List_LinkedServices TLL
			ON TPL.LinkedServiceId = TLL.LinkedServiceId
			INNER JOIN T_List_LinkedService_Parameters TLLP
			ON TLLP.LinkedServiceId = TLL.LinkedServiceId
	WHERE	TPL.PipelineLinkedServicesID = @PipelineLinkedServiceId
			AND TLLP.ReferFromKeyVault = 1


END
GO


