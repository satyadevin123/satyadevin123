
CREATE procedure [dbo].[final_execution_ps_new] 
 (@PipelineId INT)
as


DECLARE @DSJsonCode NVARCHAR(max)
Declare @MasterPipelineActivityJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
Declare @DFCreationJsonCode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
Declare @KeyVaultJsonCode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))

insert into @DFCreationJsonCode select 'New-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName –Location $dataFactoryNameLocation -Force'
insert into @DFCreationJsonCode select 
'$sinkAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $SinkAccountName  -ErrorAction SilentlyContinue'
insert into @DFCreationJsonCode select  'if($sinkAccount -eq $null){
     New-AzStorageAccount -Kind StorageV2 -ResourceGroupName $resourceGroupName -Name $SinkAccountName -Location $dataFactoryNameLocation -EnableHierarchicalNamespace $true -SkuName Standard_LRS }'
insert into @DFCreationJsonCode select '$spID = (Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName).Identity.PrincipalId '
insert into @DFCreationJsonCode select 'New-AzRoleAssignment -ObjectId $spID -RoleDefinitionName "Storage Blob Data Contributor" -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$SinkAccountName" -ErrorAction SilentlyContinue'

Declare @IRCount int,@IRType varchar(200),@irname varchar(200)
set @IRCount =(SELECT count(*) from T_Pipeline_IntegrationRunTime  )
declare @IRid int

declare @tbl2 table
(rownum int, id int)

insert into @tbl2
select row_number() over(order by IntegrationRunTimeId ),IntegrationRunTimeId from dbo.T_Pipeline_IntegrationRunTime 

set @IRid = 1

while @IRid <=  @IRCount
begin
SELECT  @IRType = IntegrationRunTimeType, @irname = tpl.IntegrationRunTimeName 
from [dbo].T_Pipeline_IntegrationRunTime TPL 
JOIN @tbl2 t ON t.id = tpl.IntegrationRunTimeId
AND t.rownum =@IRid 

insert into @DFCreationJsonCode select 'Set-AzDataFactoryV2IntegrationRuntime -DataFactoryName $dataFactoryName -Name "'+ @irname + '" -ResourceGroupName $resourceGroupName -Type "'+@IRType +'" -Location $dataFactoryNameLocation -Force'

set @IRid=@IRid+1
End




insert into @KeyVaultJsonCode select 
'Set-AzKeyVaultAccessPolicy -VaultName $keyvaultname -ResourceGroupName $resourceGroupName -ObjectId $spID -PermissionsToKeys get -PermissionsToSecrets get'

declare @emailpipelinename nvarchar(100)

insert into @MasterPipelineActivityJsoncode select '$sendmailpipelineDefinition = @"'
insert into @MasterPipelineActivityJsoncode select Jsoncode From T_Master_Pipelines Where MasterPipelineName='Sendmail'
insert into @MasterPipelineActivityJsoncode select '"@'
insert into @MasterPipelineActivityJsoncode select '$sendmailpipelineDefinition | Out-File "$ScriptPath\OutputPipelineScripts\sendmail.json"'

insert into @MasterPipelineActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $sendmailMasterPipelineName -Force -File "$ScriptPath\OutputPipelineScripts\sendmail.json"'

Declare @pipelinename varchar(100)
set @pipelinename = (select PipelineName from [dbo].[T_Pipelines] where [PipelineId]=@PipelineId )

declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+[JsonCode] from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipeline_Activities] PS on P.[PipelineId] = PS.PipelineId
join [dbo].[T_List_Activities] LS on LS.[ActivityId] = PS.[ActivityID]
where p.Enabled=1 AND P.PipelineId = @PipelineId


declare @tbl table
(rownum int, id int)

Declare @LSCount int,@LinkedService varchar(200),@name varchar(200),@LSInit int
Declare @LinkedServiceJsoncode table(Jsoncode varchar(max), ID INT IDENTITY(1,1))
set @LSCount =(SELECT count(*) from T_Pipeline_LinkedServices  )
declare @lsid int
declare @dsid int

insert into @tbl
select row_number() over(order by [PipelineLinkedServicesID] ),[PipelineLinkedServicesID] from dbo.T_Pipeline_LinkedServices 

set @LSInit = 1

while @LSInit <=  @LSCount
begin
SELECT @LinkedService= tpl.[LinkedServiceName] , @name = ParameterValue, @lsid = tpl.[PipelineLinkedServicesID] from [dbo].[T_Pipeline_LinkedServices] TPL 
JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.[LinkedServiceId] = TPL.LinkedServiceID 
JOIN [T_Pipeline_LinkedService_Parameters] TPLP on TPLP.LinkedServerId =TPL.[PipelineLinkedServicesID]
JOIN @tbl t ON t.id = tpl.[PipelineLinkedServicesID]
where TPLP.ParameterName like '%linkedservicename%'
AND t.rownum =@LSInit 


insert into @LinkedServiceJsoncode select '$LS_'+@LinkedService+'Definition = @"'
insert into @LinkedServiceJsoncode select REPLACE(REPLACE(Jsoncode,'$','$'+CAST(TPL.[PipelineLinkedServicesID] AS nvarchar)+'_'),'$'+CAST(TPL.[PipelineLinkedServicesID] AS nvarchar)+'_master_','$') from [dbo].[T_Pipeline_LinkedServices] 
TPL JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.[LinkedServiceId] = TPL.LinkedServiceID where TPL.[PipelineLinkedServicesID]=@lsid
insert into @LinkedServiceJsoncode select '"@'
insert into @LinkedServiceJsoncode select '$LS_'+@LinkedService+'Definition | Out-File "$ScriptPath\OutputPipelineScripts\LS_'+@LinkedService+'.json"'
insert into @LinkedServiceJsoncode select  'New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name '+@name+' -File "$ScriptPath\OutputPipelineScripts\LS_'+@LinkedService+'.json"'

set @LSInit=@LSInit+1
End


Declare @DSCount int,@DataSet varchar(200)
Declare @DataSetJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
set @DSCount =(SELECT count(*) from [dbo].[T_Pipeline_DataSets] Where PipeLineId =@PipelineId )


declare @tbl1 table
(rownum int, id int)

insert into @tbl1
select row_number() over(order by [PipelineDataSetId]),[PipelineDataSetId] from dbo.[T_Pipeline_DataSets] where PipelineId = @PipelineId

while @DSCount >0
begin

SELECT @DataSet= 'DS_'+TLD.[DataSetName]+'_'+CAST(@PipelineId AS VARCHAR)+'_'+ CAST(TPD.DataSetId AS VARCHAR), @name = ParameterValue,@DSJsonCode=Jsoncode,@dsid=TPD.[PipelineDataSetId] from [dbo].[T_Pipeline_DataSets] TPD
JOIN [dbo].[T_List_DataSets] TLD ON TLD.[DatasetId] = TPD.DataSetId 
JOIN [T_Pipeline_DataSet_Parameters] TPDP on TPDP.[PipelineDataSetId] =TPD.[PipelineDataSetId]
JOIN @tbl1 t ON t.Id = TPD.[PipelineDataSetId]
where TPDP.ParameterName like '%datasetname%'
AND t.rownum =@DSCount AND tpdp.PipelineId = @PipelineId

--set @Dataset= (select DataSet_Name from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.id where TPD.id =@DSCount)

insert into @DataSetJsoncode select '$'+@DataSet+'Definition = @"'
insert into @DataSetJsoncode select REPLACE(REPLACE(TLD.Jsoncode,'$','$'+CAST(TPD.PipelineDataSetId AS nvarchar)+'_'+CAST(@PipelineId AS nvarchar)+'_'),'$'+CAST(TPD.PipelineDataSetId AS nvarchar)+'_'+CAST(@PipelineId AS nvarchar)+'_master_','$') from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.[DatasetId] JOIN T_Pipeline_LinkedServices TPL ON TPL.[PipelineLinkedServicesID] = TPD.LinkedServericeId JOIN T_List_LinkedServices TLL ON TLL.[LinkedServiceId] = TPL.LinkedServiceId where TPD.[PipelineDataSetId]=@dsid 
insert into @DataSetJsoncode select '"@'
insert into @DataSetJsoncode select '$'+@DataSet+'Definition | Out-File "$ScriptPath\OutputPipelineScripts\'+@DataSet+'.json"'
insert into @DataSetJsoncode select  'New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "'+@name+'" -File "$ScriptPath\OutputPipelineScripts\'+@DataSet+'.json"'

set @DSCount=@DSCount-1
End


Declare @ActivityJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
insert into @ActivityJsoncode select '$pipelineDefinition = @"'
insert into @ActivityJsoncode select '{'
insert into @ActivityJsoncode select '"name": "$pipelinename",'
insert into @ActivityJsoncode select '"properties": {'
insert into @ActivityJsoncode select         '"activities": ['
insert into @ActivityJsoncode Exec [dbo].[usp_return_activitycode] @PipelineId 
insert into @ActivityJsoncode select ']'
insert into @ActivityJsoncode select     '}'
insert into @ActivityJsoncode select 	'}'
insert into @ActivityJsoncode select '"@'
insert into @ActivityJsoncode select '$pipelineDefinition | Out-File "$ScriptPath\OutputPipelineScripts\'+@pipelinename+'.json"'

insert into @ActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name $pipelinename -File "$ScriptPath\OutputPipelineScripts\$pipelinename.json"'





--select 'Decalre '+ParameterName from [dbo].[T_DataSet_Parameters]

--select 'SET '+ ParameterName+' = '+ ParameterValue from [dbo].[T_DataSet_Parameters]



--select * from @DataSetJsoncode
IF (Select MAX(EmailNotificationEnabled) From [T_Pipeline_Activities]) =1
SELECT Parameter
FROM (
		select '$pipelinename = "'+ @pipelinename +'"' AS Parameter,0 AS ID, 'MasterParameterList' AS DescType 
	    union all
		Select '#Variables for master parameters',0,'MasterParameterList'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[MasterParameterId], 'MasterParameterList' AS DescType from T_Master_Parameters_List
		union all
		Select '#Variables for Linked Service Parameters',0,'LinkedServiceParameterList'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[PipelineLinkedServicesParameterID], 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters] 
		union all
		Select '#Variables for Dataset Parameters',0,'DatasetParameterList'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,[PipelineDatasetParameterId], 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_DataSet_Parameters]  WHERE PipelineId = @PipelineId
		union all
		Select '#Variables for pipeline Activity Parameters',0,'ActivityParameterList'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,[PipelineActivityParameterId], 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'  AND PipelineId = @PipelineId
		union all
		Select '#Variables for master pipeline paramters i.e sendmail',0,'MasterPipelineParameterList'
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,[MasterParameterPipelineId], 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List
		union all
		Select '#Code for creating/updating data factory',0,'DFCode'
		union all
		select Jsoncode AS Parameter,ID, 'DFCode' AS DescType from @DFCreationJsonCode 
		union all
		Select '#Code for creating/updating key vault',0,'KVCode'
		union all
		select Jsoncode AS Parameter,ID, 'KVCode' AS DescType from @KeyVaultJsonCode
		union all
		Select '#Code for creating/updating linked services',0,'LSCode'
		union all
		select Jsoncode AS Parameter,ID, 'LSCode' AS DescType from @LinkedServiceJsoncode 
		union all
		Select '#Code for creating/updating pipeline datasets',0,'DSCode'
		union all
		select Jsoncode AS Parameter, ID, 'DSCode' AS DescType from @DataSetJsoncode 
		union all
		Select '#Code for creating/updating master pipeline code i.e sendmail',0,'Mastercode'
		union all
		select Jsoncode AS Parameter, ID, 'Mastercode' AS DescTyp from @MasterPipelineActivityJsoncode
		Union all
		Select '#Code for creating/updating master pipeline activity code',0,'ActivityCode'
		union all
		select Jsoncode AS Parameter, ID, 'ActivityCode' AS DescType from @ActivityJsoncode
) A
ORDER BY CASE WHEN DescType Like '%MasterParameterList%' THEN 1 
			  WHEN DescType Like '%LinkedServiceParameterList%' THEN 2 
			  WHEN DescType Like '%DatasetParameterList%' THEN 3
			  WHEN DescType Like '%ActivityParameterList%' THEN 4
			  WHEN DescType Like '%MasterPipelineParameterList%' THEN 5
			  WHEN DescType Like '%DFCode%' THEN 6
			  WHEN DescType Like '%KVCode%' THEN 7
			  WHEN DescType Like '%LSCode%' THEN 8
			  WHEN DescType Like '%DSCode%' THEN 9 
			  WHEN DescType Like '%Mastercode%' THEN 10
			  WHEN DescType Like '%ActivityCode%' THEN 11 END 
			  ,ID




ELSE
SELECT Parameter
FROM (  
       select '$pipelinename = "'+ @pipelinename +'"' AS Parameter,0 AS ID, 'MasterParameterList' AS DescType 
	   union all
	    Select '#Variables for master parameters',0,'MasterParameterList'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[MasterParameterId], 'MasterParameterList' AS DescType from T_Master_Parameters_List
		union all
		Select '#Variables for linked service parameters',0,'LinkedServiceParameterList'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[PipelineLinkedServicesParameterID], 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters]  
		union all
		Select '#Variables for dataset parameters',0,'DatasetParameterList'
		union all
		select ParameterName+' = "'+ ParameterValue +'"' AS Parameter,[PipelineDatasetParameterId], 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_DataSet_Parameters] WHERE PipelineId = @PipelineId
		union all
		Select '#Variables for pipeline activity parameters',0,'ActivityParameterList'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,[PipelineActivityParameterId], 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'  AND PipelineId = @PipelineId
		union all
		Select '#Variables for master pipeline parameters',0,'MasterPipelineParameterList'
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,[MasterParameterPipelineId], 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List 
		union all
		Select '#Code for creating/updating data factory',0,'DFCode'
		union all
		select Jsoncode AS Parameter,ID, 'DFCode' AS DescType from @DFCreationJsonCode 
		union all
		Select '#Code for creating/updating key vault',0,'KVCode'
		union all
		select Jsoncode AS Parameter,ID, 'KVCode' AS DescType from @KeyVaultJsonCode
		union all
		Select '#Code for creating/updating linked services',0,'LSCode'
		union all
		select Jsoncode AS Parameter,ID, 'LSCode' AS DescType from @LinkedServiceJsoncode 
		union all
		Select '#Code for creating/updating pipeline data sets',0,'DSCode'
		union all
		select Jsoncode AS Parameter, ID, 'DSCode' AS DescType from @DataSetJsoncode 
		union all
		Select '#Code for creating/updating pipleine activities',0,'ActivityCode'
		union all
		select Jsoncode AS Parameter, ID, 'ActivityCode' AS DescType from @ActivityJsoncode
) A
ORDER BY CASE WHEN DescType Like '%MasterParameterList%' THEN 1 
			  WHEN DescType Like '%LinkedServiceParameterList%' THEN 2 
			  WHEN DescType Like '%DatasetParameterList%' THEN 3
			  WHEN DescType Like '%ActivityParameterList%' THEN 4
			  WHEN DescType Like '%MasterPipelineParameterList%' THEN 5
			  WHEN DescType Like '%DFCode%' THEN 6
			  WHEN DescType Like '%KVCode%' THEN 7
			  WHEN DescType Like '%LSCode%' THEN 8
			  WHEN DescType Like '%DSCode%' THEN 9 
			  WHEN DescType Like '%Mastercode%' THEN 10
			  WHEN DescType Like '%ActivityCode%' THEN 11 END
GO


