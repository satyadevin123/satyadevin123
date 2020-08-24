/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
Print 'Start - Inserting data to master parameters list table'

INSERT INTO [dbo].[T_Master_Parameters_List] ( ParameterName, ParameterValue)
VALUES 
('$resourceGroupName',''),
('$dataFactoryName',''),
('$subscriptionid',''),
('$dataFactoryNameLocation',''),
('$tenantid',''),
('$sendmailMasterPipelineName',''),
('$finalouput',''),
('$azuredeployparametersjson',''),
('$nameofintegrationruntime',''),
('$SinkAccountName','')

Print 'End - Inserting data to master parameters list table'

GO

Print 'Start - Inserting data to master pipelines table'

INSERT INTO [dbo].[T_Master_Pipelines]
(Id, MasterPipelineName, Enabled, JsonCode)
VALUES
(1,'sendmail',1,'  {      "name": "$sendmailMasterPipelineName",      "properties": {          "activities": [                {                  "name": "Sendmail",                  "type": "WebActivity",                  "dependsOn": [],                   "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                        "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },  "userProperties": [],                  "typeProperties": {                      "url": "$LogicAppURL",                        "method": "POST",                      "headers": {                          "Content-type": "application/json"                      },  "body": $body                  }              }          ],          "parameters": {               "EmailTo": {                  "type": "string"              },                "Activity": {                  "type": "string"              },                "Message": {                  "type": "string"              } ,  "PipelineName": {                  "type": "string"              }   },          "annotations": []      }  }    ')

Print 'End - Inserting data to master pipelines table'
GO

Print 'Start - Inserting data to master pipelines parameters table'
INSERT INTO [dbo].[T_Master_Pipelines_Parameters_List]
(Id, ParameterName, ParameterValue,MasterPipelineId)
VALUES
(1,'$LogicAppURL','"https://prod-91.eastus.logic.azure.com:443/workflows/687c06941f5f4b2694402fb9f0cfd4f7/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=_lxKCk_SSJGvx8WZ05-TkfVmeKOD0DqpCzklFByuK48"',1),
(2,'$body','''"{\"EmailTo\": \"@{pipeline().parameters.EmailTo}\",  \"Subject\": \"An error has occured in the @{pipeline().parameters.PipelineName}-pipeline\",  \"DataFactoryName\": \"@{pipeline().DataFactory}\",  \"PipelineName\": \"@{pipeline().parameters.PipelineName}\",  \"Activity\": \"@{pipeline().parameters.Activity}\",  \"Message\": \"@{pipeline().parameters.Message}\"}"''',1),
(3,'$EmailTo','',1),
(4,'$Activity','""',1),
(5,'$PipelineEndedMessage','"The $Pipeline is Ended"',1),
(6,'$PipelineStartedMessage','"The $Pipeline is Started"',1)

Print 'End - Inserting data to master pipelines parameters table'
GO

Print 'Start - Inserting data to list datasources table'


INSERT INTO [dbo].[T_List_DataSources]
( DataSource_name,created_date,source_Type,source_metadata_query)
VALUES
('On Premise SQLServer',getdate(),'SqlServer','DECLARE @version VARCHAR(1000) =            (                SELECT @@version            );    DECLARE @Tables TABLE    (        sql_ServerName NVARCHAR(128),        sql_TableSchema_type NVARCHAR(128),        sql_TableName_Full NVARCHAR(256),        sql_Table_Catalog NVARCHAR(128),        sql_Table_Schema NVARCHAR(128),        sql_Table_Name NVARCHAR(128),        sql_Column_Name NVARCHAR(128),        sql_Ordinal_Position INT,        sql_Is_Nullable VARCHAR(3),        sql_Data_Type NVARCHAR(128),        sql_Character_Maximum_Length INT,        sql_isPrimaryKey INT    );        INSERT INTO @Tables    (        sql_ServerName ,        sql_TableSchema_type ,        sql_TableName_Full ,        sql_TABLE_CATALOG,        sql_TABLE_SCHEMA ,        sql_TABLE_NAME ,        sql_Column_Name  ,        sql_Ordinal_Position ,        sql_Is_Nullable ,        sql_Data_Type  ,        sql_Character_Maximum_Length,     sql_isPrimaryKey      )      SELECT DISTINCT           @@SERVERNAME src_ServerName,           t.type_desc AS src_TableSchema_type,           ''['' + s.name + '']'' + ''.['' + t.name + '']'' COLLATE DATABASE_DEFAULT AS src_TableName_Full,           c.TABLE_CATALOG,           c.TABLE_SCHEMA,           c.TABLE_NAME,           c.COLUMN_NAME,           c.ORDINAL_POSITION,           c.IS_NULLABLE,           c.DATA_TYPE,           c.CHARACTER_MAXIMUM_LENGTH,           ISNULL(CAST(ix.is_primary_key AS INT), 0) is_primary_key               FROM    (        SELECT name,               type_desc,               schema_id,               t.object_id        FROM sys.tables t        UNION        SELECT name,               type_desc,               schema_id,               v.object_id        FROM sys.views v    ) t        JOIN sys.schemas s            ON t.schema_id = s.schema_id        JOIN INFORMATION_SCHEMA.COLUMNS c            ON c.TABLE_NAME = t.name COLLATE DATABASE_DEFAULT               AND c.TABLE_SCHEMA = s.name        JOIN sys.columns co            ON co.object_id = t.object_id               AND co.name = c.COLUMN_NAME        JOIN sys.types ty            ON co.user_type_id = ty.user_type_id        LEFT JOIN        (            SELECT ic.object_id,                   ic.index_id,                   ic.index_column_id,                   ic.column_id,                   i.is_primary_key            FROM sys.index_columns ic                JOIN sys.indexes i                    ON i.index_id = ic.index_id                       AND i.object_id = ic.object_id            WHERE  i.is_primary_key = 1        ) ix            ON ix.object_id = co.object_id               AND ix.column_id = co.column_id    WHERE c.TABLE_CATALOG NOT IN ( ''master'', ''tempdb'', ''msdb'', ''model'' )    SELECT * FROM @Tables ;'),
('AzureDataLakeStorageV2',getdate(),'ADLSV2','')

Print 'End - Inserting data to list datasources table'
GO

Print 'Start - Inserting data to list linkedservices table'

INSERT INTO [dbo].[T_List_LinkedServices]
(Id, LinkedService_Name, DataSource_Id, Jsoncode)
VALUES
(1,'azureSQLDatabase',1,'  {      "name": "$azureSqlDatabaseLinkedServiceName",    "properties": {          "type": "AzureSqlDatabase",      "typeProperties": {            "connectionString": {                  "type": "SecureString",              "value": "Server=tcp:$azureSqlDBServerName.database.windows.net,1433;Database=$azureSqlDatabaseName;  User ID=$azureSqlDBUserName;Password=$azureSqlDBPassword;Trusted_Connection=False;Encrypt=True;Connection Timeout=30"  }          } ,  "connectVia": {              "referenceName": "$nameofintegrationruntime",             "type": "IntegrationRuntimeReference"          }  }  }  '),
(2,'azureSQLDataWarehouse',2,'{      "name": "$azureSqlDataWarehouseLinkedServiceName",      "properties": {          "type": "AzureSqlDW",          "typeProperties": {              "connectionString": {                  "type": "SecureString",                  "value": "Server=tcp:$azureSqlDWServerName.database.windows.net,1433;Database=$azureSqlDWDBName;Integrated Security=False;Encrypt=True;Connection Timeout=30"              }          }      }  }'),
(3,'ADLSv2',3,'{      "name": "$ADLSv2LinkedServiceName",      "properties": {          "annotations": [],          "type": "AzureBlobFS",          "typeProperties": {              "url": "$URL"          },          "connectVia": {              "referenceName": "$nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }'),
(4,'AzureBlobStorage',4,'{      "name": "$AzureBlobStorageLinkedServiceName" ,     "properties": {          "type": "AzureBlobStorage",          "typeProperties": {              "connectionString": "DefaultEndpointsProtocol=https;AccountName=$AccountName;AccountKey=$AccountKey"          },          "connectVia": {              "referenceName": "$nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }'),
(5,'OnPremsieSQLServer',1,'{      "name": "$OnPremiseSQLServerLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": { "type": "SqlServer",          "typeProperties": {              "connectionString": "integrated security=False;data source=DESKTOP-T6TT297;initial catalog=Test;user id=sa",              "encryptedCredential": "eyJDcmVkZW50aWFsSWQiOiJlYmNkNjg1MS05NzY0LTQyNDQtYWZmNy04NGU0ZWM5NTlhMjEiLCJWZXJzaW9uIjoiMi4wIiwiQ2xhc3NUeXBlIjoiTWljcm9zb2Z0LkRhdGFQcm94eS5Db3JlLkludGVyU2VydmljZURhdGFDb250cmFjdC5DcmVkZW50aWFsU1UwNkNZMTQifQ=="          },          "connectVia": {              "referenceName": "$IRName",              "type": "IntegrationRuntimeReference"          }      }  }'),
(6,'azureSQLDatabasewithManagedIdentity',1,'     { "name": "$azureSqlDatabaseLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "AzureSqlDatabase",          "typeProperties": {              "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$azureSqlDBServerName.database.windows.net;Initial Catalog=$azureSqlDatabaseName"          }      }  }')

Print 'End - Inserting data to list linkedservices table'

GO

Print 'Start - Inserting data to list linked service parameters table'

INSERT INTO [dbo].[T_List_LinkedService_Parameters]
(Id, ParameterName, ParameterValue, LinkedServiceId)
VALUES
(1,'$azureSqlDatabaseLinkedServiceName','AzureSQLDatabase',1),
(2,'$azureSqlDBServerName','',1),
(3,'$azureSqlDatabaseName','',1),
(4,'$azureSqlDBUserName','',1),
(5,'$azureSqlDBPassword','',1),
(6,'$AccountName','',4),
(7,'$AccountKey','',4),
(24,'$nameofintegrationruntime','',1),
(9,'$AzureBlobStorageLinkedServiceName','',4),
(10,'$OnPremiseSQLServerLinkedServiceName','',5),
(11,'$IRName','IR-SelfHosted',5),
(12,'$azureSqlDataWarehouseLinkedServiceName','',2),
(13,'$azureSqlDWServerName','',2),
(14,'$azureSqlDWDBName','',2),
(15,'$azureSqlDWUserName','',2),
(16,'$azureSqlDWUserPassword','',2),
(17,'$ADLSv2LinkedServiceName','',3),
(18,'$ADLSv2AccountName','',3),
(19,'$URL','',3),
(25,'$nameofintegrationruntime','',3),
(21,'$azureSqlDatabaseLinkedServiceName','',6),
(22,'$azureSqlDBServerName','',6),
(23,'$azureSqlDatabaseName','',6)

Print 'End - Inserting data to list linked service parameters table'
GO

Print 'Start - Inserting data to list datasets table'

INSERT INTO [dbo].[T_List_DataSets]
(Id, DataSet_name, LinkedService_id, created_date,JsonCode,DataSetStandardName,AdditionalConfigurationType,AdditionalConfigurationValue)
VALUES
(1,'azureSqlDatabaseDataset',1,getdate(),'{"name": "$azureSqlDatabaseDatasetName","properties": {"type": "AzureSqlTable","linkedServiceName": {"referenceName": "$azureSqlDatabaseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSqlDatabaseDataset',NULL,NULL),
(2,'azureSqlDataWarehouseDataset',2,getdate(),'{"name": "$azureSqlDWDatasetName","properties": {"type": "AzureSqlDWTable","linkedServiceName": {"referenceName": "$azureSqlDataWarehouseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSqlDataWarehouseDataset',NULL,NULL),
(3,'azureADLSv2DataSet',3,getdate(),'{    "name": "$azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileformat)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        },        "compressionCodec": "$CompressionCodectype"      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Parquet'),
(4,'azureBlobStorageDataSet',4,getdate(),'{      "name": "$azureBlobDataSetName",      "properties": {          "linkedServiceName": {              "referenceName": "$AzureBlobStorageLinkedServiceName",              "type": "LinkedServiceReference"          },          "annotations": [],          "type": "DelimitedText",          "typeProperties": {              "location": {                  "type": "AzureBlobFSLocation",                  "fileSystem": "$fileslocation"              },              "columnDelimiter": ",",              "escapeChar": "\\",              "firstRowAsHeader": "true",              "quoteChar": "\""          },          "schema": []      }  }','azureBlobStorageDataSet',NULL,NULL),
(5,'azureADLSv2DataSet',3,getdate(),'{    "name": "$azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        },        "columnDelimiter": "@dataset().columndelimiter",        "compressionCodec": "$CompressionCodectype"      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
(6,'azureADLSv2DataSet',3,getdate(),'{  "name": "$azureADLSV2DataSetName",  "properties": {    "linkedServiceName": {      "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        }      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Json'),
(7,'azureADLSv2DataSet',3,getdate(),'{  "name": "$azureADLSV2DataSetName",  "properties": {    "linkedServiceName": {      "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        }      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Avro')


Print 'End - Inserting data to list datasets table'
GO

Print 'Start - Inserting data to list datasets parameters table'

INSERT INTO [dbo].[T_List_Dataset_Parameters]
(Id, ParameterName, ParameterValue, DatasetId)
VALUES
(1,'$azureADLSV2DataSetName','DS_POC_ADLS',3),
(2,'$LInkedServerReferneceName','',3),
(3,'$azureSqlDWDatasetName','DS_POC_DWH',2),
(4,'$azureSqlDatabaseDatasetName','DS_POC_AzureSQL',1),
(5,'$azureBlobDataSetName','DS_AzureBlob',4),
(6,'$fileSystemFolderName','',3),
(7,'$CompressionCodectype','snappy',3),
(8,'$fileformat','',3),
(9,'$fileextension','',3),
(10,'$azureADLSV2DataSetName','DS_POC_ADLS',5),
(11,'$LInkedServerReferneceName','',5),
(12,'$fileSystemFolderName','',5),
(13,'$CompressionCodectype','snappy',5),
(14,'$fileformat','',5),
(15,'$fileextension','',5),
(16,'$ColumnDelimiter',',',5)

Print 'End - Inserting data to list datasets parameters table'
GO


Print 'Start - Inserting data to list activities table'

INSERT INTO [dbo].[T_List_Activities]
(Id, ActivityName, ActivityStandardName,Enabled,code,linkedserverrequired,datasetrequired)
VALUES
(1,'Execute Pipeline','Exe_Pipeline',1,'{                  "name": "ExecutePipelineActivity",                  "type": "ExecutePipeline",                  "typeProperties": {                      "parameters": {                                                  "mySourceDatasetFolderPath": {                              "value": "@pipeline().parameters.mySourceDatasetFolderPath",                              "type": "Expression"                          }                      },                      "pipeline": {                          "referenceName": "<InvokedPipelineName>",                          "type": "PipelineReference"                      },                      "waitOnCompletion": true                   }              }          ],          "parameters": [              {                  "mySourceDatasetFolderPath": {                      "type": "String"                  }              }',NULL,NULL),
(2,'Lookup Activity','LKP_DataSource_Name',1,'{                  "name": "$LookupActivityname",                  "type": "Lookup",                  "dependsOn": [],                  "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                      "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },                  "userProperties": [],                  "typeProperties": {                      "source": {                          "type": "AzureSqlSource",                          "sqlReaderQuery": {                              "value": "$query",                              "type": "Expression"                          },                          "queryTimeout": "02:00:00"                      },                      "dataset": {                          "referenceName": "$dataset",                          "type": "DatasetReference"                      },                      "firstRowOnly": $firstrow                  }              }',NULL,1),
(3,'Copy Activity','CP_DataSource_DataDestination',1,'{"name": "$CopyActivityName","type": "Copy","dependsOn": [],"policy": {    "timeout": "7.00:00:00",    "retry": 0,    "retryIntervalInSeconds": 30,    "secureOutput": false,    "secureInput": false},"userProperties": [],"typeProperties": {    "source": {        "type": "$Source",        "sqlReaderQuery": {            "value": "$sqlReaderQuery",            "type": "Expression"        },        "queryTimeout": "02:00:00"    },    "sink": {        "type": "$Sink",        "storeSettings": {            "type": "AzureBlobFSWriteSettings"        }    },    "enableStaging": false},"inputs": [    {        "referenceName": "$inputDatasetReference",        "type": "DatasetReference"    }],"outputs": [    {        "referenceName": "$outputDatasetReference",        "type": "DatasetReference",        "parameters": {            $parameters            }        }    ]                          }',NULL,1),
(4,'For Each Activity','ForEachActivity',1,'   {                  "name": "$foreachactivityname",                  "type": "ForEach",                  "dependsOn": [                      {                          "activity": "$dependson",                          "dependencyConditions": [                              "$dependencyConditions"                          ]                      }                  ],                  "userProperties": [],                  "typeProperties": {                      "items": {                          "value": "@activity(''$dependentactivityname'').output.value",                          "type": "Expression"                      },                      "batchCount": $batchCount,       "isSequential": $isSequential,       "activities": [$activityjsoncode]                         }              }',NULL,NULL),
(5,'Wait Activity','Wait',1,'{     "name":"Wait1",     "type":"Wait",     "dependsOn":[       ],     "userProperties":[        {           "name":"Description",           "value":"Wait time for 30 seconds"        }     ],     "typeProperties":{        "waitTimeInSeconds":30     }  } ',NULL,NULL),
(6,'Filter Activity','FilterActivity',1,'{   "name": "MyFilterActivity",   "type": "filter",   "typeProperties": {    "condition": "$condition",    "items": "$inputarray"   }  }',NULL,NULL),
(7,'Get Metadata Activity','Metadata Activity',1,'{   "name": "$Metadataactivityname",   "type": "GetMetadata",   "typeProperties": {    "fieldList" : "$filedlist",    "dataset": {     "referenceName": "$MyDataset",     "type": "DatasetReference"    }   }  }',NULL,NULL),
(8,'If Activity','IfActivity',1,'{      "name": "$Name_of_the_activity>",      "type": "IfCondition",      "typeProperties": {        "expression": {              "value": "$expression_that_evaluates_to_trueorfalse>",              "type": "Expression"        },          "ifTrueActivities": [              {                  "Activity 1 definition>"              },              {                  "<Activity 2 definition>"              },              {                  "<Activity N definition>"              }          ],            "ifFalseActivities": [              {                  "<Activity 1 definition>"              },              {                  "<Activity 2 definition>"              },              {                  "<Activity N definition>"              }        ]      }  }',NULL,NULL),
(9,'Custom Logging','SP_Custom_Logging',1,'{      "name": "Stored Procedure Activity",      "description":"Description",      "type": "SqlServerStoredProcedure",      "linkedServiceName": {          "referenceName": "AzureSqlLinkedService",          "type": "LinkedServiceReference"      },      "typeProperties": {          "storedProcedureName": "$SPName",          "storedProcedureParameters": "$SPParameters"            }      }  }','1',NULL)


Print 'End - Inserting data to list activities table'

GO


Print 'Start - Inserting data to list activity parameters table'

INSERT INTO [dbo].[T_List_Activity_Parameters]
(Id, ParameterName, ParameterValue,ActivityId)
VALUES
(1,'InvokedPipelineName','',1),
(2,'condition','',6),
(3,'inputarray','',6),
(4,'isSequential','FALSE',4),
(5,'Metadataactivityname','',7),
(6,'filedlist','',7),
(7,'MyDataset','',7),
(8,'Name_of_the_activity','',8),
(9,'LookupActivityname','',2),
(10,'query','select SS.Name as Schema_Name, ST.Name as Table_Name FROM SYS.TABLES ST JOIN SYS.SCHEMAS SS ON SS.schema_id= ST.schema_id',2),
(11,'dataset','',2),
(12,'firstrow','FALSE',2),
(13,'foreachactivityname','',4),
(14,'dependson','',4),
(15,'dependencyConditions','',4),
(16,'dependentactivityname','',4),
(17,'batchCount','20',4),
(18,'activityjsoncode','',4),
(19,'dependson','',2),
(20,'CopyActivityName','CP_SqlServer_ADLSParquet',3),
(21,'Source','AzureSqlSource',3),
(22,'Sink','ParquetSink',3),
(23,'inputDatasetReference','',3),
(24,'outputDatasetReference','',3),
(25,'parameters','       ""filename"": ""@item().table_name"",                                          ""directory"": ""@item().table_name"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter""',3),
(26,'sqlReaderQuery','@concat(''select * from '',''['',item().schema_name,'']'',''.'',''['',item().table_name,'']'')',3),
(27,'$SPName','usp_Log_PipelineStatus',9)

Print 'End - Inserting data to list activity parameters table'

GO