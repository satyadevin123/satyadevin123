﻿
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

DELETE FROM T_Pipeline_LinkedService_Parameters WHERE LinkedServerId = @LinkedServiceId

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

declare @tenantid varchar(255)

SELECT @tenantid = ParameterValue
FROM T_Master_Parameters_List
WHERE ParameterName = '$tenantid'

UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = @tenantid WHERE ParameterName like '%tenantid%' 
AND LinkedServerId = @LinkedServiceId 

declare @KeyVaultLinkedServiceName VARCHAR(200)

declare @kvlinkedserviceparamname VARCHAR(200) 

SELECT TOP 1  @KeyVaultLinkedServiceName = TPLP.ParameterValue
FROM T_Pipeline_LinkedServices TPL
INNER JOIN T_List_LinkedServices TLL
ON TPL.LinkedServiceId = TLL.LinkedServiceId
INNER JOIN T_Pipeline_LinkedService_Parameters TPLP
ON TPLP.LinkedServerId = TPL.PipelineLinkedServicesID
WHERE TLL.LinkedServiceName = 'azureKeyVault'
AND TPLP.ParameterName like '%LinkedServiceName%'

set @kvlinkedserviceparamname = '$'+CAST(@LinkedServiceId  AS  VARCHAR)+'_'+'azurekeyvaultlinkedservicereference'


UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = @KeyVaultLinkedServiceName 
WHERE LinkedServerId = @LinkedServiceId
AND  ParameterName = @kvlinkedserviceparamname


   

END
GO


