
create procedure [dbo].[final_execution_ps_2] 

as

Declare @pipelinename varchar(100), @PipelineId int
set @pipelinename = (select PipelineName from [dbo].[T_Pipelines] where id=1)
set @pipelinename = (select Id from [dbo].[T_Pipelines] where id=1)
 
declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+code from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipelines_Steps] PS on P.Id = PS.PipelineiD
join [dbo].[T_List_Activities] LS on LS.ID = PS.Activity_ID
where p.Enabled=1

Declare @LSCount int,@LinkedService varchar(200)
Declare @LinkedServiceJsoncode table(Jsoncode varchar(max))
set @LSCount =(SELECT count(*) from T_Pipeline_LinkedServices Where PipeLineId =1)
while @LSCount >0
begin
set @LinkedService= (select LinkedService_Name from [T_LinkedServices] where id =@LSCount)

insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition = @"'
insert into @LinkedServiceJsoncode select Jsoncode from [dbo].[T_LinkedServices] where id=@LSCount
insert into @LinkedServiceJsoncode select '"@'
insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition | Out-File c:\'+@LinkedService+'.json'
insert into @LinkedServiceJsoncode select  'New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "'+@LinkedService+'" -File "c:\'+@LinkedService+'.json"'

set @LSCount=@LSCount-1
End

Declare @DSCount int,@DataSet varchar(200)
Declare @DataSetJsoncode table(Jsoncode varchar(max))
set @DSCount =(SELECT count(*) from T_Pipeline_DataSets Where PipeLineId =1)
while @DSCount >0
begin
set @Dataset= (select DataSet_Name from [T_List_DataSets] where id =@DSCount)

insert into @DataSetJsoncode select '$'+@DataSet+' = @"'
insert into @DataSetJsoncode select Jsoncode from [dbo].[T_List_DataSets] where id=@DSCount
insert into @DataSetJsoncode select '"@'
insert into @DataSetJsoncode select '$'+@DataSet+' | Out-File c:\$'+@DataSet+'.json'
insert into @DataSetJsoncode select  'New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "$'+@DataSet+'" -File "c:\$'+@DataSet+'.json"'

set @DSCount=@DSCount-1
End


--select 'Decalre '+ParameterName from [dbo].[T_Dataset_Parameters]

--select 'SET '+ ParameterName+' = '+ ParameterValue from [dbo].[T_Dataset_Parameters]



--select * from @DataSetJsoncode

select ParameterName+' = '+ ParameterValue from T_Master_Parameters_List
union all
select ParameterName+' = '+ ParameterValue from [dbo].[T_LinkedService_Parameters]
union all
select ParameterName+' = '+ ParameterValue from [dbo].[T_Dataset_Parameters]
union all
select * from @LinkedServiceJsoncode
union all
select * from @DataSetJsoncode
union all
select '$pipelineDefinition = @"'
union all
select '{'
union all
select '"name": "$pipelinename",'
union all select '"properties": {'
union all select         '"activities": ['
union all select             @activity_code +']'
--union all select         ']'
union all select     '}'
union all select 	'}'
union all select '"@'
union all select '$pipelineDefinition | Out-File c:\$finaloutput.json'

union all select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelinename -File "c:\$finaloutput.json"'


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