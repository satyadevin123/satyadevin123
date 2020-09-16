
CREATE PROCEDURE [dbo].[usp_UpdateKeyVaultReferedLinkedServiceParameters]
( @PipelineLinkedServiceId INT,@KeyVaultSecretName VARCHAR(200))
AS 
BEGIN
declare @kvreferedparamname VARCHAR(200) 

SELECT TOP 1  @kvreferedparamname = TLLP.ParameterName
FROM T_Pipeline_LinkedServices TPL
INNER JOIN T_List_LinkedServices TLL
ON TPL.LinkedServiceId = TLL.LinkedServiceId
INNER JOIN T_List_LinkedService_Parameters TLLP
ON TLLP.LinkedServiceId = TLL.LinkedServiceId
WHERE TPL.PipelineLinkedServicesID = @PipelineLinkedServiceId
AND TLLP.ReferFromKeyVault = 1

SET @kvreferedparamname = '$'+ CAST(@PipelineLinkedServiceId  AS  VARCHAR) +'_'+ REPLACE(@kvreferedparamname,'$','')

UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = @KeyVaultSecretName 
WHERE LinkedServerId = @PipelineLinkedServiceId
AND  ParameterName = @kvreferedparamname


END
GO


