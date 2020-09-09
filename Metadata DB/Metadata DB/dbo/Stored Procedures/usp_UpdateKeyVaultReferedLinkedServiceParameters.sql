
CREATE PROCEDURE [dbo].[usp_UpdateKeyVaultReferedLinkedServiceParameters]
( @PipelineLinkedServiceId INT,@KeyVaultSecretName VARCHAR(200))
AS 
BEGIN
declare @kvlinkedserviceparamname VARCHAR(200) 
declare @kvreferedparamname VARCHAR(200) 
declare @KeyVaultLinkedServiceName VARCHAR(200)

set @kvlinkedserviceparamname = '$'+CAST(@PipelineLinkedServiceId  AS  VARCHAR)+'_'+'azurekeyvaultlinkedservicereference'


SELECT TOP 1  @KeyVaultLinkedServiceName = TPLP.ParameterValue
FROM T_Pipeline_LinkedServices TPL
INNER JOIN T_List_LinkedServices TLL
ON TPL.LinkedServiceId = TLL.LinkedServiceId
INNER JOIN T_Pipeline_LinkedService_Parameters TPLP
ON TPLP.LinkedServerId = TPL.PipelineLinkedServicesID
WHERE TLL.LinkedServiceName = 'azureKeyVault'
AND TPLP.ParameterName like '%LinkedServiceName%'


SELECT TOP 1  @kvreferedparamname = TLLP.ParameterName
FROM T_Pipeline_LinkedServices TPL
INNER JOIN T_List_LinkedServices TLL
ON TPL.LinkedServiceId = TLL.LinkedServiceId
INNER JOIN T_List_LinkedService_Parameters TLLP
ON TLLP.LinkedServiceId = TLL.LinkedServiceId
WHERE TPL.PipelineLinkedServicesID = @PipelineLinkedServiceId
AND TLLP.ReferFromKeyVault = 1

SET @kvreferedparamname = '$'+ CAST(@PipelineLinkedServiceId  AS  VARCHAR) +'_'+ REPLACE(@kvreferedparamname,'$','')

UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = @KeyVaultLinkedServiceName 
WHERE LinkedServerId = @PipelineLinkedServiceId
AND  ParameterName = @kvlinkedserviceparamname

UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = @KeyVaultSecretName 
WHERE LinkedServerId = @PipelineLinkedServiceId
AND  ParameterName = @kvreferedparamname


END
GO


