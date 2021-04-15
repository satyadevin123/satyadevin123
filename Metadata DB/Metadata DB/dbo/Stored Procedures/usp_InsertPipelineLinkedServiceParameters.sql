CREATE procedure [dbo].[usp_InsertPipelineLinkedServiceParameters]
(
	@LinkedServiceName VARCHAR(140)
	,@IRName VARCHAR(63) = ''
)
AS
BEGIN

	DECLARE @LinkedServiceId INT
	DECLARE @LinkedServiceParamName VARCHAR(200)
	DECLARE @LinkedServiceType VARCHAR(140)
	DECLARE @Keyvaultname VARCHAR(24)
	DECLARE @Keyvaultparamname VARCHAR(200)
	DECLARE @tenantid VARCHAR(255)
	DECLARE @KeyVaultLinkedServiceName VARCHAR(140)
	DECLARE @kvlinkedserviceparamname VARCHAR(200) 

	SET @kvlinkedserviceparamname = '$'+CAST(@LinkedServiceId  AS  VARCHAR)+'_'+'azurekeyvaultlinkedservicereference'
	
	SELECT 
			@LinkedServiceId = TPL.PipelineLinkedServicesID
	FROM	dbo.T_Pipeline_LinkedServices TPL
	WHERE	LinkedServiceName = @LinkedServiceName

	DELETE	FROM 
			T_Pipeline_LinkedService_Parameters 
	WHERE	LinkedServerId = @LinkedServiceId

	INSERT	INTO [dbo].[T_Pipeline_LinkedService_Parameters]
	SELECT  
			REPLACE(tllp.ParameterName,'$','$'+CAST(tpl.[PipelineLinkedServicesID] AS nvarchar)+'_') AS parameterName
			,tllp.parametervalue as ParameterValue
			,TPl.[PipelineLinkedServicesID]
	FROM	
			dbo.T_Pipeline_LinkedServices tpl
			INNER JOIN dbo.T_List_LinkedServices tll
			ON tpl.LinkedServiceId = tll.[LinkedServiceId]
			INNER JOIN dbo.T_List_LinkedService_Parameters tllp
			ON tllp.LinkedServiceId = tll.[LinkedServiceId]
	WHERE	
			TPL.LinkedServiceName = @LinkedServiceName

	SET @LinkedServiceName = '"LS_'+ @LinkedServiceName +'"'

	UPDATE 
			T_Pipeline_LinkedService_Parameters 
	SET		ParameterValue = @LinkedServiceName
	WHERE	ParameterName LIKE '%LinkedServiceName%' 
			AND LinkedServerId = @LinkedServiceId 

	UPDATE 
			T_Pipeline_LinkedService_Parameters 
	SET		ParameterValue = @IRName 
	WHERE	ParameterName like '%nameofintegrationruntime%' 
			AND LinkedServerId = @LinkedServiceId 

	SELECT 
			@tenantid = ParameterValue
	FROM	
			dbo.T_Master_Parameters_List
	WHERE 
			ParameterName = '$tenantid'

	UPDATE	
			dbo.T_Pipeline_LinkedService_Parameters 
	SET		ParameterValue = @tenantid 
	WHERE	ParameterName like '%tenantid%' 
			AND LinkedServerId = @LinkedServiceId 


	SELECT 
			TOP 1  @KeyVaultLinkedServiceName = TPLP.ParameterValue
	FROM	dbo.T_Pipeline_LinkedServices TPL
			INNER JOIN T_List_LinkedServices TLL
			ON TPL.LinkedServiceId = TLL.LinkedServiceId
			INNER JOIN T_Pipeline_LinkedService_Parameters TPLP
			ON TPLP.LinkedServerId = TPL.PipelineLinkedServicesID
	WHERE	TLL.LinkedServiceName = 'azureKeyVault'
			AND TPLP.ParameterName like '%LinkedServiceName%'

	UPDATE 
			[dbo].[T_Pipeline_LinkedService_Parameters] 
	SET		ParameterValue = @KeyVaultLinkedServiceName 
	WHERE	LinkedServerId = @LinkedServiceId
			AND  ParameterName = @kvlinkedserviceparamname

END
GO


