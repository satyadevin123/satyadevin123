
CREATE procedure [dbo].[usp_Insert_Pipeline_LinkedServiceParameters]
(@LinkedServiceId INT,@PipelineId INT,@IRName VARCHAR(200) = '')
AS
BEGIN

declare @LinkedServiceName VARCHAR(200)
declare @LinkedServiceParamName VARCHAR(200)
declare @LinkedServiceType VARCHAR(200)
declare @Keyvaultname VARCHAR(200)
declare @Keyvaultparamname VARCHAR(200)


insert into [dbo].[T_Pipeline_LinkedService_Parameters]
select  REPLACE(tllp.ParameterName,'$','$'+CAST(tpl.[PipelineLinkedServicesID] AS nvarchar)+'_') AS parameterName
,  tllp.parametervalue as ParameterValue, TPl.[PipelineLinkedServicesID], TP.[PipelineId]
FROM [dbo].[T_Pipelines] TP
JOIN dbo.T_Pipeline_LinkedServices tpl
ON tp.[PipelineId] = tpl.PipelineId
INNER JOIN dbo.T_List_LinkedServices tll
ON tpl.LinkedServiceId = tll.[LinkedServiceId]
INNER JOIN dbo.T_List_LinkedService_Parameters tllp
ON tllp.LinkedServiceId = tll.[LinkedServiceId]
WHERE TP.[PipelineId] = @PipelineId AND TPL.[PipelineLinkedServicesID] = @LinkedServiceId


SELECT @LinkedServiceType = tll.[LinkedServiceName]
FROM T_Pipeline_LinkedServices tpl JOIN T_List_LinkedServices tll
ON tpl.LinkedServiceId = tll.[LinkedServiceId]
WHERE tpl.[PipelineLinkedServicesID] = @LinkedServiceId

select @LinkedServiceType

SET @LinkedServiceName = '"LS_POC_'+@LinkedServiceType+'_'+CAST(@LinkedServiceId AS NVARCHAR(10)) +'"'
SET @LinkedServiceParamName = '$'+CAST(@LinkedServiceId AS NVARCHAR(10)) +'_'+@LinkedServiceType+'LinkedServiceName'
   
   SELECT @LinkedServiceParamName

UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = @LinkedServiceName
WHERE ParameterName = @LinkedServiceParamName 
AND LinkedServerId = @LinkedServiceId AND PipelineId = @PipelineId


UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = @IRName WHERE ParameterName like '%nameofintegrationruntime%' 
AND LinkedServerId = @LinkedServiceId AND PipelineId = @PipelineId

IF(@LinkedServiceType = 'azurekeyvault')
BEGIN
	
	SET @Keyvaultparamname = '$'+CAST(@LinkedServiceId AS NVARCHAR(10)) +'_keyvaultname'

	SELECT @Keyvaultname = ParameterValue FROM T_Master_Parameters_List WHERE ParameterName = '$keyvaultname'
	EXEC usp_UpdateLinkedServiceParameters @Keyvaultparamname,@Keyvaultname,@PipelineId,@LinkedServiceId
 

END

   

END
GO


