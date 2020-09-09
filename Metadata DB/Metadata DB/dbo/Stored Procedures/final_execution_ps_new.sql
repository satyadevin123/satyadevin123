
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
insert into @DFCreationJsonCode select 'Set-AzDataFactoryV2IntegrationRuntime -DataFactoryName $dataFactoryName -Name $nameofintegrationruntime -ResourceGroupName $resourceGroupName -Type Managed -Location $dataFactoryNameLocation -Force'

insert into @KeyVaultJsonCode select 
'Set-AzKeyVaultAccessPolicy -VaultName $keyvaultname -ResourceGroupName $resourceGroupName -ObjectId $spID -PermissionsToKeys get -PermissionsToSecrets get'

declare @emailpipelinename nvarchar(100)

insert into @MasterPipelineActivityJsoncode select '$pipelineDefinition = @"'
insert into @MasterPipelineActivityJsoncode select Jsoncode From T_Master_Pipelines Where MasterPipelineName='Sendmail'
insert into @MasterPipelineActivityJsoncode select '"@'
insert into @MasterPipelineActivityJsoncode select '$pipelineDefinition | Out-File c:\$finaloutput.json'

insert into @MasterPipelineActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $sendmailMasterPipelineName -Force -File "c:\$finaloutput.json"'

Declare @pipelinename varchar(100)
set @pipelinename = (select PipelineName from [dbo].[T_Pipelines] where [PipelineId]=@PipelineId )

declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+[JsonCode] from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipeline_Activities] PS on P.[PipelineId] = PS.PipelineiD
join [dbo].[T_List_Activities] LS on LS.[ActivityId] = PS.[ActivityID]
where p.Enabled=1 AND P.PipelineId = @PipelineId

Declare @LSCount int,@LinkedService varchar(200),@name varchar(200),@LSInit int
Declare @LinkedServiceJsoncode table(Jsoncode varchar(max), ID INT IDENTITY(1,1))
set @LSCount =(SELECT count(*) from T_Pipeline_LinkedServices Where PipeLineId =@PipelineId )
declare @lsid int
declare @dsid int
declare @tbl table
(rownum int, id int)

insert into @tbl
select row_number() over(order by [PipelineLinkedServicesID] ),[PipelineLinkedServicesID] from dbo.T_Pipeline_LinkedServices where PipelineId = @PipelineId

set @LSInit = 1

while @LSInit <=  @LSCount
begin
SELECT @LinkedService= [LinkedServiceName] , @name = parametervalue, @lsid = tpl.[PipelineLinkedServicesID] from [dbo].[T_Pipeline_LinkedServices] TPL 
JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.[LinkedServiceId] = TPL.LinkedServiceID 
JOIN [T_Pipeline_LinkedService_Parameters] TPLP on TPLP.LinkedServerId =TPL.[PipelineLinkedServicesID]
JOIN @tbl t ON t.id = tpl.[PipelineLinkedServicesID]
where TPLP.ParameterName like '%linkedservicename%'
AND t.rownum =@LSInit AND tplp.PipelineId = @PipelineId


insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition = @"'
insert into @LinkedServiceJsoncode select REPLACE(Jsoncode,'$','$'+CAST(TPL.[PipelineLinkedServicesID] AS nvarchar)+'_') from [dbo].[T_Pipeline_LinkedServices] 
TPL JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.[LinkedServiceId] = TPL.LinkedServiceID where TPL.[PipelineLinkedServicesID]=@lsid
insert into @LinkedServiceJsoncode select '"@'
insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition | Out-File c:\'+@LinkedService+'.json'
insert into @LinkedServiceJsoncode select  'New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name '+@name+' -File "c:\'+@LinkedService+'.json"'

set @LSInit=@LSInit+1
End


Declare @DSCount int,@DataSet varchar(200)
Declare @DataSetJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
set @DSCount =(SELECT count(*) from [dbo].[T_Pipeline_DataSets] Where PipeLineId =@PipelineId )


declare @tbl1 table
(rownum int, id int)

insert into @tbl1
select row_number() over(order by [PipelineDatasetId]),[PipelineDatasetId] from dbo.[T_Pipeline_DataSets] where PipelineId = @PipelineId

while @DSCount >0
begin

SELECT @DataSet= TLD.[DataSetName] , @name = parametervalue,@DSJsonCode=Jsoncode,@dsid=TPD.[PipelineDatasetId] from [dbo].[T_Pipeline_DataSets] TPD
JOIN [dbo].[T_List_DataSets] TLD ON TLD.[DatasetId] = TPD.DataSetId 
JOIN [T_Pipeline_DataSet_Parameters] TPDP on TPDP.[PipelineDatasetId] =TPD.[PipelineDatasetId]
JOIN @tbl1 t ON t.Id = TPD.[PipelineDatasetId]
where TPDP.ParameterName like '%datasetname%'
AND t.rownum =@DSCount AND tpdp.pipelineid = @PipelineId

--set @Dataset= (select DataSet_Name from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.id where TPD.id =@DSCount)

insert into @DataSetJsoncode select '$'+@DataSet+'Definition = @"'
insert into @DataSetJsoncode select REPLACE(TLD.Jsoncode,'$','$'+CAST(TPL.[PipelineLinkedServicesID] AS nvarchar)+'_') from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.[DatasetId] JOIN T_Pipeline_LinkedServices TPL ON TPL.[PipelineLinkedServicesID] = TPD.LinkedServericeId JOIN T_List_LinkedServices TLL ON TLL.[LinkedServiceId] = TPL.LinkedServiceId where TPD.[PipelineDatasetId]=@dsid AND TPL.PipelineId = @PipelineId
insert into @DataSetJsoncode select '"@'
insert into @DataSetJsoncode select '$'+@DataSet+'Definition | Out-File c:\'+@DataSet+'.json'
insert into @DataSetJsoncode select  'New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "'+@name+'" -File "c:\'+@DataSet+'.json"'

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
insert into @ActivityJsoncode select '$pipelineDefinition | Out-File c:\$finaloutput.json'

insert into @ActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name $pipelinename -File "c:\$finaloutput.json"'





--select 'Decalre '+ParameterName from [dbo].[T_Dataset_Parameters]

--select 'SET '+ ParameterName+' = '+ ParameterValue from [dbo].[T_Dataset_Parameters]



--select * from @DataSetJsoncode
IF (Select MAX(EmailNotificationEnabled) From [T_Pipeline_Activities]) =1
SELECT Parameter
FROM (
		select '$pipelinename = "'+ @pipelinename +'"' AS Parameter,0 AS ID, 'MasterParameterList' AS DescType 
	    union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[MasterParameterId], 'MasterParameterList' AS DescType from T_Master_Parameters_List
		--union all
		--Select '#Pass values to Linked Service Parameters',0,'comments'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[PipelineLinkedServicesParameterID], 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters] WHERE pipelineid = @PipelineId
		--union all
		--Select '#Pass values to Dataset Parameters',0,'comments'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,[PipelineDatasetParameterId], 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_Dataset_Parameters]  WHERE pipelineid = @PipelineId
		--union all
		--Select '#Pass values to Activity Parameters',0,'comments'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,[PipelineActivityParameterId], 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'  AND pipelineid = @PipelineId
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,[MasterParameterPipelineId], 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List
		union all
		select Jsoncode AS Parameter,ID, 'DFCode' AS DescType from @DFCreationJsonCode 
		union all
		select Jsoncode AS Parameter,ID, 'KVCode' AS DescType from @KeyVaultJsonCode
		union all
		select Jsoncode AS Parameter,ID, 'LSCode' AS DescType from @LinkedServiceJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'DSCode' AS DescType from @DataSetJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'Mastercode' AS DescTyp from @MasterPipelineActivityJsoncode
		Union all
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
		select ParameterName+' = '+ ParameterValue AS Parameter,[MasterParameterId], 'MasterParameterList' AS DescType from T_Master_Parameters_List
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,[PipelineLinkedServicesParameterID], 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters]  WHERE pipelineid = @PipelineId
		union all
		select ParameterName+' = "'+ ParameterValue +'"' AS Parameter,[PipelineDatasetParameterId], 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_Dataset_Parameters] WHERE pipelineid = @PipelineId
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,[PipelineActivityParameterId], 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'  AND pipelineid = @PipelineId
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,[MasterParameterPipelineId], 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List 
		union all
		select Jsoncode AS Parameter,ID, 'DFCode' AS DescType from @DFCreationJsonCode 
		union all
		select Jsoncode AS Parameter,ID, 'KVCode' AS DescType from @KeyVaultJsonCode
		union all
		select Jsoncode AS Parameter,ID, 'LSCode' AS DescType from @LinkedServiceJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'DSCode' AS DescType from @DataSetJsoncode 
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


