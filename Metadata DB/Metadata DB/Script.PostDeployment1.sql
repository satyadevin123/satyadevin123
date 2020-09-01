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
--*/
--Print 'Start - Change pricing tier to basic'
--DECLARE @CurrentDBName NVARCHAR(100)
--DECLARE @Sql NVARCHAR(1000)

--SELECT @CurrentDBName = DB_NAME() 

--USE MASTER
--SET @Sql = 'ALTER DATABASE '+@CurrentDBName +' MODIFY (EDITION =''Basic'')';

--exec sp_executesql @Sql

--Print 'end - Change pricing tier to basic'
--GO

--SET @Sql = 'USE '+@CurrentDBName

--exec sp_executesql @Sql

Print 'Start - Inserting data to master parameters list table'

DECLARE @Mastertable as TABLE
( ParameterName NVARCHAR(200), ParameterValue NVARCHAR(200))
INSERT INTO @Mastertable ( ParameterName, ParameterValue)
VALUES 
('$resourceGroupName',''),
('$dataFactoryName',''),
('$subscriptionid',''),
('$dataFactoryNameLocation',''),
('$tenantid',''),
('$sendmailMasterPipelineName','"sendmail"'),
('$finalouput','"pocmeta"'),
('$azuredeployparametersjson',''),
('$nameofintegrationruntime','"Azure-IR-ADF"'),
('$SinkAccountName',''),
('$keyvaultname',''),
('$keyvaultlocation','')

MERGE [T_Master_Parameters_List] AS mrg
USING (SELECT * FROM @Mastertable) AS src
ON mrg.ParameterName = src.ParameterName
WHEN MATCHED THEN 
   UPDATE SET mrg.ParameterValue = src.ParameterValue
WHEN NOT MATCHED THEN
INSERT (ParameterName
           ,ParameterValue
           )
VALUES(src.ParameterName
           ,src.ParameterValue
           );

Print 'End - Inserting data to master parameters list table'

GO

Print 'Start - Inserting data to master pipelines table'

DECLARE @SrcMasterPipelines as TABLE
( MasterPipelineName NVARCHAR(200), Enabled int,JsonCode NVARCHAR(max))

INSERT INTO @SrcMasterPipelines
( MasterPipelineName, Enabled, JsonCode)
VALUES
('sendmail',1,'  {      "name": "$sendmailMasterPipelineName",      "properties": {          "activities": [                {                  "name": "Sendmail",                  "type": "WebActivity",                  "dependsOn": [],                   "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                        "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },  "userProperties": [],                  "typeProperties": {                      "url": "$LogicAppURL",                        "method": "POST",                      "headers": {                          "Content-type": "application/json"                      },  "body": $body                  }              }          ],          "parameters": {               "EmailTo": {                  "type": "string"              },                "Activity": {                  "type": "string"              },                "Message": {                  "type": "string"              } ,  "PipelineName": {                  "type": "string"              }   },          "annotations": []      }  }    ')

MERGE [T_Master_Pipelines] AS mrg
USING (SELECT * FROM @SrcMasterPipelines) AS src
ON mrg.MasterPipelineName = src.MasterPipelineName
WHEN MATCHED THEN 
   UPDATE SET mrg.Enabled = src.Enabled,
   mrg.JsonCode = src.Jsoncode
WHEN NOT MATCHED THEN
INSERT (MasterPipelineName
           ,Enabled
           ,JsonCode
           )
VALUES(src.MasterPipelineName
           ,src.Enabled
           ,src.JsonCode
           );



Print 'End - Inserting data to master pipelines table'
GO

Print 'Start - Inserting data to master pipelines parameters table'



DECLARE @SrcMasterPipelinesparams as TABLE
(ParameterName NVARCHAR(255), ParameterValue VARCHAR (MAX),MasterPipelineName NVARCHAR(255))


INSERT INTO @SrcMasterPipelinesparams
( ParameterName, ParameterValue,MasterPipelineName)
VALUES
('$LogicAppURL','"https://prod-91.eastus.logic.azure.com:443/workflows/687c06941f5f4b2694402fb9f0cfd4f7/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=_lxKCk_SSJGvx8WZ05-TkfVmeKOD0DqpCzklFByuK48"','Sendmail'),
('$body','''"{\"EmailTo\": \"@{pipeline().parameters.EmailTo}\",  \"Subject\": \"An error has occured in the @{pipeline().parameters.PipelineName}-pipeline\",  \"DataFactoryName\": \"@{pipeline().DataFactory}\",  \"PipelineName\": \"@{pipeline().parameters.PipelineName}\",  \"Activity\": \"@{pipeline().parameters.Activity}\",  \"Message\": \"@{pipeline().parameters.Message}\"}"''','Sendmail'),
('$EmailTo','','Sendmail'),
('$Activity','""','Sendmail'),
('$PipelineEndedMessage','"The $Pipeline is Ended"','Sendmail'),
('$PipelineStartedMessage','"The $Pipeline is Started"','Sendmail')



MERGE [T_Master_Pipelines_Parameters_List] AS mrg
USING (SELECT s.*,m.Id FROM @SrcMasterPipelinesparams s 
    INNER JOIN 
    T_Master_Pipelines m 
    on s.MasterPipelineName = m.MasterPipelineName
    ) AS src
ON mrg.[MasterPipelineId] = src.Id
AND mrg.ParameterName = src.ParameterName
WHEN MATCHED THEN 
   UPDATE SET mrg.ParameterValue = src.ParameterValue
WHEN NOT MATCHED THEN
INSERT (ParameterName
           ,ParameterValue
           ,MasterPipelineId
           )
VALUES(src.ParameterName
           ,src.ParameterValue
           ,src.Id
           );


Print 'End - Inserting data to master pipelines parameters table'
GO

Print 'Start - Inserting data to list datasources table'

DECLARE @SrcDataSources as TABLE
( DataSource_name NVARCHAR(255), created_date date,source_Type VARCHAR(100),source_metadata_query varchar(max))

INSERT INTO @SrcDataSources
( DataSource_name,created_date,source_Type,source_metadata_query)
VALUES
('On Premise SQLServer',getdate(),'SqlServer','DECLARE @version VARCHAR(1000) =            (                SELECT @@version            );    DECLARE @Tables TABLE    (        sql_ServerName NVARCHAR(128),        sql_TableSchema_type NVARCHAR(128),        sql_TableName_Full NVARCHAR(256),        sql_Table_Catalog NVARCHAR(128),        sql_Table_Schema NVARCHAR(128),        sql_Table_Name NVARCHAR(128),        sql_Column_Name NVARCHAR(128),        sql_Ordinal_Position INT,        sql_Is_Nullable VARCHAR(3),        sql_Data_Type NVARCHAR(128),        sql_Character_Maximum_Length INT,        sql_isPrimaryKey INT    );        INSERT INTO @Tables    (        sql_ServerName ,        sql_TableSchema_type ,        sql_TableName_Full ,        sql_TABLE_CATALOG,        sql_TABLE_SCHEMA ,        sql_TABLE_NAME ,        sql_Column_Name  ,        sql_Ordinal_Position ,        sql_Is_Nullable ,        sql_Data_Type  ,        sql_Character_Maximum_Length,     sql_isPrimaryKey      )      SELECT DISTINCT           @@SERVERNAME src_ServerName,           t.type_desc AS src_TableSchema_type,           ''['' + s.name + '']'' + ''.['' + t.name + '']'' COLLATE DATABASE_DEFAULT AS src_TableName_Full,           c.TABLE_CATALOG,           c.TABLE_SCHEMA,           c.TABLE_NAME,           c.COLUMN_NAME,           c.ORDINAL_POSITION,           c.IS_NULLABLE,           c.DATA_TYPE,           c.CHARACTER_MAXIMUM_LENGTH,           ISNULL(CAST(ix.is_primary_key AS INT), 0) is_primary_key               FROM    (        SELECT name,               type_desc,               schema_id,               t.object_id        FROM sys.tables t        UNION        SELECT name,               type_desc,               schema_id,               v.object_id        FROM sys.views v    ) t        JOIN sys.schemas s            ON t.schema_id = s.schema_id        JOIN INFORMATION_SCHEMA.COLUMNS c            ON c.TABLE_NAME = t.name COLLATE DATABASE_DEFAULT               AND c.TABLE_SCHEMA = s.name        JOIN sys.columns co            ON co.object_id = t.object_id               AND co.name = c.COLUMN_NAME        JOIN sys.types ty            ON co.user_type_id = ty.user_type_id        LEFT JOIN        (            SELECT ic.object_id,                   ic.index_id,                   ic.index_column_id,                   ic.column_id,                   i.is_primary_key            FROM sys.index_columns ic                JOIN sys.indexes i                    ON i.index_id = ic.index_id                       AND i.object_id = ic.object_id            WHERE  i.is_primary_key = 1        ) ix            ON ix.object_id = co.object_id               AND ix.column_id = co.column_id    WHERE c.TABLE_CATALOG NOT IN ( ''master'', ''tempdb'', ''msdb'', ''model'' )    SELECT * FROM @Tables ;'),
('AzureDataLakeStorageV2',getdate(),'ADLSV2','')

MERGE [T_List_DataSources] AS mrg
USING (SELECT * FROM @SrcDataSources) AS src
ON mrg.DataSource_name = src.DataSource_name
AND mrg.source_Type = src.source_Type
WHEN MATCHED THEN 
   UPDATE SET mrg.source_metadata_query = src.source_metadata_query
WHEN NOT MATCHED THEN
INSERT (DataSource_name
           ,source_Type
           ,source_metadata_query
           )
VALUES(src.DataSource_name
           ,src.source_Type
           ,src.source_metadata_query
           );

Print 'End - Inserting data to list datasources table'
GO

Print 'Start - Inserting data to list linkedservices table'

DECLARE @SrcLinkedServices as TABLE
( LinkedService_Name VARCHAR(100), Jsoncode VARCHAR(4000))

INSERT INTO @SrcLinkedServices
( LinkedService_Name,Jsoncode)
VALUES
('azureSQLDatabase',' 
	 {
    "name": "$azureSqlDatabaseLinkedServiceName",
    "properties": {
        "type": "AzureSqlDatabase",
        "typeProperties": {
            "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$azureSqlDBServerName.database.windows.net;Initial Catalog=$azureSqlDatabaseName;User ID=$azureSqlDBUserName",
            "password": {
                "type": "AzureKeyVaultSecret",
                "store": {
                    "referenceName": "$azurekeyvaultlinkedservicereference",
                    "type": "LinkedServiceReference"
                },
                "secretName": "$azureSqlDBPassword"
            }
        },
        "connectVia": {
            "referenceName": "$nameofintegrationruntime",
            "type": "IntegrationRuntimeReference"
        }
    }} '),
('azureSQLDataWarehouse','{      "name": "$azureSqlDataWarehouseLinkedServiceName",      "properties": {          "type": "AzureSqlDW",          "typeProperties": {              "connectionString": {                  "type": "SecureString",                  "value": "Server=tcp:$azureSqlDWServerName.database.windows.net,1433;Database=$azureSqlDWDBName;Integrated Security=False;Encrypt=True;Connection Timeout=30"              }          }      }  }'),
('ADLSv2','{      "name": "$ADLSv2LinkedServiceName",      "properties": {          "annotations": [],          "type": "AzureBlobFS",          "typeProperties": {              "url": "$URL"          },          "connectVia": {              "referenceName": "$nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }'),
('AzureBlobStorage','{      "name": "$AzureBlobStorageLinkedServiceName" ,     "properties": {          "type": "AzureBlobStorage",          "typeProperties": {              "connectionString": "DefaultEndpointsProtocol=https;AccountName=$AccountName;AccountKey=$AccountKey"          },          "connectVia": {              "referenceName": "$nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }'),
('OnPremiseSQLServer','{      "name": "$OnPremiseSQLServerLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": { "type": "SqlServer",          "typeProperties":{              "connectionString": "Integrated Security=False;Data Source=$onpremSqlDBServerName;Initial Catalog=$onpremSqlDatabaseName;User ID=$onpremSqlDBUserName",               "password": {                  "type": "AzureKeyVaultSecret",                  "store": {                         "referenceName": "$azurekeyvaultlinkedservicereference",                      "type": "LinkedServiceReference"                  },      "secretName": "$onpremSqlDBPassword"              }          },           "connectVia": {              "referenceName": "$IRName",              "type": "IntegrationRuntimeReference"          }      }  }  '),
('azureSQLDatabasewithManagedIdentity','     { "name": "$azureSqlDatabaseLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "AzureSqlDatabase",          "typeProperties": {              "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$azureSqlDBServerName.database.windows.net;Initial Catalog=$azureSqlDatabaseName"          }      }  }'),
('azureKeyVault','{    "name": "$azureKeyVaultLinkedServiceName",    "properties": {        "annotations": [],        "type": "AzureKeyVault",       "typeProperties": {            "baseUrl": "https://$keyvaultname.vault.azure.net/"        }    }}')

MERGE [T_List_LinkedServices] AS mrg
USING (SELECT * FROM @SrcLinkedServices) AS src
ON mrg.LinkedService_Name = src.LinkedService_Name
WHEN MATCHED THEN 
   UPDATE SET mrg.Jsoncode = src.Jsoncode
WHEN NOT MATCHED THEN
INSERT (LinkedService_Name
           ,Jsoncode
           )
VALUES(src.LinkedService_Name
           ,src.Jsoncode
           );

Print 'End - Inserting data to list linkedservices table'

GO

Print 'Start - Inserting data to list linked service parameters table'

DECLARE @SrcLinkedServicesParameters as TABLE
( ParameterName VARCHAR(100), ParameterValue VARCHAR(500),LinkedServiceName VARCHAR (100))

INSERT INTO @SrcLinkedServicesParameters
( ParameterName,ParameterValue,LinkedServiceName)
VALUES
('$azureSqlDatabaseLinkedServiceName','AzureSQLDatabase','azureSQLDatabase'),
('$azureSqlDBServerName','','azureSQLDatabase'),
('$azureSqlDatabaseName','','azureSQLDatabase'),
('$azureSqlDBUserName','','azureSQLDatabase'),
('$azureSqlDBPassword','','azureSQLDatabase'),
('$azurekeyvaultlinkedservicereference','','azureSQLDatabase'),
('$AccountName','','AzureBlobStorage'),
('$AccountKey','','AzureBlobStorage'),
('$nameofintegrationruntime','','azureSQLDatabase'),
('$AzureBlobStorageLinkedServiceName','','AzureBlobStorage'),
('$OnPremiseSQLServerLinkedServiceName','','OnPremiseSQLServer'),
('$IRName','IR-SelfHosted','OnPremiseSQLServer'),
('$onpremSqlDBServerName','','OnPremiseSQLServer'),
('$onpremSqlDatabaseName','','OnPremiseSQLServer'),
('$onpremSqlDBUserName','','OnPremiseSQLServer'),
('$onpremSqlDBPassword','','OnPremiseSQLServer'),
('$azureSqlDataWarehouseLinkedServiceName','','azureSQLDataWarehouse'),
('$azureSqlDWServerName','','azureSQLDataWarehouse'),
('$azureSqlDWDBName','','azureSQLDataWarehouse'),
('$azureSqlDWUserName','','azureSQLDataWarehouse'),
('$azureSqlDWUserPassword','','azureSQLDataWarehouse'),
('$ADLSv2LinkedServiceName','','ADLSv2'),
('$ADLSv2AccountName','','ADLSv2'),
('$URL','','ADLSv2'),
('$nameofintegrationruntime','','ADLSv2'),
('$azureSQLDatabasewithManagedIdentityLinkedServiceName','','azureSQLDatabasewithManagedIdentity'),
('$azureSqlDBServerName','','azureSQLDatabasewithManagedIdentity'),
('$azureSqlDatabaseName','','azureSQLDatabasewithManagedIdentity'),
('$nameofintegrationruntime','','azureSQLDatabasewithManagedIdentity'),
('$azureKeyVaultLinkedServiceName','','azureKeyVault'),
('$keyvaultName','','azureKeyVault')


MERGE [T_List_LinkedService_Parameters] AS mrg
USING (
    SELECT S.*,t.Id FROM @SrcLinkedServicesParameters s
    INNER JOIN T_List_LinkedServices t
    ON s.LinkedServiceName = t.[LinkedService_Name]
      ) AS src
ON mrg.[LinkedServiceId] = src.Id
AND mrg.ParameterName = src.ParameterName
WHEN MATCHED THEN 
   UPDATE SET mrg.ParameterValue = src.ParameterValue
WHEN NOT MATCHED THEN
INSERT (ParameterName
           ,ParameterValue
           ,[LinkedServiceId]
           )
VALUES(src.ParameterName
           ,src.ParameterValue
           ,src.Id
           );

Print 'End - Inserting data to list linked service parameters table'
GO

Print 'Start - Inserting data to list datasets table'


DECLARE @SrcDatasets as TABLE
( [DataSet_name] NVARCHAR (255), [LinkedServiceName] NVARCHAR (255),
    [Jsoncode] VARCHAR(8000)
    ,[DataSetStandardName] nvarchar(200),
    [AdditionalConfigurationType] nvarchar(100),[AdditionalConfigurationValue] nvarchar(100))

INSERT INTO @SrcDatasets
( [DataSet_name],[LinkedServiceName],Jsoncode,[DataSetStandardName],[AdditionalConfigurationType],[AdditionalConfigurationValue])
VALUES
('azureSqlDatabaseDataset','azureSQLDatabase','{"name": "$azureSqlDatabaseDatasetName","properties": {"type": "AzureSqlTable","linkedServiceName": {"referenceName": "$azureSqlDatabaseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSqlDatabaseDataset',NULL,NULL),
('azureSqlDataWarehouseDataset','azureSQLDataWarehouse','{"name": "$azureSqlDWDatasetName","properties": {"type": "AzureSqlDWTable","linkedServiceName": {"referenceName": "$azureSqlDataWarehouseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSqlDataWarehouseDataset',NULL,NULL),
('azureADLSv2DataSet','ADLSv2','{    "name": "$azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileformat)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        },        "compressionCodec": "$CompressionCodectype"      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('azureBlobStorageDataSet','AzureBlobStorage','{      "name": "$azureBlobDataSetName",      "properties": {          "linkedServiceName": {              "referenceName": "$AzureBlobStorageLinkedServiceName",              "type": "LinkedServiceReference"          },          "annotations": [],          "type": "DelimitedText",          "typeProperties": {              "location": {                  "type": "AzureBlobFSLocation",                  "fileSystem": "$fileslocation"              },              "columnDelimiter": ",",              "escapeChar": "\\",              "firstRowAsHeader": "true",              "quoteChar": "\""          },          "schema": []      }  }','azureBlobStorageDataSet',NULL,NULL),
('azureADLSv2DataSet','ADLSv2','{    "name": "$azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        },        "columnDelimiter": "@dataset().columndelimiter",        "compressionCodec": "$CompressionCodectype"      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('azureADLSv2DataSet','ADLSv2','{  "name": "$azureADLSV2DataSetName",  "properties": {    "linkedServiceName": {      "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        }      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Json'),
('azureADLSv2DataSet','ADLSv2','{  "name": "$azureADLSV2DataSetName",  "properties": {    "linkedServiceName": {      "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        }      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Avro'),
('azureSQLDatabasewithManagedIdentityDataset','azureSQLDatabasewithManagedIdentity','{  "name": "$azureSQLDatabasewithManagedIdentityDatasetName",  "properties": {    "type": "AzureSqlTable",    "linkedServiceName": {      "referenceName": "$azureSQLDatabasewithManagedIdentityLinkedServiceName", "type": "LinkedServiceReference"},  "typeProperties": { "tableName": "dummy" }}}','azureSQLDatabasewithManagedIdentityDataset',NULL,NULL),
('OnPremiseSQLServerDataset','OnPremiseSQLServer','{"name": "$OnPremiseSQLServerDatasetName","properties": {"type": "SqlServerTable","linkedServiceName":{"referenceName": "$OnPremiseSQLServerLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','OnPremiseSQLServerDataset',NULL,NULL)


MERGE [T_List_DataSets] AS mrg
USING (SELECT s.*,l.Id FROM @SrcDatasets s
    INNER JOIN T_List_LinkedServices l
    ON s.[LinkedServiceName] = l.[LinkedService_Name]
    ) AS src
ON mrg.[LinkedService_id] = src.Id
AND mrg.[DataSet_name] = src.[DataSet_name]
AND ISNULL(mrg.[AdditionalConfigurationType],'') = ISNULL(src.[AdditionalConfigurationType],'')
AND ISNULL(mrg.[AdditionalConfigurationValue],'') = ISNULL(src.[AdditionalConfigurationValue],'')
WHEN MATCHED THEN 
   UPDATE SET mrg.Jsoncode = src.Jsoncode,
   mrg.[DataSetStandardName] = src.[DataSetStandardName]
WHEN NOT MATCHED THEN
INSERT ([DataSet_name],
[LinkedService_id],
           Jsoncode,
           [DataSetStandardName],
           [AdditionalConfigurationType],
           [AdditionalConfigurationValue]
           )
VALUES(src.[DataSet_name]
,src.Id
           ,src.Jsoncode
           ,src.[DataSetStandardName]
           ,src.[AdditionalConfigurationType]
           ,src.[AdditionalConfigurationValue]
           );


Print 'End - Inserting data to list datasets table'
GO

Print 'Start - Inserting data to list datasets parameters table'

DECLARE @SrcdatasetParameters as TABLE
( ParameterName VARCHAR (100) , ParameterValue VARCHAR (500) , DatasetName NVARCHAR (255),
[AdditionalConfigurationType] NVARCHAR (100),
[AdditionalConfigurationValue] NVARCHAR (100))

INSERT INTO @SrcdatasetParameters
( ParameterName,ParameterValue,DatasetName,[AdditionalConfigurationType],[AdditionalConfigurationValue])
VALUES
('$azureADLSV2DataSetName','DS_POC_ADLS','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('$LInkedServerReferneceName','','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('$azureSqlDWDatasetName','DS_POC_DWH','azureSqlDataWarehouseDataset',NULL,NULL),
('$azureSqlDatabaseDatasetName','DS_POC_AzureSQL','azureSqlDatabaseDataset',NULL,NULL),
('$azureBlobDataSetName','DS_AzureBlob','azureBlobStorageDataSet',NULL,NULL),
('$fileSystemFolderName','','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('$CompressionCodectype','snappy','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('$fileformat','','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('$fileextension','','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('$azureADLSV2DataSetName','DS_POC_ADLS','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('$LInkedServerReferneceName','','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('$fileSystemFolderName','','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('$CompressionCodectype','snappy','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('$fileformat','','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('$fileextension','','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('$ColumnDelimiter',',','azureADLSv2DataSet','SinkFileFormat','DelimitedText')

MERGE [T_List_Dataset_Parameters] AS mrg
USING (
    SELECT S.*,t.Id FROM @SrcdatasetParameters s
    INNER JOIN T_List_Datasets t
    ON s.DatasetName = t.[DataSet_name]
    AND s.[AdditionalConfigurationType] = t.[AdditionalConfigurationType]
    AND s.[AdditionalConfigurationValue] = t.[AdditionalConfigurationValue]
      ) AS src
ON mrg.[DatasetId] = src.Id
AND mrg.ParameterName = src.ParameterName

WHEN MATCHED THEN 
   UPDATE SET mrg.ParameterValue = src.ParameterValue
WHEN NOT MATCHED THEN
INSERT (ParameterName
           ,ParameterValue
           ,[DatasetId]
           )
VALUES(src.ParameterName
           ,src.ParameterValue
           ,src.Id
           );
Print 'End - Inserting data to list datasets parameters table'
GO


Print 'Start - Inserting data to list activities table'

DECLARE @SrcActivities as TABLE
( ActivityName NVARCHAR (255) ,
ActivityStandardName NVARCHAR (255),
Enabled INT,
code VARCHAR(8000),
linkedserverrequired CHAR(3),datasetrequired CHAR(3))

INSERT INTO @SrcActivities
( ActivityName,ActivityStandardName,Enabled,code,linkedserverrequired,datasetrequired)
VALUES
('Execute Pipeline','Exe_Pipeline',1,'{                  "name": "ExecutePipelineActivity",                  "type": "ExecutePipeline",                  "typeProperties": {                      "parameters": {                                                  "mySourceDatasetFolderPath": {                              "value": "@pipeline().parameters.mySourceDatasetFolderPath",                              "type": "Expression"                          }                      },                      "pipeline": {                          "referenceName": "<InvokedPipelineName>",                          "type": "PipelineReference"                      },                      "waitOnCompletion": true                   }              }          ],          "parameters": [              {                  "mySourceDatasetFolderPath": {                      "type": "String"                  }              }',NULL,NULL),
('Lookup Activity','LKP_DataSource_Name',1,'     {                  "name": "$LookupActivityname",                  "type": "Lookup",                      "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],                  "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                      "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },                  "userProperties": [],                  "typeProperties": {                      "source": {                          "type": "AzureSqlSource",                          "sqlReaderQuery": {                              "value": "$query",                              "type": "Expression"                          },                          "queryTimeout": "02:00:00"                      },                      "dataset": {                          "referenceName": "$dataset",                          "type": "DatasetReference"                      },       "firstRowOnly": $firstrow                  }              }       ',NULL,1),
('Copy Activity','CP_DataSource_DataDestination',1,'{"name": "$CopyActivityName","type": "Copy","dependsOn": [],"policy": {    "timeout": "7.00:00:00",    "retry": 0,    "retryIntervalInSeconds": 30,    "secureOutput": false,    "secureInput": false},"userProperties": [],"typeProperties": {    "source": {        "type": "$Source",        "sqlReaderQuery": {            "value": "$sqlReaderQuery",            "type": "Expression"        },        "queryTimeout": "02:00:00"    },    "sink": {        "type": "$Sink",        "storeSettings": {            "type": "AzureBlobFSWriteSettings"        }    },    "enableStaging": false},"inputs": [    {        "referenceName": "$inputDatasetReference",        "type": "DatasetReference"    }],"outputs": [    {        "referenceName": "$outputDatasetReference",        "type": "DatasetReference",        "parameters": {            $parameters            }        }    ]                          }',NULL,1),
('For Each Activity','ForEachActivity',1,'   {                  "name": "$foreachactivityname",                  "type": "ForEach",                  "dependsOn": [                      {                          "activity": "$dependson",                          "dependencyConditions": [                              "$dependencyConditions"                          ]                      }                  ],                  "userProperties": [],                  "typeProperties": {                      "items": {                          "value": "@activity(''$dependentactivityname'').output.value",                          "type": "Expression"                      },                      "batchCount": $batchCount,       "isSequential": $isSequential,       "activities": [$activityjsoncode]                         }              }',NULL,NULL),
('Wait Activity','Wait',1,'{     "name":"Wait1",     "type":"Wait",     "dependsOn":[       ],     "userProperties":[        {           "name":"Description",           "value":"Wait time for 30 seconds"        }     ],     "typeProperties":{        "waitTimeInSeconds":30     }  } ',NULL,NULL),
('Filter Activity','FilterActivity',1,'{   "name": "MyFilterActivity",   "type": "filter",   "typeProperties": {    "condition": "$condition",    "items": "$inputarray"   }  }',NULL,NULL),
('Get Metadata Activity','Metadata Activity',1,'{   "name": "$Metadataactivityname",   "type": "GetMetadata",   "typeProperties": {    "fieldList" : "$filedlist",    "dataset": {     "referenceName": "$MyDataset",     "type": "DatasetReference"    }   }  }',NULL,NULL),
('If Activity','IfActivity',1,'{      "name": "$Name_of_the_activity>",      "type": "IfCondition",      "typeProperties": {        "expression": {              "value": "$expression_that_evaluates_to_trueorfalse>",              "type": "Expression"        },          "ifTrueActivities": [              {                  "Activity 1 definition>"              },              {                  "<Activity 2 definition>"              },              {                  "<Activity N definition>"              }          ],            "ifFalseActivities": [              {                  "<Activity 1 definition>"              },              {                  "<Activity 2 definition>"              },              {                  "<Activity N definition>"              }        ]      }  }',NULL,NULL),
('Custom Logging','SP_Custom_Logging',1,'   {      "name": "$SPActivityName",      "description":"Description",      "type": "SqlServerStoredProcedure",     "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],     "linkedServiceName": {          "referenceName": "$MetadataDBLinkedServiceName",       "type": "LinkedServiceReference"      },      "typeProperties": {              "storedProcedureName": "$SPName",          "storedProcedureParameters": $SPParameters            }      }  }','1',NULL)


MERGE [T_List_Activities] AS mrg
USING (SELECT s.* FROM @SrcActivities s
      ) AS src
ON mrg.ActivityName = src.ActivityName
WHEN MATCHED THEN 
   UPDATE SET mrg.ActivityStandardName = src.ActivityStandardName,
   mrg.Enabled = src.Enabled,
   mrg.code = src.code,
   mrg.linkedserverrequired = src.linkedserverrequired,
   mrg.datasetrequired = src.datasetrequired
WHEN NOT MATCHED THEN
INSERT (ActivityName,
ActivityStandardName,
           Enabled,
           code,
           linkedserverrequired,
           datasetrequired
           )
VALUES(    src.ActivityName
           ,src.ActivityStandardName
           ,src.Enabled
           ,src.code
           ,src.linkedserverrequired,
           src.datasetrequired
           );



Print 'End - Inserting data to list activities table'

GO


Print 'Start - Inserting data to list activity parameters table'


DECLARE @SrcactivityParameters as TABLE
( ParameterName VARCHAR (100) , ParameterValue VARCHAR (8000) , ActivityName NVARCHAR (255))

INSERT INTO @SrcactivityParameters
( ParameterName,ParameterValue,ActivityName)
VALUES
('InvokedPipelineName','','Execute Pipeline'),
('condition','','Filter Activity'),
('inputarray','','Filter Activity'),
('isSequential','false','For Each Activity'),
('Metadataactivityname','','Get Metadata Activity'),
('filedlist','','Get Metadata Activity'),
('MyDataset','','Get Metadata Activity'),
('Name_of_the_activity','','If Activity'),
('LookupActivityname','','Lookup Activity'),
('query','select SS.Name as Schema_Name, ST.Name as Table_Name FROM SYS.TABLES ST JOIN SYS.SCHEMAS SS ON SS.schema_id= ST.schema_id','Lookup Activity'),
('dataset','','Lookup Activity'),
('firstrow','false','Lookup Activity'),
('foreachactivityname','','For Each Activity'),
('dependson','','For Each Activity'),
('dependencyConditions','','For Each Activity'),
('dependentactivityname','','For Each Activity'),
('batchCount','20','For Each Activity'),
('activityjsoncode','','For Each Activity'),
('dependson','','Lookup Activity'),
('CopyActivityName','CP_SqlServer_ADLSParquet','Copy Activity'),
('Source','AzureSqlSource','Copy Activity'),
('Sink','ParquetSink','Copy Activity'),
('inputDatasetReference','','Copy Activity'),
('outputDatasetReference','','Copy Activity'),
('parameters','       ""filename"": ""@item().table_name"",                                          ""directory"": ""@item().table_name"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter""','Copy Activity'),
('sqlReaderQuery','@concat(''select * from '',''['',item().schema_name,'']'',''.'',''['',item().table_name,'']'')','Copy Activity'),
('SPName','usp_Log_PipelineStatus','Custom Logging'),
('SPParameters','   {""In_PipelineName"": {""value"": 
   {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                
   ""type"": ""String""                          },                     
   ""In_PipelineStatus"": {                              ""value"": ""$pipelinestatus"",     
   ""type"": ""String""                          },                 
   ""In_ExecutionStartTime"": {                            
   ""value"": {                                 ""value"": ""@utcnow()"",     
   ""type"": ""Expression""                              },                  
   ""type"": ""Datetime""                          },                      
   ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                    
   ""type"": ""Datetime""                          }    
                    ','Custom Logging'),
('MetadataDBLinkedServiceName','','Custom Logging'),

('SPActivityName','','Custom Logging'),
('dependson','','Custom Logging'),
('dependencyConditions','','Custom Logging'),
('dependencyConditions','','Lookup Activity')


MERGE [T_List_Activity_Parameters] AS mrg
USING (
    SELECT S.*,t.Id FROM @SrcactivityParameters s
    INNER JOIN T_List_Activities t
    ON s.ActivityName = t.[ActivityName]
      ) AS src
ON mrg.[ActivityId] = src.Id
AND mrg.ParameterName = src.ParameterName
WHEN MATCHED THEN 
   UPDATE SET mrg.ParameterValue = src.ParameterValue
WHEN NOT MATCHED THEN
INSERT (ParameterName
           ,ParameterValue
           ,[ActivityId]
           )
VALUES(src.ParameterName
           ,src.ParameterValue
           ,src.Id
           );


Print 'End - Inserting data to list activity parameters table'

GO