 Param([Parameter(Mandatory=$True,Position=1)][string]$logfilepath,[Parameter(Mandatory=$True,Position=2)][string]$ScriptPath)
$pipelinename = "AdvWorks_From_AzureSqldb_To_ADLS_1"
#Variables for master parameters
$resourceGroupName = "RG-data-pipeline-framework-poc"
$dataFactoryName = "DFMetadataPoCDemo14apr"
$subscriptionid = "81ec4907-9db6-4d56-86d4-d997209d7be6"
$dataFactoryNameLocation = "EAST US"
$tenantid = "bdcfaa46-3f69-4dfd-b3f7-c582bdfbb820"
$sendmailMasterPipelineName = "sendmail"
$finalouput = "pocmeta"
$azuredeployparametersjson = 
$nameofintegrationruntime = "Azure-IR-ADF"
$SinkAccountName = "metadatapocdemo14apr"
$keyvaultname = "KVMetadataPoCDemo14Apr"
$keyvaultlocation = "EAST US"
$servicePrincipalId = 
$servicePrincipalKey = 
$EmailTo = "satyadevi.nimmakayala@winwire.com"
$LogicAppURL = "https://prod-90.eastus.logic.azure.com:443/workflows/d0a3d68c0ce14e0bbb322d349d22cd05/triggers/manual/paths/invoke?api-version=2018-07-01-preview&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=dYoPttMsIpaKNM13QvkzgL5nGDeFiAgvBGgMK7KN8so"
#Variables for Linked Service Parameters
$1_azureKeyVaultLinkedServiceName = "LS_KeyVault"
$1_keyvaultname = "KVMetadataPoCDemo"
$2_azureSQLDatabaseLinkedServiceName = "LS_MetadataDB"
$2_azureSqlDBServerName = "poc-metadatadriven"
$2_azureSqlDatabaseName = "MetadataDBPublish"
$2_nameofintegrationruntime = "Azure-IR-ADF"
$3_azureSQLDatabaseLinkedServiceName = "LS_AdventureWorksAzureSql"
$3_azureSqlDBServerName = "poc-metadatadriven"
$3_azureSqlDatabaseName = "AdventureWorksSample"
$3_nameofintegrationruntime = "Azure-IR-ADF"
$4_azureSQLDatabaseLinkedServiceName = "LS_AdventureWorksAzureSql2"
$4_azureSqlDBServerName = "poc-metadatadriven"
$4_azureSqlDatabaseName = "AdventureWorksSample1"
$4_nameofintegrationruntime = "Azure-IR-ADF"
$5_ADLSv2LinkedServiceName = "LS_ADLSV2"
$5_ADLSv2AccountName = "metadatapocdemo14apr"
$5_URL = "https://metadatapocdemo14apr.dfs.core.windows.net"
$5_nameofintegrationruntime = "Azure-IR-ADF"
#Variables for Dataset Parameters
$1_1_azureSQLDatabaseDatasetName = "DS_LKP_1"
$1_1_azureSQLDatabaseLinkedServiceName = "LS_MetadataDB"
$2_1_azureSQLDatabaseDatasetName = "DS_CP_SRC_DataCopy_1"
$2_1_azureSQLDatabaseLinkedServiceName = "LS_AdventureWorksAzureSql"
$3_1_ADLSV2DataSetName = "DS_CP_SINK_DataCopy_1"
$3_1_ADLSV2LinkedServiceName = "LS_ADLSV2"
$3_1_fileSystemFolderName = "frompipeline1"
$3_1_CompressionCodectype = "none"
$3_1_fileformat = "DelimitedText"
$3_1_fileextension = "csv"
$3_1_ColumnDelimiter = ","
#Variables for pipeline Activity Parameters
$Foreach_SourceEntity_1_isSequential = "false"
$LKP_1_LookupActivityname = "LKP_1"
$FE_LKP_LookupActivityname = "FE_LKP"
$FE_LKP_CNT_LookupActivityname = "FE_LKP_CNT"
$LKP_1_query = "SELECT SchemaName,TableName,'DelimitedText' as fileformat,'csv' as fileextension,',' as columnDelimiter,Query, IsIncremental, LastRefreshedBasedOn, 
ISNULL(LastRefreshedDateTime,CAST('1900-01-01 00:00:00.000' AS DATETime)) AS LastRefreshedDateTime,CntQuery  
FROM t_pipeline_tables_tobemoved WHERE IsActive = 1 AND pipelineid = 1"
$FE_LKP_query = "@if(equals(item().IsIncremental,true),concat('select max(',item().LastRefreshedBasedOn,') as maxval from ','[',item().schemaname,']','.','[',item().tablename,']'),'SELECT ''NULL'' AS maxval')"
$FE_LKP_CNT_query = "@if(equals(item().IsIncremental,true),concat(item().CntQuery,' WHERE ',item().LastRefreshedBasedOn ,' > CAST(''',item().LastRefreshedDateTime,''' AS Datetime) AND ',item().LastRefreshedBasedOn,' <= CAST(''',activity('FE_LKP').output.firstrow.maxval,''' AS Datetime)'),item().CntQuery)"
$LKP_1_dataset = "DS_LKP_1"
$FE_LKP_dataset = "DS_CP_SRC_DataCopy_1"
$FE_LKP_CNT_dataset = "DS_CP_SRC_DataCopy_1"
$LKP_1_firstrow = "false"
$FE_LKP_firstrow = "true"
$FE_LKP_CNT_firstrow = "true"
$Foreach_SourceEntity_1_foreachactivityname = "Foreach_SourceEntity_1"
$Foreach_SourceEntity_1_dependson = "LKP_1"
$Foreach_SourceEntity_1_dependencyConditions = "Succeeded"
$Foreach_SourceEntity_1_dependentactivityname = "LKP_1"
$Foreach_SourceEntity_1_batchCount = "20"
$LKP_1_dependson = "SPPipelineInprogressActivity"
$FE_LKP_dependson = ""
$FE_LKP_CNT_dependson = "FE_LKP"
$CP_1_CopyActivityName = "CP_1"
$CP_1_Source = "AzureSqlSource"
$CP_1_Sink = "ParquetSink"
$CP_1_inputDatasetReference = "DS_CP_SRC_DataCopy_1"
$CP_1_outputDatasetReference = "DS_CP_SINK_DataCopy_1"
$CP_1_dependson = ""

$CP_1_parameters = "       ""filename"": {""value"": ""@concat(item().tablename,'_',utcnow())"",""type"": ""Expression""},                                          ""directory"": ""@item().tablename"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter"""
$CP_1_sqlReaderQuery = "@if(equals(item().IsIncremental,true),concat(item().Query,' WHERE ',item().LastRefreshedBasedOn ,' > CAST(''',item().LastRefreshedDateTime,''' AS Datetime) AND ',item().LastRefreshedBasedOn,' <= CAST(''',activity('FE_LKP').output.firstrow.maxval,''' AS Datetime)'),item().Query)"
$SPPipelineInprogressActivity_SPName = "usp_Log_PipelineStatus"
$SPPipelineFailedActivity1_SPName = "usp_Log_PipelineStatus"
$SPPipelineFailedActivity2_SPName = "usp_Log_PipelineStatus"
$SPPipelineFailedActivity3_SPName = "usp_Log_PipelineStatus"
$SPPipelineSucceededActivity_SPName = "usp_Log_PipelineStatus"
$SPPipelineInprogressActivity_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SPPipelineFailedActivity1_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SPPipelineFailedActivity2_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SPPipelineFailedActivity3_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SPPipelineSucceededActivity_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SPPipelineInprogressActivity_SPActivityName = "SPPipelineInprogressActivity"
$SPPipelineFailedActivity1_SPActivityName = "SPPipelineFailedActivity1"
$SPPipelineFailedActivity2_SPActivityName = "SPPipelineFailedActivity2"
$SPPipelineFailedActivity3_SPActivityName = "SPPipelineFailedActivity3"
$SPPipelineSucceededActivity_SPActivityName = "SPPipelineSucceededActivity"
$SPPipelineInprogressActivity_dependson = ""
$SPPipelineFailedActivity1_dependson = "SPPipelineInprogressActivity"
$SPPipelineFailedActivity2_dependson = "LKP_1"
$SPPipelineFailedActivity3_dependson = "Foreach_SourceEntity_1"
$SPPipelineSucceededActivity_dependson = "Foreach_SourceEntity_1"

$SPPipelineFailedActivity1_dependencyConditions = "Failed"
$SPPipelineFailedActivity2_dependencyConditions = "Failed"
$SPPipelineFailedActivity3_dependencyConditions = "Failed"
$SPPipelineSucceededActivity_dependencyConditions = "Succeeded"
$LKP_1_dependencyConditions = "Succeeded"

$FE_LKP_CNT_dependencyConditions = "Succeeded"
$SP_CopyActivityLogging_SPName = "usp_InsertPipelineCopyLogDetails"
$SP_CopyActivityLoggingNoDeltaRecords_SPName = "usp_InsertPipelineCopyLogDetails"
$SP_CopyActivityLogging_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SP_CopyActivityLoggingNoDeltaRecords_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SP_CopyActivityLogging_SPActivityName = "SP_CopyActivityLogging"
$SP_CopyActivityLoggingNoDeltaRecords_SPActivityName = "SP_CopyActivityLoggingNoDeltaRecords"
$SP_CopyActivityLogging_dependson = "CP_1"
$SP_CopyActivityLoggingNoDeltaRecords_dependson = ""
$SP_CopyActivityLogging_dependencyConditions = "Succeeded"

$SP_MaxRefreshUpdate_SPName = "usp_UpdateMaxRefreshDate"
$SP_MaxRefreshUpdate_MetadataDBLinkedServiceName = "LS_MetadataDB"
$SP_MaxRefreshUpdate_SPActivityName = "SP_MaxRefreshUpdate"
$SP_MaxRefreshUpdate_dependson = "SP_CopyActivityLogging"
$SP_MaxRefreshUpdate_dependencyConditions = "Succeeded"
$IfCondition_ifactivityname = "IfCondition"
$IfCondition_dependson = "FE_LKP_CNT"
$IfCondition_dependencyConditions = "Succeeded"
$IfCondition_ifFalseActivityCode = ""
$IfCondition_ifTrueActivityCode = ""
$SPPipelineInprogressActivity_SPParameters = "    { ""In_PipelineName"": {""value"":      {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                     ""type"": ""String""                          },    ""In_PipelineStatus"": {                              ""value"": ""InProgress"",          ""type"": ""String""                          },                   ""In_ExecutionStartTime"": {                                 ""value"": {                                 ""value"": ""@utcnow()"",          ""type"": ""Expression""                              },                       ""type"": ""Datetime""                          },                           ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                         ""type"": ""Datetime""                          }            ,              ""In_PipelineRunID"": {""value"":      {""value"": ""@pipeline().RunId"",""type"": ""Expression""},                     ""type"": ""String""                          }  "
$SPPipelineFailedActivity1_SPParameters = "    { ""In_PipelineName"": {""value"":      {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                     ""type"": ""String""                          },    ""In_PipelineStatus"": {                              ""value"": ""Failed"",          ""type"": ""String""                          },                   ""In_ExecutionStartTime"": {                                 ""value"": {                                 ""value"": ""@utcnow()"",          ""type"": ""Expression""                              },                       ""type"": ""Datetime""                          },                           ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                         ""type"": ""Datetime""                          }            ,              ""In_PipelineRunID"": {""value"":      {""value"": ""@pipeline().RunId"",""type"": ""Expression""},                     ""type"": ""String""                          }  ,                           ""In_ErrorMessage"": {                             
                                   ""value"": ""@activity('SPPipelineInprogressActivity').Error.Message"",            
                                   ""type"": ""string""                          }   "
$SPPipelineFailedActivity2_SPParameters = "    { ""In_PipelineName"": {""value"":      {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                     ""type"": ""String""                          },    ""In_PipelineStatus"": {                              ""value"": ""Failed"",          ""type"": ""String""                          },                   ""In_ExecutionStartTime"": {                                 ""value"": {                                 ""value"": ""@utcnow()"",          ""type"": ""Expression""                              },                       ""type"": ""Datetime""                          },                           ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                         ""type"": ""Datetime""                          }            ,              ""In_PipelineRunID"": {""value"":      {""value"": ""@pipeline().RunId"",""type"": ""Expression""},                     ""type"": ""String""                          }  ,                           ""In_ErrorMessage"": {                             
                                   ""value"": ""@activity('LKP_1').Error.Message"",            
                                   ""type"": ""string""                          }   "
$SPPipelineFailedActivity3_SPParameters = "    { ""In_PipelineName"": {""value"":      {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                     ""type"": ""String""                          },    ""In_PipelineStatus"": {                              ""value"": ""Failed"",          ""type"": ""String""                          },                   ""In_ExecutionStartTime"": {                                 ""value"": {                                 ""value"": ""@utcnow()"",          ""type"": ""Expression""                              },                       ""type"": ""Datetime""                          },                           ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                         ""type"": ""Datetime""                          }            ,              ""In_PipelineRunID"": {""value"":      {""value"": ""@pipeline().RunId"",""type"": ""Expression""},                     ""type"": ""String""                          }  ,                           ""In_ErrorMessage"": {                             
                                   ""value"": ""@activity('Foreach_SourceEntity_1').Error.Message"",            
                                   ""type"": ""string""                          }   "
$SPPipelineSucceededActivity_SPParameters = "    { ""In_PipelineName"": {""value"":      {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                     ""type"": ""String""                          },    ""In_PipelineStatus"": {                              ""value"": ""Succeeded"",          ""type"": ""String""                          },                   ""In_ExecutionStartTime"": {                                 ""value"": {                                 ""value"": ""@utcnow()"",          ""type"": ""Expression""                              },                       ""type"": ""Datetime""                          },                           ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                         ""type"": ""Datetime""                          }            ,              ""In_PipelineRunID"": {""value"":      {""value"": ""@pipeline().RunId"",""type"": ""Expression""},                     ""type"": ""String""                          }  "
$SP_CopyActivityLogging_SPParameters = "   {""In_PipelineRunID"": {""value"": {""value"": ""@pipeline().RunId"",""type"": ""Expression""},""type"": ""Guid""},""In_RowsCopied"": {""value"": {""value"": ""@activity('$SP_CopyActivityLogging_dependson').output.rowsCopied"",""type"": ""Expression""},""type"": ""Int64""  },""In_RowsRead"": {""value"": {""value"": ""@activity('$SP_CopyActivityLogging_dependson').output.rowsRead"",""type"": ""Expression""},""type"": ""Int64""},  ""In_Duration"": {""value"": {""value"": ""@activity('$SP_CopyActivityLogging_dependson').output.copyDuration"",""type"": ""Expression""},""type"": ""Int16""},  ""In_Status"": {""value"": {""value"": ""@activity('$SP_CopyActivityLogging_dependson').output.executionDetails[0].status"",""type"": ""Expression""},""type"": ""String""},""In_StartTime"": { ""value"": {  ""value"": ""@activity('$SP_CopyActivityLogging_dependson').output.executionDetails[0].start"",""type"": ""Expression""},""type"": ""Datetime""},""In_EndTime"": {  ""value"": {""value"": ""@utcnow()"",""type"": ""Expression""},""type"": ""Datetime""},""In_EntityName"": {""value"": {""value"": ""@item().tablename"",""type"": ""Expression""},""type"": ""String""  }  }  "
$SP_CopyActivityLoggingNoDeltaRecords_SPParameters = "   {""In_PipelineRunID"": {""value"": {""value"": ""@pipeline().RunId"",""type"": ""Expression""},""type"": ""Guid""},
   ""In_RowsCopied"": {""value"": {""value"": ""0"",""type"": ""Expression""},""type"": ""Int64""  },
   ""In_RowsRead"": {""value"": {""value"": ""0"",""type"": ""Expression""},""type"": ""Int64""},  
   ""In_Duration"": {""value"": {""value"": ""0"",""type"": ""Expression""},""type"": ""Int16""},  
   ""In_Status"": {""value"": {""value"": ""NoDeltaRecords"",""type"": ""Expression""},""type"": ""String""},
   ""In_StartTime"": { ""value"": {  ""value"": ""@utcnow()"",""type"": ""Expression""},""type"": ""Datetime""},
   ""In_EndTime"": {  ""value"": {""value"": ""@utcnow()"",""type"": ""Expression""},""type"": ""Datetime""},
   ""In_EntityName"": {""value"": {""value"": ""@item().tablename"",""type"": ""Expression""},""type"": ""String""  }  }  "
$SP_MaxRefreshUpdate_SPParameters = "{""TableName"": { ""value"": {""value"": ""@item().TableName"", ""type"": ""Expression"" },""type"": ""String""},""SchemaName"": {
""value"": {""value"": ""@item().SchemaName"",""type"": ""Expression""},""type"": ""String""},
""PipelineName"": {""value"": {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},""type"": ""String""},
""MaxRefreshDateTime"": {""value"": {""value"": ""@activity('FE_LKP').output.firstrow.maxval"",""type"": ""Expression""},""type"": ""String""}
}"
#Variables for master pipeline paramters i.e sendmail
$body = '"{\"EmailTo\": \"@{pipeline().parameters.EmailTo}\",  \"Subject\": \"An error has occured in the @{pipeline().parameters.PipelineName}-pipeline\",  \"DataFactoryName\": \"@{pipeline().DataFactory}\",  \"PipelineName\": \"@{pipeline().parameters.PipelineName}\",  \"Activity\": \"@{pipeline().parameters.Activity}\",  \"Message\": \"@{pipeline().parameters.Message}\"}"'
$Activity = ""
$PipelineEndedMessage = "The $Pipeline is Ended"
$PipelineStartedMessage = "The $Pipeline is Started"
Start-Transcript -Path $logfilepath -Append -Force
#Code for creating/updating data factory
New-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName –Location $dataFactoryNameLocation -Force
$sinkAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $SinkAccountName  -ErrorAction SilentlyContinue
if($sinkAccount -eq $null){
		 New-AzStorageAccount -Kind StorageV2 -ResourceGroupName $resourceGroupName -Name $SinkAccountName -Location $dataFactoryNameLocation -EnableHierarchicalNamespace $true -SkuName Standard_LRS }
$spID = (Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName).Identity.PrincipalId 
New-AzRoleAssignment -ObjectId $spID -RoleDefinitionName "Storage Blob Data Contributor" -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$SinkAccountName" -ErrorAction SilentlyContinue
Set-AzDataFactoryV2IntegrationRuntime -DataFactoryName $dataFactoryName -Name "Azure-IR-ADF" -ResourceGroupName $resourceGroupName -Type "Managed" -Location $dataFactoryNameLocation -Force
#Code for creating/updating key vault
Set-AzKeyVaultAccessPolicy -VaultName $keyvaultname -ResourceGroupName $resourceGroupName -ObjectId $spID -PermissionsToKeys get -PermissionsToSecrets get
#Code for creating/updating linked services
$LS_KeyVaultDefinition = @"
{    "name": "$1_azureKeyVaultLinkedServiceName",    "properties": {        "annotations": [],        "type": "AzureKeyVault",       "typeProperties": {            "baseUrl": "https://$1_keyvaultname.vault.azure.net/"        }    }}
"@
$LS_KeyVaultDefinition | Out-File "$ScriptPath\OutputPipelineScripts\LS_KeyVault.json"
New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "LS_KeyVault" -File "$ScriptPath\OutputPipelineScripts\LS_KeyVault.json"
$LS_MetadataDBDefinition = @"
     { "name": "$2_azureSqlDatabaseLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "AzureSqlDatabase",          "typeProperties": {              "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$2_azureSqlDBServerName.database.windows.net;Initial Catalog=$2_azureSqlDatabaseName"          }      }  }
"@
$LS_MetadataDBDefinition | Out-File "$ScriptPath\OutputPipelineScripts\LS_MetadataDB.json"
New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "LS_MetadataDB" -File "$ScriptPath\OutputPipelineScripts\LS_MetadataDB.json"
$LS_AdventureWorksAzureSqlDefinition = @"
     { "name": "$3_azureSqlDatabaseLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "AzureSqlDatabase",          "typeProperties": {              "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$3_azureSqlDBServerName.database.windows.net;Initial Catalog=$3_azureSqlDatabaseName"          }      }  }
"@
$LS_AdventureWorksAzureSqlDefinition | Out-File "$ScriptPath\OutputPipelineScripts\LS_AdventureWorksAzureSql.json"
New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "LS_AdventureWorksAzureSql" -File "$ScriptPath\OutputPipelineScripts\LS_AdventureWorksAzureSql.json"
$LS_AdventureWorksAzureSql2Definition = @"
     { "name": "$4_azureSqlDatabaseLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "AzureSqlDatabase",          "typeProperties": {              "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$4_azureSqlDBServerName.database.windows.net;Initial Catalog=$4_azureSqlDatabaseName"          }      }  }
"@
$LS_AdventureWorksAzureSql2Definition | Out-File "$ScriptPath\OutputPipelineScripts\LS_AdventureWorksAzureSql2.json"
New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "LS_AdventureWorksAzureSql2" -File "$ScriptPath\OutputPipelineScripts\LS_AdventureWorksAzureSql2.json"
$LS_ADLSV2Definition = @"
{      "name": "$5_ADLSv2LinkedServiceName",      "properties": {          "annotations": [],          "type": "AzureBlobFS",          "typeProperties": {              "url": "$5_URL"          },          "connectVia": {              "referenceName": "$5_nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }
"@
$LS_ADLSV2Definition | Out-File "$ScriptPath\OutputPipelineScripts\LS_ADLSV2.json"
New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "LS_ADLSV2" -File "$ScriptPath\OutputPipelineScripts\LS_ADLSV2.json"
#Code for creating/updating pipeline datasets
$DS_azureADLSv2DataSet_1_5Definition = @"
{    "name": "$3_1_azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$3_1_ADLSV2LinkedServiceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$3_1_fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,'.',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$3_1_fileSystemFolderName"        },        "columnDelimiter": "@dataset().columndelimiter",        "compressionCodec": "$3_1_CompressionCodectype" ,"firstRowAsHeader": true     },      "schema": []    }  }
"@
$DS_azureADLSv2DataSet_1_5Definition | Out-File "$ScriptPath\OutputPipelineScripts\DS_azureADLSv2DataSet_1_5.json"
New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "DS_CP_SINK_DataCopy_1" -File "$ScriptPath\OutputPipelineScripts\DS_azureADLSv2DataSet_1_5.json"
$DS_azureSQLDatabaseDataset_1_8Definition = @"
{  "name": "$2_1_azureSQLDatabaseDatasetName",  "properties": {    "type": "AzureSqlTable",    "linkedServiceName": {      "referenceName": "$2_1_azureSQLDatabaseLinkedServiceName", "type": "LinkedServiceReference"},  "typeProperties": { "tableName": "dummy" }}}
"@
$DS_azureSQLDatabaseDataset_1_8Definition | Out-File "$ScriptPath\OutputPipelineScripts\DS_azureSQLDatabaseDataset_1_8.json"
New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "DS_CP_SRC_DataCopy_1" -File "$ScriptPath\OutputPipelineScripts\DS_azureSQLDatabaseDataset_1_8.json"
$DS_azureSQLDatabaseDataset_1_8Definition = @"
{  "name": "$1_1_azureSQLDatabaseDatasetName",  "properties": {    "type": "AzureSqlTable",    "linkedServiceName": {      "referenceName": "$1_1_azureSQLDatabaseLinkedServiceName", "type": "LinkedServiceReference"},  "typeProperties": { "tableName": "dummy" }}}
"@
$DS_azureSQLDatabaseDataset_1_8Definition | Out-File "$ScriptPath\OutputPipelineScripts\DS_azureSQLDatabaseDataset_1_8.json"
New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "DS_LKP_1" -File "$ScriptPath\OutputPipelineScripts\DS_azureSQLDatabaseDataset_1_8.json"
#Code for creating/updating master pipeline code i.e sendmail
$sendmailpipelineDefinition = @"
  {      "name": "$sendmailMasterPipelineName",      "properties": {          "activities": [                {                  "name": "Sendmail",                  "type": "WebActivity",                  "dependsOn": [],                   "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                        "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },  "userProperties": [],                  "typeProperties": {                      "url": "$LogicAppURL",                        "method": "POST",                      "headers": {                          "Content-type": "application/json"                      },  "body": $body                  }              }          ],          "parameters": {               "EmailTo": {                  "type": "string"              },                "Activity": {                  "type": "string"              },                "Message": {                  "type": "string"              } ,  "PipelineName": {                  "type": "string"              }   },          "annotations": []      }  }    
"@
$sendmailpipelineDefinition | Out-File "$ScriptPath\OutputPipelineScripts\sendmail.json"
New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $sendmailMasterPipelineName -Force -File "$ScriptPath\OutputPipelineScripts\sendmail.json"
#Code for creating/updating master pipeline activity code
$pipelineDefinition = @"
{
"name": "$pipelinename",
"properties": {
"activities": [
{"name":"$SPPipelineInprogressActivity_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SPPipelineInprogressActivity_dependson","dependencyConditions":["$SPPipelineInprogressActivity_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SPPipelineInprogressActivity_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SPPipelineInprogressActivity_SPName","storedProcedureParameters":$SPPipelineInprogressActivity_SPParameters}}}
,{"name":"$SPPipelineFailedActivity1_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SPPipelineFailedActivity1_dependson","dependencyConditions":["$SPPipelineFailedActivity1_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SPPipelineFailedActivity1_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SPPipelineFailedActivity1_SPName","storedProcedureParameters":$SPPipelineFailedActivity1_SPParameters}}}
,{"name":"$LKP_1_LookupActivityname","type":"Lookup","dependsOn":[{"activity":"$LKP_1_dependson","dependencyConditions":["$LKP_1_dependencyConditions"]}],"policy":{"timeout":"7.00:00:00","retry":0,"retryIntervalInSeconds":30,"secureOutput":false,"secureInput":false},"userProperties":[],"typeProperties":{"source":{"type":"AzureSqlSource","sqlReaderQuery":{"value":"$LKP_1_query","type":"Expression"},"queryTimeout":"02:00:00"},"dataset":{"referenceName":"$LKP_1_dataset","type":"DatasetReference"},"firstRowOnly":$LKP_1_firstrow}}
,{"name":"$SPPipelineFailedActivity2_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SPPipelineFailedActivity2_dependson","dependencyConditions":["$SPPipelineFailedActivity2_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SPPipelineFailedActivity2_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SPPipelineFailedActivity2_SPName","storedProcedureParameters":$SPPipelineFailedActivity2_SPParameters}}}
,{"name":"$SPPipelineFailedActivity3_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SPPipelineFailedActivity3_dependson","dependencyConditions":["$SPPipelineFailedActivity3_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SPPipelineFailedActivity3_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SPPipelineFailedActivity3_SPName","storedProcedureParameters":$SPPipelineFailedActivity3_SPParameters}}}
,{"name":"$SPPipelineSucceededActivity_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SPPipelineSucceededActivity_dependson","dependencyConditions":["$SPPipelineSucceededActivity_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SPPipelineSucceededActivity_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SPPipelineSucceededActivity_SPName","storedProcedureParameters":$SPPipelineSucceededActivity_SPParameters}}}
,{"name":"$Foreach_SourceEntity_1_foreachactivityname","type":"ForEach","dependsOn":[{"activity":"$Foreach_SourceEntity_1_dependson","dependencyConditions":["$Foreach_SourceEntity_1_dependencyConditions"]}],"userProperties":[],"typeProperties":{"items":{"value":"@activity('$Foreach_SourceEntity_1_dependentactivityname').output.value","type":"Expression"},"batchCount":$Foreach_SourceEntity_1_batchCount,"isSequential":$Foreach_SourceEntity_1_isSequential,"activities":[{"name":"$FE_LKP_LookupActivityname","type":"Lookup","dependsOn":[{"activity":"$FE_LKP_dependson","dependencyConditions":["$FE_LKP_dependencyConditions"]}],"policy":{"timeout":"7.00:00:00","retry":0,"retryIntervalInSeconds":30,"secureOutput":false,"secureInput":false},"userProperties":[],"typeProperties":{"source":{"type":"AzureSqlSource","sqlReaderQuery":{"value":"$FE_LKP_query","type":"Expression"},"queryTimeout":"02:00:00"},"dataset":{"referenceName":"$FE_LKP_dataset","type":"DatasetReference"},"firstRowOnly":$FE_LKP_firstrow}},{"name":"$FE_LKP_CNT_LookupActivityname","type":"Lookup","dependsOn":[{"activity":"$FE_LKP_CNT_dependson","dependencyConditions":["$FE_LKP_CNT_dependencyConditions"]}],"policy":{"timeout":"7.00:00:00","retry":0,"retryIntervalInSeconds":30,"secureOutput":false,"secureInput":false},"userProperties":[],"typeProperties":{"source":{"type":"AzureSqlSource","sqlReaderQuery":{"value":"$FE_LKP_CNT_query","type":"Expression"},"queryTimeout":"02:00:00"},"dataset":{"referenceName":"$FE_LKP_CNT_dataset","type":"DatasetReference"},"firstRowOnly":$FE_LKP_CNT_firstrow}},{"name":"$IfCondition_ifactivityname","type":"IfCondition","dependsOn":[{"activity":"$IfCondition_dependson","dependencyConditions":["$IfCondition_dependencyConditions"]}],"userProperties":[],"typeProperties":{"expression":{"value":"@greater(int(activity('FE_LKP_CNT').output.firstRow.cnt),0)","type":"Expression"},"ifFalseActivities":[{"name":"$SP_CopyActivityLoggingNoDeltaRecords_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SP_CopyActivityLoggingNoDeltaRecords_dependson","dependencyConditions":["$SP_CopyActivityLoggingNoDeltaRecords_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SP_CopyActivityLoggingNoDeltaRecords_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SP_CopyActivityLoggingNoDeltaRecords_SPName","storedProcedureParameters":$SP_CopyActivityLoggingNoDeltaRecords_SPParameters}}],"ifTrueActivities":[{"name":"$CP_1_CopyActivityName","type":"Copy","dependsOn":[{
"activity":"$CP_1_dependson",
"dependencyConditions":["$CP_1_dependencyConditions"]
}],"policy":{"timeout":"7.00:00:00","retry":0,"retryIntervalInSeconds":30,"secureOutput":false,"secureInput":false},"userProperties":[],"typeProperties":{"source":{"type":"$CP_1_Source","sqlReaderQuery":{"value":"$CP_1_sqlReaderQuery","type":"Expression"},"queryTimeout":"02:00:00"},"sink":{"type":"$CP_1_Sink","storeSettings":{"type":"AzureBlobFSWriteSettings"}},"enableStaging":false},"inputs":[{"referenceName":"$CP_1_inputDatasetReference","type":"DatasetReference"}],"outputs":[{"referenceName":"$CP_1_outputDatasetReference","type":"DatasetReference","parameters":{$CP_1_parameters}}]},{"name":"$SP_CopyActivityLogging_SPActivityName","description":"Description","type":"SqlServerStoredProcedure","dependsOn":[{"activity":"$SP_CopyActivityLogging_dependson","dependencyConditions":["$SP_CopyActivityLogging_dependencyConditions"]}],"linkedServiceName":{"referenceName":"$SP_CopyActivityLogging_MetadataDBLinkedServiceName","type":"LinkedServiceReference"},"typeProperties":{"storedProcedureName":"$SP_CopyActivityLogging_SPName","storedProcedureParameters":$SP_CopyActivityLogging_SPParameters}},{
"name":"$SP_MaxRefreshUpdate_SPActivityName",
"description":"Description",
"type":"SqlServerStoredProcedure",
"dependsOn":[
{
"activity":"$SP_MaxRefreshUpdate_dependson",
"dependencyConditions":["$SP_MaxRefreshUpdate_dependencyConditions"]
}
],
"linkedServiceName":{
"referenceName":"$SP_MaxRefreshUpdate_MetadataDBLinkedServiceName",
"type":"LinkedServiceReference"
},
"typeProperties":{
"storedProcedureName":"$SP_MaxRefreshUpdate_SPName",
"storedProcedureParameters":$SP_MaxRefreshUpdate_SPParameters
}
}
]}}]}}
, {
                "name": "Execute Send Mail for failed activity 29",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "SPPipelineFailedActivity1",
                        "dependencyConditions": ["Succeeded"]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "Sendmail",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true,
                    "parameters": {
					"EmailTo": "$EmailTo",
                        "Activity": "sppipelineinprogressactivity",
                        "Message": "failed at activity sppipelineinprogressactivity",
						"PipelineName": "AdvWorks_From_AzureSqldb_To_ADLS_1"
				}
                }
            }
        
, {
                "name": "Execute Send Mail for failed activity 31",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "SPPipelineFailedActivity2",
                        "dependencyConditions": ["Succeeded"]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "Sendmail",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true,
                    "parameters": {
					"EmailTo": "$EmailTo",
                        "Activity": "lkp1",
                        "Message": "failed at activity lkp1",
						"PipelineName": "AdvWorks_From_AzureSqldb_To_ADLS_1"
				}
                }
            }
        
, {
                "name": "Execute Send Mail for failed activity 42",
                "type": "ExecutePipeline",
                "dependsOn": [
                    {
                        "activity": "SPPipelineFailedActivity3",
                        "dependencyConditions": ["Succeeded"]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "Sendmail",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true,
                    "parameters": {
					"EmailTo": "$EmailTo",
                        "Activity": "foreachsourceentity1",
                        "Message": "failed at activity foreachsourceentity1",
						"PipelineName": "AdvWorks_From_AzureSqldb_To_ADLS_1"
				}
                }
            }
        
]
}
}
"@
$pipelineDefinition | Out-File "$ScriptPath\OutputPipelineScripts\AdvWorks_From_AzureSqldb_To_ADLS_1.json"
New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name $pipelinename -File "$ScriptPath\OutputPipelineScripts\$pipelinename.json"
Stop-Transcript 
