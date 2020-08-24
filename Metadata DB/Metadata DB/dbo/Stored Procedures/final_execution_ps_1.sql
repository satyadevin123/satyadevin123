
CREATE procedure [dbo].[final_execution_ps_1] 
 
as


Declare @MasterPipelineActivityJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
insert into @MasterPipelineActivityJsoncode select '$pipelineDefinition = @"'
insert into @MasterPipelineActivityJsoncode select Jsoncode From T_Master_Pipelines Where MasterPipelineName='Sendmail'
insert into @MasterPipelineActivityJsoncode select '"@'
insert into @MasterPipelineActivityJsoncode select '$pipelineDefinition | Out-File c:\$finaloutput.json'

insert into @MasterPipelineActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelinename -File "c:\$finaloutput.json"'

Declare @pipelinename varchar(100), @PipelineId int
set @pipelinename = (select PipelineName from [dbo].[T_Pipelines] where id=1)
set @pipelineid = (select Id from [dbo].[T_Pipelines] where id=1)
 
declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+code from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipelines_Steps] PS on P.Id = PS.PipelineiD
join [dbo].[T_List_Activities] LS on LS.ID = PS.Activity_ID
where p.Enabled=1

Declare @LSCount int,@LinkedService varchar(200),@name varchar(200)
Declare @LinkedServiceJsoncode table(Jsoncode varchar(max), ID INT IDENTITY(1,1))
set @LSCount =(SELECT count(*) from T_Pipeline_LinkedServices Where PipeLineId =1)
while @LSCount >0
begin
SELECT @LinkedService= LinkedService_Name , @name = parametervalue from [dbo].[T_Pipeline_LinkedServices] TPL 
JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.ID = TPL.LinkedServiceID 
JOIN [T_Pipeline_LinkedService_Parameters] TPLP on TPLP.LinkedServerId =TPL.LinkedServiceId
where TPLP.ParameterName like '%linkedservicename%'
AND TPL.id =@LSCount


insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition = @"'
insert into @LinkedServiceJsoncode select Jsoncode from [dbo].[T_Pipeline_LinkedServices] 
TPL JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.ID = TPL.LinkedServiceID where TPL.id=@LSCount
insert into @LinkedServiceJsoncode select '"@'
insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition | Out-File c:\'+@LinkedService+'.json'
insert into @LinkedServiceJsoncode select  'New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name '+@name+' -File "c:\'+@LinkedService+'.json"'

set @LSCount=@LSCount-1
End


Declare @DSCount int,@DataSet varchar(200)
Declare @DataSetJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
set @DSCount =(SELECT count(*) from [dbo].[T_Pipeline_DataSets] Where PipeLineId =1)
while @DSCount >0
begin

SELECT @DataSet= DataSet_name , @name = parametervalue from [dbo].[T_Pipeline_DataSets] TPD
JOIN [dbo].[T_List_DataSets] TLD ON TLD.ID = TPD.DataSetId 
JOIN [T_Pipeline_DataSet_Parameters] TPDP on TPDP.DatasetId =TPD.DataSetId
where TPDP.ParameterName like '%datasetname%'
AND TPD.id =@DSCount

--set @Dataset= (select DataSet_Name from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.id where TPD.id =@DSCount)

insert into @DataSetJsoncode select '$'+@DataSet+'Definition = @"'
insert into @DataSetJsoncode select Jsoncode from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.id where TPD.id=@DSCount
insert into @DataSetJsoncode select '"@'
insert into @DataSetJsoncode select '$'+@DataSet+'Definition | Out-File c:\'+@DataSet+'.json'
insert into @DataSetJsoncode select  'New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "'+@name+'" -File "c:\'+@DataSet+'.json"'

set @DSCount=@DSCount-1
End


Declare @ActivityJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
insert into @ActivityJsoncode select '$pipelineDefinition = @"'
insert into @ActivityJsoncode select '{'
insert into @ActivityJsoncode select '"name": "$pipelinename",'
insert into @ActivityJsoncode select '"properties": {'
insert into @ActivityJsoncode select         '"activities": ['
insert into @ActivityJsoncode Exec [dbo].[usp_return_activitycode]@PipelineId 
insert into @ActivityJsoncode select ']'
insert into @ActivityJsoncode select     '}'
insert into @ActivityJsoncode select 	'}'
insert into @ActivityJsoncode select '"@'
insert into @ActivityJsoncode select '$pipelineDefinition | Out-File c:\$finaloutput.json'

insert into @ActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelinename -File "c:\$finaloutput.json"'





--select 'Decalre '+ParameterName from [dbo].[T_Dataset_Parameters]

--select 'SET '+ ParameterName+' = '+ ParameterValue from [dbo].[T_Dataset_Parameters]



--select * from @DataSetJsoncode
IF (Select MAX(EmailNotificationEnabled) From T_Pipelines_steps) =1
SELECT *
FROM (
		--Select '#Pass values to Master Parameters' as Paramter,0 As ID ,'comments' As DescType
		--Union All
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'MasterParameterList' AS DescType from T_Master_Parameters_List
		--union all
		--Select '#Pass values to Linked Service Parameters',0,'comments'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters]
		--union all
		--Select '#Pass values to Dataset Parameters',0,'comments'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,ID, 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_Dataset_Parameters]
		--union all
		--Select '#Pass values to Activity Parameters',0,'comments'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,ID, 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,ID, 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List
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
			  WHEN DescType Like '%LSCode%' THEN 6
			  WHEN DescType Like '%DSCode%' THEN 7 
			  WHEN DescType Like '%Mastercode%' THEN 9
			  WHEN DescType Like '%ActivityCode%' THEN 10 END 
			  ,ID




ELSE
SELECT *
FROM (
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'MasterParameterList' AS DescType from T_Master_Parameters_List
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters]
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_Dataset_Parameters]
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,ID, 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,ID, 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List
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
			  WHEN DescType Like '%LSCode%' THEN 6
			  WHEN DescType Like '%DSCode%' THEN 7 
			  WHEN DescType Like '%Mastercode%' THEN 9
			  WHEN DescType Like '%ActivityCode%' THEN 10 END



--# create a resource gorup
--New-AzResourceGroup -Name $resourceGroupName -Location $dataFactoryNameLocation

--set @code = @code+' '+'# create a data factory'
--set @code = @code+' '+ '$df = Set-AzDataFactory -ResourceGroupName $resourceGroupName -Location $dataFactoryNameLocation -Name $dataFactoryName'

--set @code = @code+' '+'# create a linked service for Azure SQL Database (source)'
--set @code = @code+' '+ (select connection_Details from [dbo].[T_LinkedServices] where id=1)

--set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryLinkedService command. '
--set @code = @code+' '+ '$azureSQLDatabaseLinkedServiceDefinition | Out-File c:\$azureSqlDatabaseLinkedService.json'

--set @code = @code+' '+'## Creates an Az.Storage linked service'
--set @code = @code+' '+ 'Set-AzDataFactoryLinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $azureSqlDatabaseLinkedService -File c:\$azureSqlDatabaseLinkedService.json'


--set @code = @code+' '+'# create a linked service for Azure SQL Datawarehouse (sink)'
--set @code = @code+' '+ (select connection_Details from [dbo].[T_LinkedServices] where id=2)

--set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryLinkedService command. '
--set @code = @code+' '+ '$azureSQLDataWarehouseLinkedServiceDefinition | Out-File c:\$azureSqlDataWarehouseLinkedService.json'

--set @code = @code+' '+'## Creates an linked service for Az.Storage Account. Interim storage to enable PolyBase'
--set @code = @code+' '+ 'Set-AzDataFactoryLinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $azureSqlDataWarehouseLinkedService -File c:\$azureSqlDataWarehouseLinkedService.json'

--set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryLinkedService command. '
--set @code = @code+' '+ '$storageLinkedServiceDefinition | Out-File c:\$azureStorageLinkedService.json'

--set @code = @code+' '+'## Creates an Az.Storage linked service'
--set @code = @code+' '+ 'Set-AzDataFactoryLinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $azureStorageLinkedService -File c:\$azureStorageLinkedService.json'


--set @code = @code+' '+'# create the input dataset (Azure SQL Database)'
--set @code = @code+' '+ (select [DataSet_Definition] from [T_List_DataSets] where id =1)

--set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryDataset command. '
--set @code = @code+' '+ '$azureSqlDatabaseDatasetDefiniton | Out-File c:\$azureSqlDatabaseDataset.json'

--set @code = @code+' '+'## Create a dataset in the data factory'
--set @code = @code+' '+ 'Set-AzDataFactoryDataset -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $azureSqlDatabaseDataset -File "c:\$azureSqlDatabaseDataset.json"'


--set @code = @code+' '+'# create the output dataset (Azure SQL Data Warehouse)'
--set @code = @code+' '+ (select [DataSet_Definition] from [T_List_DataSets] where id =2)
--set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryDataset command. '
--set @code = @code+' '+ '$azureSqlDataWarehouseDatasetDefiniton | Out-File c:\$azureSqlDataWarehouseDataset.json'

--set @code = @code+' '+'## Create a dataset in the data factory'
--set @code = @code+' '+ 'Set-AzDataFactoryDataset -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $azureSqlDataWarehouseDataset -File "c:\$azureSqlDataWarehouseDataset.json"'

--set @code = @code+' '+'# Create a pipeline in the data factory that copies data from source SQL Database to sink SQL Data Warehouse'
----# Create a pipeline run 

----## JSON definition for dummy pipeline parameters
----$T_PipelineParameters = @"
----{
----    "dummy":  "b"
----}
----"@

----## IMPORTANT: store the JSON definition in a file that will be used by the Invoke-AzDataFactoryPipeline command. 
----$T_PipelineParameters | Out-File c:\T_PipelineParameters.json

----# Create a pipeline run by using parameters
----$runId = Invoke-AzDataFactoryPipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineName $pipelineGetTableListAndTriggerCopyData -ParameterFile c:\T_PipelineParameters.json

----# Check the pipeline run status until it finishes the copy operation
----Start-Sleep -Seconds 30
----while ($True) {
----    $result = Get-AzDataFactoryActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineRunId $runId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)

----    if (($result | Where-Object { $_.Status -eq "InProgress" } | Measure-Object).count -ne 0) {
----        Write-Host "Pipeline run status: In Progress" -foregroundcolor "Yellow"
----        Start-Sleep -Seconds 30
----    }
----    else {
----        Write-Host "Pipeline ''$pipelineGetTableListAndTriggerCopyData'' run finished. Result:" -foregroundcolor "Yellow"
----        $result
----        break
----    }
----}

----# Get the activity run details 
----    $result = Get-AzDataFactoryActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName `
----        -PipelineRunId $runId `
----        -RunStartedAfter (Get-Date).AddMinutes(-10) `
----        -RunStartedBefore (Get-Date).AddMinutes(10) `
----        -ErrorAction Stop

----    $result

----    if ($result.Status -eq "Succeeded") {`
----        $result.Output -join "`r`n"`
----    }`
----    else {`
----        $result.Error -join "`r`n"`
----    }

----# To remove the data factory from the resource gorup
----# Remove-AzDataFactory -Name $dataFactoryName -ResourceGroupName $resourceGroupName
----# 
----# To remove the whole resource group
----# Remove-AzResourceGroup  -Name $resourceGroupName