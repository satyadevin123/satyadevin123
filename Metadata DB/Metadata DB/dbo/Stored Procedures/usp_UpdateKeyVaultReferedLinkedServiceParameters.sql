
CREATE PROCEDURE [dbo].[usp_UpdateKeyVaultReferedLinkedServiceParameters]
( @PipelineLinkedServiceId INT,@KeyVaultSecretName VARCHAR(200),@kvreferedparamname VARCHAR(255))
AS 
BEGIN

SET @kvreferedparamname = '$'+ CAST(@PipelineLinkedServiceId  AS  VARCHAR) +'_'+ REPLACE(@kvreferedparamname,'$','')

UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = @KeyVaultSecretName 
WHERE LinkedServerId = @PipelineLinkedServiceId
AND  ParameterName = @kvreferedparamname


END
GO


