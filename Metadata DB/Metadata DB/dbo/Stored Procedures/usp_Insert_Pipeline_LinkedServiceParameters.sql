
CREATE procedure [dbo].[usp_Insert_Pipeline_LinkedServiceParameters]
(@LinkedServiceName VARCHAR(200),@IRName VARCHAR(200) = '')
AS
BEGIN

declare @LinkedServiceId INT
declare @LinkedServiceParamName VARCHAR(200)
declare @LinkedServiceType VARCHAR(200)
declare @Keyvaultname VARCHAR(200)
declare @Keyvaultparamname VARCHAR(200)

SELECT @LinkedServiceId = TPL.PipelineLinkedServicesID
FROM T_Pipeline_LinkedServices TPL
WHERE LinkedServiceName = @LinkedServiceName

insert into [dbo].[T_Pipeline_LinkedService_Parameters]
select  REPLACE(tllp.ParameterName,'$','$'+CAST(tpl.[PipelineLinkedServicesID] AS nvarchar)+'_') AS parameterName
,  tllp.parametervalue as ParameterValue, TPl.[PipelineLinkedServicesID]
FROM dbo.T_Pipeline_LinkedServices tpl
INNER JOIN dbo.T_List_LinkedServices tll
ON tpl.LinkedServiceId = tll.[LinkedServiceId]
INNER JOIN dbo.T_List_LinkedService_Parameters tllp
ON tllp.LinkedServiceId = tll.[LinkedServiceId]
WHERE  TPL.LinkedServiceName = @LinkedServiceName


--SELECT @LinkedServiceType = tll.[LinkedServiceName]
--FROM T_Pipeline_LinkedServices tpl JOIN T_List_LinkedServices tll
--ON tpl.LinkedServiceId = tll.[LinkedServiceId]
--WHERE tpl.[PipelineLinkedServicesID] = @LinkedServiceId

select @LinkedServiceType

SET @LinkedServiceName = '"LS_'+ @LinkedServiceName +'"'

UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = @LinkedServiceName
WHERE ParameterName LIKE '%LinkedServiceName%' 
AND LinkedServerId = @LinkedServiceId 

UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = @IRName WHERE ParameterName like '%nameofintegrationruntime%' 
AND LinkedServerId = @LinkedServiceId 

--IF(@LinkedServiceType = 'azurekeyvault')
--BEGIN
	
--	SET @Keyvaultparamname = '$'+CAST(@LinkedServiceId AS NVARCHAR(10)) +'_keyvaultname'

--	SELECT @Keyvaultname = ParameterValue FROM T_Master_Parameters_List WHERE ParameterName = '$keyvaultname'
--	EXEC usp_UpdateLinkedServiceParameters @Keyvaultparamname,@Keyvaultname,@PipelineId,@LinkedServiceId
 

--END

   

END
GO


