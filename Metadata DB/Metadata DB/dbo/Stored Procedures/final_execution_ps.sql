CREATE procedure [dbo].[final_execution_ps] 

@resourceGroupName varchar(500) ='saga_freetrail',
@dataFactoryName varchar(500)='pocmetadata',
@dataFactoryNameLocation varchar(500)='',
@azureSqlServer varchar(500)='',
@azureSqlServerUser varchar(500)='',
@azureSqlServerUserPassword varchar(500)='',
@azureSqlDatabase varchar(500)='',
@azureSqlDataWarehouse varchar(500)='',
@azureStorageAccount varchar(500)='',
@azureStorageAccountKey varchar(500)='',
@azureSqlDatabaseLinkedService varchar(500)='',
@azureSqlDataWarehouseLinkedService varchar(500)='',
@azureStorageLinkedService varchar(500)='',
@azureSqlDatabaseDataset varchar(500)='',
@azureSqlDataWarehouseDataset varchar(500)='',
@IterateAndCopySQLTablesPipeline varchar(500)='',
@pipelineGetTableListAndTriggerCopyData varchar(500)=''
as

Declare @code varchar(max)
 set @code = '# Set variables with your own values
$resourceGroupName = "'+@resourceGroupName+'"
$dataFactoryName = "'+@dataFactoryName+'" # Name of the data factory must be globally unique
$dataFactoryNameLocation = "'+@dataFactoryNameLocation+'"

$azureSqlServer = "'+@azureSqlServer+'"
$azureSqlServerUser = "'+@azureSqlServerUser+'"
$azureSqlServerUserPassword = "'+@azureSqlServerUserPassword+'"
$azureSqlDatabase = "'+@azureSqlDatabase+'"
$azureSqlDataWarehouse = "'+@azureSqlDataWarehouse+'"

$azureStorageAccount = "'+@azureStorageAccount+'"
$azureStorageAccountKey = "'+@azureStorageAccountKey+'"
$azureSqlDatabaseLinkedService = "'+@azureSqlDatabaseLinkedService+'"
$azureSqlDataWarehouseLinkedService = "'+@azureSqlDataWarehouseLinkedService+'"
$azureStorageLinkedService = "'+@azureStorageLinkedService+'"
$azureSqlDatabaseDataset = "'+@azureSqlDatabaseDataset+'"
$azureSqlDataWarehouseDataset = "'+@azureSqlDataWarehouseDataset+'"
$IterateAndCopySQLTablesPipeline = "'+@IterateAndCopySQLTablesPipeline+'"
$pipelineGetTableListAndTriggerCopyData = "'+@pipelineGetTableListAndTriggerCopyData

declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+code from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipelines_Steps] PS on P.Id = PS.PipelineiD
join [dbo].[T_List_Activities] LS on LS.ID = PS.Activity_ID
where p.Enabled=1
--PRINT @activity_code


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

--set @code = @code+' '+ (select connection_Details from [dbo].[T_LinkedServices] where id=3)
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
set @code = @code+' '+ '$pipelineDefinition = @"
{
    "name": "$IterateAndCopySQLTablesPipeline",
    "properties": {
        "activities": [
            {'
                set @code = @code+' '+ (select code from [dbo].[T_List_Activities] where id =1)+',    "activities": ['+(select code from [dbo].[T_List_Activities] where id =2)+' "@'

set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryPipeline command. '
set @code = @code+' '+ '$pipelineDefinition | Out-File c:\$IterateAndCopySQLTablesPipeline.json'

set @code = @code+' '+'## Create a pipeline in the data factory'
set @code = @code+' '+ 'Set-AzDataFactoryPipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $IterateAndCopySQLTablesPipeline -File "c:\$IterateAndCopySQLTablesPipeline.json"'


set @code = @code+' '+'# Create a pipeline in the data factory that retrieves a list of tables and invokes the above pipeline for each table to be copied'
set @code = @code+' '+'$pipeline2Definition = @"
{
    "name":"$pipelineGetTableListAndTriggerCopyData",
    "properties":{
        "activities":['+
            @activity_code+'
        ]
    }

"@'

set @code = @code+' '+'## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryPipeline command. '
set @code = @code+' '+ '$pipeline2Definition | Out-File c:\$pipelineGetTableListAndTriggerCopyData.json'

set @code = @code+' '+'## Create a pipeline in the data factory'
set @code = @code+' '+ 'Set-AzDataFactoryPipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelineGetTableListAndTriggerCopyData -File "c:\$pipelineGetTableListAndTriggerCopyData.json"'

select @code

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