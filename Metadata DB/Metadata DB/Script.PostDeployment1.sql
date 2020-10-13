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
('$keyvaultlocation',''),
('$servicePrincipalId',''),
('$servicePrincipalKey',''),
('$EmailTo',''),
('$LogicAppURL','')

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

DECLARE @SrcMasterPipelinesparams as TABLE
(ParameterName NVARCHAR(255), ParameterValue VARCHAR (MAX),MasterPipelineName NVARCHAR(255))


INSERT INTO @SrcMasterPipelinesparams
( ParameterName, ParameterValue,MasterPipelineName)
VALUES
('$body','''"{\"EmailTo\": \"@{pipeline().parameters.EmailTo}\",  \"Subject\": \"An error has occured in the @{pipeline().parameters.PipelineName}-pipeline\",  \"DataFactoryName\": \"@{pipeline().DataFactory}\",  \"PipelineName\": \"@{pipeline().parameters.PipelineName}\",  \"Activity\": \"@{pipeline().parameters.Activity}\",  \"Message\": \"@{pipeline().parameters.Message}\"}"''','Sendmail'),
('$Activity','""','Sendmail'),
('$PipelineEndedMessage','"The $Pipeline is Ended"','Sendmail'),
('$PipelineStartedMessage','"The $Pipeline is Started"','Sendmail')



MERGE [T_Master_Pipelines_Parameters_List] AS mrg
USING (SELECT s.*,m.MasterPipelineId as Id FROM @SrcMasterPipelinesparams s 
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
( DataSourcename NVARCHAR(255), created_date date,sourceType VARCHAR(100),sourcemetadataquery varchar(max))

INSERT INTO @SrcDataSources
( DataSourcename,created_date,sourceType,sourcemetadataquery)
VALUES
('On Premise SQLServer',getdate(),'SqlServer','DECLARE @version VARCHAR(1000) =            (                SELECT @@version            );    DECLARE @Tables TABLE    (        sql_ServerName NVARCHAR(128),        sql_TableSchema_type NVARCHAR(128),        sql_TableName_Full NVARCHAR(256),        sql_Table_Catalog NVARCHAR(128),        sql_Table_Schema NVARCHAR(128),        sql_Table_Name NVARCHAR(128),        sql_Column_Name NVARCHAR(128),        sql_Ordinal_Position INT,        sql_Is_Nullable VARCHAR(3),        sql_Data_Type NVARCHAR(128),        sql_Character_Maximum_Length INT,        sql_isPrimaryKey INT    );        INSERT INTO @Tables    (        sql_ServerName ,        sql_TableSchema_type ,        sql_TableName_Full ,        sql_TABLE_CATALOG,        sql_TABLE_SCHEMA ,        sql_TABLE_NAME ,        sql_Column_Name  ,        sql_Ordinal_Position ,        sql_Is_Nullable ,        sql_Data_Type  ,        sql_Character_Maximum_Length,     sql_isPrimaryKey      )      SELECT DISTINCT           @@SERVERNAME src_ServerName,           t.type_desc AS src_TableSchema_type,           ''['' + s.name + '']'' + ''.['' + t.name + '']'' COLLATE DATABASE_DEFAULT AS src_TableName_Full,           c.TABLE_CATALOG,           c.TABLE_SCHEMA,           c.TABLE_NAME,           c.COLUMN_NAME,           c.ORDINAL_POSITION,           c.IS_NULLABLE,           c.DATA_TYPE,           c.CHARACTER_MAXIMUM_LENGTH,           ISNULL(CAST(ix.is_primary_key AS INT), 0) is_primary_key               FROM    (        SELECT name,               type_desc,               schema_id,               t.object_id        FROM sys.tables t        UNION        SELECT name,               type_desc,               schema_id,               v.object_id        FROM sys.views v    ) t        JOIN sys.schemas s            ON t.schema_id = s.schema_id        JOIN INFORMATION_SCHEMA.COLUMNS c            ON c.TABLE_NAME = t.name COLLATE DATABASE_DEFAULT               AND c.TABLE_SCHEMA = s.name        JOIN sys.columns co            ON co.object_id = t.object_id               AND co.name = c.COLUMN_NAME        JOIN sys.types ty            ON co.user_type_id = ty.user_type_id        LEFT JOIN        (            SELECT ic.object_id,                   ic.index_id,                   ic.index_column_id,                   ic.column_id,                   i.is_primary_key            FROM sys.index_columns ic                JOIN sys.indexes i                    ON i.index_id = ic.index_id                       AND i.object_id = ic.object_id            WHERE  i.is_primary_key = 1        ) ix            ON ix.object_id = co.object_id               AND ix.column_id = co.column_id    WHERE c.TABLE_CATALOG NOT IN ( ''master'', ''tempdb'', ''msdb'', ''model'' )    SELECT * FROM @Tables ;'),
('AzureDataLakeStorageV2',getdate(),'ADLSV2','')

MERGE [T_List_DataSources] AS mrg
USING (SELECT * FROM @SrcDataSources) AS src
ON mrg.DataSourceName = src.DataSourceName
AND mrg.SourceType = src.SourceType
WHEN MATCHED THEN 
   UPDATE SET mrg.[SourceMetadataQuery] = src.SourceMetadataQuery
WHEN NOT MATCHED THEN
INSERT ([DataSourceName]
           ,[SourceType]
           ,[SourceMetadataQuery]
           )
VALUES(src.DataSourceName
           ,src.SourceType
           ,src.SourceMetadataQuery
           );

Print 'End - Inserting data to list datasources table'
GO

Print 'Start - Inserting data to list linkedservices table'

DECLARE @SrcLinkedServices as TABLE
( LinkedServiceName VARCHAR(100), Jsoncode VARCHAR(4000),AuthenticationType VARCHAR(200),KeyVaultReferenceReq INT)

INSERT INTO @SrcLinkedServices
( LinkedServiceName,Jsoncode,AuthenticationType,KeyVaultReferenceReq)
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
    }} ','SQL authentication',1),
('azureSQLDataWarehouse','{      "name": "$azureSqlDataWarehouseLinkedServiceName",      "properties": {          "type": "AzureSqlDW",          "typeProperties": {              "connectionString": {                  "type": "SecureString",                  "value": "Server=tcp:$azureSqlDWServerName.database.windows.net,1433;Database=$azureSqlDWDBName;Integrated Security=False;Encrypt=True;Connection Timeout=30"              }          }      }  }','SQL authentication',1),
('ADLSv2','{      "name": "$ADLSv2LinkedServiceName",      "properties": {          "annotations": [],          "type": "AzureBlobFS",          "typeProperties": {              "url": "$URL"          },          "connectVia": {              "referenceName": "$nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }','Managed Identity',0),
('AzureBlobStorage','{      "name": "$AzureBlobStorageLinkedServiceName" ,     "properties": {          "type": "AzureBlobStorage",          "typeProperties": {              "connectionString": "DefaultEndpointsProtocol=https;AccountName=$AccountName;AccountKey=$AccountKey"          },          "connectVia": {              "referenceName": "$nameofintegrationruntime",              "type": "IntegrationRuntimeReference"          }      }  }','Managed Identity',NULL),
('OnPremiseSQLServer','{      "name": "$OnPremiseSQLServerLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": { "type": "SqlServer",          "typeProperties":{              "connectionString": "Integrated Security=False;Data Source=$onpremSqlDBServerName;Initial Catalog=$onpremSqlDatabaseName;User ID=$onpremSqlDBUserName",               "password": {                  "type": "AzureKeyVaultSecret",                  "store": {                         "referenceName": "$azurekeyvaultlinkedservicereference",                      "type": "LinkedServiceReference"                  },      "secretName": "$onpremSqlDBPassword"              }          },           "connectVia": {              "referenceName": "$IRName",              "type": "IntegrationRuntimeReference"          }      }  }  ','SQL authentication',1),
('azureSQLDatabase','     { "name": "$azureSqlDatabaseLinkedServiceName",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "AzureSqlDatabase",          "typeProperties": {              "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$azureSqlDBServerName.database.windows.net;Initial Catalog=$azureSqlDatabaseName"          }      }  }','Managed Identity',0),
('azureKeyVault','{    "name": "$azureKeyVaultLinkedServiceName",    "properties": {        "annotations": [],        "type": "AzureKeyVault",       "typeProperties": {            "baseUrl": "https://$keyvaultname.vault.azure.net/"        }    }}','Managed Identity',0),
('RestService','    {      "name": "RestService1",      "type": "Microsoft.DataFactory/factories/linkedservices",      "properties": {          "annotations": [],          "type": "RestService",          "typeProperties": {              "url": "$restapiurl" ,         "enableServerCertificateValidation": true,              "authenticationType": "Anonymous"          }      }  }  ','Anonymous',0)
,('azureSQLDatabase', '{  "name": "$azureSqlDatabaseLinkedServiceName",  "properties": {    "type": "AzureSqlDatabase",    "typeProperties": {      "connectionString": "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=$azureSqlDBServerName.database.windows.net;Initial Catalog=$azureSqlDatabaseName",      "servicePrincipalId": "$master_servicePrincipalId",      "servicePrincipalKey": {        "type": "AzureKeyVaultSecret",        "store": {          "referenceName": "$azurekeyvaultlinkedservicereference",          "type": "LinkedServiceReference"        },        "secretName": "$master_servicePrincipalKey"      }  ,"tenant":"$master_tenantId"  },    "connectVia": {      "referenceName": "$nameofintegrationruntime",      "type": "IntegrationRuntimeReference"    } }} ','Service Principal',0)
,('OnPremiseOracle','{ "name": "$OnPremiseOracleLinkedServiceName","properties": { "type": "Oracle", "typeProperties": {  "connectionString": "Host=$OnPremiseOracleHost;Port=$OnPremiseOraclePort;Sid=$OnPremiseOracleSid;User Id=$OnPremiseOracleUserName;","password": {   "type": "AzureKeyVaultSecret",  "store": { "referenceName": "$azurekeyvaultlinkedservicereference",  "type": "LinkedServiceReference"  }, "secretName": "$OnPremiseOraclePassword" } },"connectVia": {"referenceName": "$IRName", "type": "IntegrationRuntimeReference"  }}}','SQL authentication',1)

MERGE [T_List_LinkedServices] AS mrg
USING (SELECT * FROM @SrcLinkedServices) AS src
ON mrg.LinkedServiceName = src.LinkedServiceName
AND mrg.AuthenticationType = src.AuthenticationType
WHEN MATCHED THEN 
   UPDATE SET mrg.Jsoncode = src.Jsoncode,
   mrg.KeyVaultReferenceReq = src.KeyVaultReferenceReq
WHEN NOT MATCHED THEN
INSERT ([LinkedServiceName]
           ,Jsoncode
		   ,AuthenticationType
		   ,KeyVaultReferenceReq
           )
VALUES(src.LinkedServiceName
           ,src.Jsoncode
		   ,src.AuthenticationType
		   ,src.KeyVaultReferenceReq
           );

Print 'End - Inserting data to list linkedservices table'

GO

Print 'Start - Inserting data to list linked service parameters table'

DECLARE @SrcLinkedServicesParameters as TABLE
( ParameterName VARCHAR(100), ParameterValue VARCHAR(500),LinkedServiceName VARCHAR (100),ReferFromKeyVault INT,KeyVaultReferenceDescription VARCHAR(200),AuthenticationType VARCHAR(100))

INSERT INTO @SrcLinkedServicesParameters
( ParameterName,ParameterValue,LinkedServiceName,ReferFromKeyVault,KeyVaultReferenceDescription,AuthenticationType)
VALUES
('$azureSqlDatabaseLinkedServiceName','AzureSQLDatabase','azureSQLDatabase',0,NULL,'SQL Authentication'),
('$azureSqlDBServerName','','azureSQLDatabase',0,NULL,'SQL Authentication'),
('$azureSqlDatabaseName','','azureSQLDatabase',0,NULL,'SQL Authentication'),
('$azureSqlDBUserName','','azureSQLDatabase',0,NULL,'SQL Authentication'),
('$azureSqlDBPassword','','azureSQLDatabase',1,'Password for Azure SQL DB','SQL Authentication'),
('$azurekeyvaultlinkedservicereference','','azureSQLDatabase',0,NULL,'SQL Authentication'),
('$AccountName','','AzureBlobStorage',0,NULL,'Managed Identity'),
('$AccountKey','','AzureBlobStorage',0,NULL,'Managed Identity'),
('$nameofintegrationruntime','','azureSQLDatabase',0,NULL,'SQL Authentication'),
('$AzureBlobStorageLinkedServiceName','','AzureBlobStorage',0,NULL,'Managed Identity'),
('$OnPremiseSQLServerLinkedServiceName','','OnPremiseSQLServer',0,NULL,'SQL Authentication'),
('$IRName','IR-SelfHosted','OnPremiseSQLServer',0,NULL,'SQL Authentication'),
('$onpremSqlDBServerName','','OnPremiseSQLServer',0,NULL,'SQL Authentication'),
('$onpremSqlDatabaseName','','OnPremiseSQLServer',0,NULL,'SQL Authentication'),
('$onpremSqlDBUserName','','OnPremiseSQLServer',0,NULL,'SQL Authentication'),
('$onpremSqlDBPassword','','OnPremiseSQLServer',1,'Password for Onprem SQL DB','SQL Authentication'),
('$azurekeyvaultlinkedservicereference','','OnPremiseSQLServer',0,NULL,'SQL Authentication'),
('$azureSqlDataWarehouseLinkedServiceName','','azureSQLDataWarehouse',0,NULL,'SQL Authentication'),
('$azureSqlDWServerName','','azureSQLDataWarehouse',0,NULL,'SQL Authentication'),
('$azureSqlDWDBName','','azureSQLDataWarehouse',0,NULL,'SQL Authentication'),
('$azureSqlDWUserName','','azureSQLDataWarehouse',0,NULL,'SQL Authentication'),
('$azureSqlDWUserPassword','','azureSQLDataWarehouse',1,'Password for Azure SQL DW','SQL Authentication'),
('$ADLSv2LinkedServiceName','','ADLSv2',0,NULL,'Managed Identity'),
('$ADLSv2AccountName','','ADLSv2',0,NULL,'Managed Identity'),
('$URL','','ADLSv2',0,NULL,'Managed Identity'),
('$nameofintegrationruntime','','ADLSv2',0,NULL,'Managed Identity'),
('$azureSQLDatabaseLinkedServiceName','','azureSQLDatabase',0,NULL,'Managed Identity'),
('$azureSqlDBServerName','','azureSQLDatabase',0,NULL,'Managed Identity'),
('$azureSqlDatabaseName','','azureSQLDatabase',0,NULL,'Managed Identity'),
('$nameofintegrationruntime','','azureSQLDatabase',0,NULL,'Managed Identity'),
('$azureKeyVaultLinkedServiceName','','azureKeyVault',0,NULL,'Managed Identity'),
('$keyvaultname','','azureKeyVault',0,NULL,'Managed Identity'),
('$restapiurl','','RestService',0,NULL,'Anonymous'),
('$nameofintegrationruntime','','RestService',0,NULL,'Anonymous'),
('$RestServiceLinkedServiceName','','RestService',0,NULL,'Anonymous'),
('$azureSqlDatabaseLinkedServiceName','','azureSQLDatabase',0,NULL,'Service Principal'),
('$azureSqlDBServerName','','azureSQLDatabase',0,NULL,'Service Principal'),
('$azureSqlDatabaseName','','azureSQLDatabase',0,NULL,'Service Principal'),
('$azurekeyvaultlinkedservicereference','','azureSQLDatabase',0,NULL,'Service Principal'),
('$nameofintegrationruntime','','azureSQLDatabase',0,NULL,'Service Principal'),
('$OnPremiseOracleLinkedServiceName','','OnPremiseOracle',0,NULL,'SQL Authentication'),
('$IRName','IR-SelfHosted','OnPremiseOracle',0,NULL,'SQL Authentication'),
('$OnPremiseOracleHost','','OnPremiseOracle',0,NULL,'SQL Authentication'),
('$OnPremiseOraclePort','','OnPremiseOracle',0,NULL,'SQL Authentication'),
('$OnPremiseOracleSid','','OnPremiseOracle',0,NULL,'SQL Authentication'),
('$OnPremiseOracleUserName','','OnPremiseOracle',0,NULL,'SQL Authentication'),
('$OnPremiseOraclePassword','','OnPremiseOracle',1,'Password for onprem oracle DB','SQL Authentication'),
('$azurekeyvaultlinkedservicereference','','OnPremiseOracle',0,NULL,'SQL Authentication')


MERGE [T_List_LinkedService_Parameters] AS mrg
USING (
    SELECT S.*,t.LinkedServiceId as Id FROM @SrcLinkedServicesParameters s
    INNER JOIN T_List_LinkedServices t
    ON s.LinkedServiceName = t.[LinkedServiceName]
    AND s.AuthenticationType = t.AuthenticationType
      ) AS src
ON mrg.[LinkedServiceId] = src.Id
AND mrg.ParameterName = src.ParameterName
WHEN MATCHED THEN 
   UPDATE SET mrg.ParameterValue = src.ParameterValue
   ,mrg.ReferFromKeyVault = src.ReferFromKeyVault
   ,mrg.KeyVaultReferenceDescription = src.KeyVaultReferenceDescription
WHEN NOT MATCHED THEN
INSERT (ParameterName
           ,ParameterValue
           ,[LinkedServiceId]
           ,ReferFromKeyVault
           ,KeyVaultReferenceDescription
           )
VALUES(src.ParameterName
           ,src.ParameterValue
           ,src.Id
           ,src.ReferFromKeyVault
           ,src.KeyVaultReferenceDescription
           );

Print 'End - Inserting data to list linked service parameters table'
GO

Print 'Start - Inserting data to list datasets table'


DECLARE @SrcDatasets as TABLE
( [DataSetName] NVARCHAR (255), [LinkedServiceName] NVARCHAR (255),
AuthenticationType NVARCHAR(200),
    [Jsoncode] VARCHAR(8000)
    ,[DataSetStandardName] nvarchar(200),
    [AdditionalConfigurationType] nvarchar(100),[AdditionalConfigurationValue] nvarchar(100))

INSERT INTO @SrcDatasets
( [DataSetName],[LinkedServiceName],AuthenticationType,Jsoncode,[DataSetStandardName],[AdditionalConfigurationType],[AdditionalConfigurationValue])
VALUES
('azureSqlDatabaseDataset','azureSQLDatabase','SQL Authentication','{"name": "$azureSqlDatabaseDatasetName","properties": {"type": "AzureSqlTable","linkedServiceName": {"referenceName": "$azureSqlDatabaseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSqlDatabaseDataset',NULL,NULL),
('azureSqlDataWarehouseDataset','azureSQLDataWarehouse','SQL Authentication','{"name": "$azureSqlDWDatasetName","properties": {"type": "AzureSqlDWTable","linkedServiceName": {"referenceName": "$azureSqlDataWarehouseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSqlDataWarehouseDataset',NULL,NULL),
('azureADLSv2DataSet','ADLSv2','Managed Identity','{    "name": "$azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileformat)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        },        "compressionCodec": "$CompressionCodectype"  ,"firstRowAsHeader": true    },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Parquet'),
('azureBlobStorageDataSet','AzureBlobStorage','Managed Identity','{      "name": "$azureBlobDataSetName",      "properties": {          "linkedServiceName": {              "referenceName": "$AzureBlobStorageLinkedServiceName",              "type": "LinkedServiceReference"          },          "annotations": [],          "type": "DelimitedText",          "typeProperties": {              "location": {                  "type": "AzureBlobFSLocation",                  "fileSystem": "$fileslocation"              },              "columnDelimiter": ",",              "escapeChar": "\\",              "firstRowAsHeader": "true",              "quoteChar": "\""          },          "schema": []      }  }','azureBlobStorageDataSet',NULL,NULL),
('azureADLSv2DataSet','ADLSv2','Managed Identity','{    "name": "$azureADLSV2DataSetName",    "properties": {      "linkedServiceName": {        "referenceName": "$ADLSV2LinkedServiceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        },        "columnDelimiter": "@dataset().columndelimiter",        "compressionCodec": "$CompressionCodectype" ,"firstRowAsHeader": true     },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','DelimitedText'),
('azureADLSv2DataSet','ADLSv2','Managed Identity','{  "name": "$azureADLSV2DataSetName",  "properties": {    "linkedServiceName": {      "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        }      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Json'),
('azureADLSv2DataSet','ADLSv2','Managed Identity','{  "name": "$azureADLSV2DataSetName",  "properties": {    "linkedServiceName": {      "referenceName": "$LInkedServerReferneceName",        "type": "LinkedServiceReference"      },      "parameters": {        "filename": { "type": "string" },        "directory": { "type": "string" },        "fileformat": { "type": "string" },        "fileextension": { "type": "string" },        "columnDelimiter": { "type": "string" }      },      "annotations": [],      "type": "$fileformat",      "typeProperties": {        "location": {          "type": "AzureBlobFSLocation",          "fileName": {            "value": "@concat(dataset().filename,''.'',dataset().fileextension)",            "type": "Expression"          },          "folderPath": {            "value": "@dataset().directory",            "type": "Expression"          },          "fileSystem": "$fileSystemFolderName"        }      },      "schema": []    }  }','azureADLSv2DataSet','SinkFileFormat','Avro'),
('azureSQLDatabaseDataset','azureSQLDatabase','Managed Identity','{  "name": "$azureSQLDatabaseDatasetName",  "properties": {    "type": "AzureSqlTable",    "linkedServiceName": {      "referenceName": "$azureSQLDatabaseLinkedServiceName", "type": "LinkedServiceReference"},  "typeProperties": { "tableName": "dummy" }}}','azureSQLDatabaseDataset',NULL,NULL),
('OnPremiseSQLServerDataset','OnPremiseSQLServer','SQL Authentication','{"name": "$OnPremiseSQLServerDatasetName","properties": {"type": "SqlServerTable","linkedServiceName":{"referenceName": "$OnPremiseSQLServerLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','OnPremiseSQLServerDataset',NULL,NULL),
('RestServiceDataset','RestService','Anonymous','  {      "name": "$RestServiceDatasetName",      "properties": {          "linkedServiceName": {              "referenceName": "$RestServiceLinkedServiceName",              "type": "LinkedServiceReference"          },          "annotations": [],          "type": "RestResource",          "schema": []      },      "type": "Microsoft.DataFactory/factories/datasets"  }','RestServiceDataset',NULL,NULL),
('azureSQLDatabaseDataset','azureSQLDatabase','Service Principal',' {"name": "$azureSqlDatabaseDatasetName","properties": {"type": "AzureSqlTable","linkedServiceName": {"referenceName": "$azureSqlDatabaseLinkedServiceName","type": "LinkedServiceReference"}, "typeProperties": {"tableName": "dummy"}}}','azureSQLDatabaseDataset',NULL,NULL),
('OnPremiseOracleDataset','OnPremiseOracle','SQL Authentication','{"name": "$OnPremiseOracleDatasetName","properties":{"type": "OracleTable","schema": [],"typeProperties": {"table": "dummy" },"linkedServiceName": {  "referenceName": "$OnPremiseOracleLinkedServiceName",  "type": "LinkedServiceReference" }}}','OnPremiseOracleDataset',NULL,NULL)


MERGE [T_List_DataSets] AS mrg
USING (SELECT s.*,l.LinkedServiceId as Id FROM @SrcDatasets s
    INNER JOIN T_List_LinkedServices l
    ON s.[LinkedServiceName] = l.[LinkedServiceName]
    AND s.AuthenticationType = l.AuthenticationType
    ) AS src
ON mrg.[LinkedServiceid] = src.Id
AND mrg.[DataSetName] = src.[DataSetName]
AND ISNULL(mrg.[AdditionalConfigurationType],'') = ISNULL(src.[AdditionalConfigurationType],'')
AND ISNULL(mrg.[AdditionalConfigurationValue],'') = ISNULL(src.[AdditionalConfigurationValue],'')
WHEN MATCHED THEN 
   UPDATE SET mrg.Jsoncode = src.Jsoncode,
   mrg.[DataSetStandardName] = src.[DataSetStandardName]
WHEN NOT MATCHED THEN
INSERT ([DataSetName],
[LinkedServiceId],
           Jsoncode,
           [DataSetStandardName],
           [AdditionalConfigurationType],
           [AdditionalConfigurationValue]
           )
VALUES(src.[DataSetName]
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
LinkedServiceName VARCHAR(200),
AuthenticationType VARCHAR(200),
[AdditionalConfigurationType] NVARCHAR (100),
[AdditionalConfigurationValue] NVARCHAR (100))

INSERT INTO @SrcdatasetParameters
( ParameterName,ParameterValue,DatasetName,LinkedServiceName,AuthenticationType,[AdditionalConfigurationType],[AdditionalConfigurationValue])
VALUES
('$azureADLSV2DataSetName','DS_POC_ADLS','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','Parquet'),
('$LInkedServerReferneceName','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','Parquet'),
('$azureSqlDWDatasetName','DS_POC_DWH','azureSqlDataWarehouseDataset','azureSqlDataWarehouse','SQL Authentication',NULL,NULL),
('$azureSqlDatabaseDatasetName','DS_POC_AzureSQL','azureSqlDatabaseDataset','azureSqlDatabase','SQL Authentication',NULL,NULL),
('$azureBlobDataSetName','DS_AzureBlob','azureBlobStorageDataSet','azureBlobStorage','Managed Identity',NULL,NULL),
('$fileSystemFolderName','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','Parquet'),
('$CompressionCodectype','snappy','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','Parquet'),
('$fileformat','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','Parquet'),
('$fileextension','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','Parquet'),
('$ADLSV2DataSetName','DS_POC_ADLS','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$ADLSV2LinkedServiceName','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$fileSystemFolderName','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$CompressionCodectype','snappy','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$fileformat','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$fileextension','','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$ColumnDelimiter',',','azureADLSv2DataSet','ADLSV2','Managed Identity','SinkFileFormat','DelimitedText'),
('$azureSqlDatabaseLinkedServiceName','','azureSqlDatabaseDataset','azureSqlDatabase','SQL Authentication',NULL,NULL),
('$azureSQLDatabaseDatasetName','','azureSQLDatabaseDataset','azureSqlDatabase','Managed Identity',NULL,NULL),
('$azureSQLDatabaseLinkedServiceName','','azureSQLDatabaseDataset','azureSqlDatabase','Managed Identity',NULL,NULL),
('$OnPremiseSQLServerDatasetName','','OnPremiseSQLServerDataset','OnPremiseSQLServer','SQL Authentication',NULL,NULL),
('$OnPremiseSQLServerLinkedServiceName','','OnPremiseSQLServerDataset','OnPremiseSQLServer','SQL Authentication',NULL,NULL),
('$RestServiceDatasetName','','RestServiceDataset','RestService','Anonymous',NULL,NULL),
('$RestServiceLinkedServiceName','','RestServiceDataset','RestService','Anonymous',NULL,NULL),
('$azureSQLDatabaseDatasetName','','azureSQLDatabaseDataset','azureSqlDatabase','Service Principal',NULL,NULL),
('$azureSQLDatabaseLinkedServiceName','','azureSQLDatabaseDataset','azureSqlDatabase','Service Principal',NULL,NULL),
('$OnPremiseOracleDatasetName','','OnPremiseOracleDataset','OnPremiseOracle','SQL Authentication',NULL,NULL),
('$OnPremiseOracleLinkedServiceName','','OnPremiseOracleDataset','OnPremiseOracle','SQL Authentication',NULL,NULL)



MERGE [T_List_Dataset_Parameters] AS mrg
USING (
    SELECT S.*,t.DataSetId AS Id FROM @SrcdatasetParameters s
    INNER JOIN T_List_Datasets t 
    ON s.DatasetName = t.[DataSetName]
    AND ISNULL(s.[AdditionalConfigurationType],'') = ISNULL(t.[AdditionalConfigurationType],'')
    AND ISNULL(s.[AdditionalConfigurationValue],'') = ISNULL(t.[AdditionalConfigurationValue],'')
    INNER JOIN T_List_LinkedServices t1
    ON t1.LinkedServiceId = t.LinkedServiceId
    AND t1.LinkedServiceName = s.LinkedServiceName
    AND t1.AuthenticationType = s.AuthenticationType
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
linkedserverrequired CHAR(3),datasetrequired CHAR(3),SourceType VARCHAR(200))

INSERT INTO @SrcActivities
( ActivityName,ActivityStandardName,Enabled,code,linkedserverrequired,datasetrequired,SourceType)
VALUES
('Execute Pipeline','Exe_Pipeline',1,'{                  "name": "ExecutePipelineActivity",                  "type": "ExecutePipeline",                  "typeProperties": {                      "parameters": {                                                  "mySourceDatasetFolderPath": {                              "value": "@pipeline().parameters.mySourceDatasetFolderPath",                              "type": "Expression"                          }                      },                      "pipeline": {                          "referenceName": "<InvokedPipelineName>",                          "type": "PipelineReference"                      },                      "waitOnCompletion": true                   }              }          ],          "parameters": [              {                  "mySourceDatasetFolderPath": {                      "type": "String"                  }              }',NULL,NULL,NULL),
('Lookup Activity','LKP_DataSourceName',1,'     {                  "name": "$LookupActivityname",                  "type": "Lookup",                      "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],                  "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                      "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },                  "userProperties": [],                  "typeProperties": {                      "source": {                          "type": "AzureSqlSource",                          "sqlReaderQuery": {                              "value": "$query",                              "type": "Expression"                          },                          "queryTimeout": "02:00:00"                      },                      "dataset": {                          "referenceName": "$dataset",                          "type": "DatasetReference"                      },       "firstRowOnly": $firstrow                  }              }       ',NULL,1,'azureSQLDatabase'),
('Lookup Activity','LKP_DataSourceName',1,'  {                  "name": "$LookupActivityname",                  "type": "Lookup",                      "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],                  "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                      "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },                  "userProperties": [],                  "typeProperties": {                      "source": {                          "type": "SalesforceSource",                          "query": {                              "value": "$query",                              "type": "Expression"                          },                          "queryTimeout": "02:00:00"                      },                      "dataset": {                          "referenceName": "$dataset",                          "type": "DatasetReference"                      },       "firstRowOnly": $firstrow                  }              }        ',NULL,1,'SalesforceKeyVault'),
('Lookup Activity','LKP_DataSourceName',1,'     {                  "name": "$LookupActivityname",                  "type": "Lookup",                      "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],                  "policy": {                      "timeout": "7.00:00:00",                      "retry": 0,                      "retryIntervalInSeconds": 30,                      "secureOutput": false,                      "secureInput": false                  },                  "userProperties": [],                  "typeProperties": {                      "source": {                          "type": "AzureSqlSource",                          "sqlReaderQuery": {                              "value": "$query",                              "type": "Expression"                          },                          "queryTimeout": "02:00:00"                      },                      "dataset": {                          "referenceName": "$dataset",                          "type": "DatasetReference"                      },       "firstRowOnly": $firstrow                  }              }       ',NULL,1,'OnPremiseSQLServer'),
('Copy Activity','CP_DataSource_DataDestination',1,'{"name": "$CopyActivityName","type": "Copy","dependsOn": [{
      "activity": "$dependson",
      "dependencyConditions": [ "$dependencyConditions" ]
    }],"policy": {    "timeout": "7.00:00:00",    "retry": 0,    "retryIntervalInSeconds": 30,    "secureOutput": false,    "secureInput": false},"userProperties": [],"typeProperties": {    "source": {        "type": "$Source",        "sqlReaderQuery": {            "value": "$sqlReaderQuery",            "type": "Expression"        },        "queryTimeout": "02:00:00"    },    "sink": {        "type": "$Sink",        "storeSettings": {            "type": "AzureBlobFSWriteSettings"        }    },    "enableStaging": false},"inputs": [    {        "referenceName": "$inputDatasetReference",        "type": "DatasetReference"    }],"outputs": [    {        "referenceName": "$outputDatasetReference",        "type": "DatasetReference",        "parameters": {            $parameters            }        }    ]                          }',NULL,1,'azureSQLDatabase'),
('For Each Activity','ForEachActivity',1,'   {                  "name": "$foreachactivityname",                  "type": "ForEach",                  "dependsOn": [                      {                          "activity": "$dependson",                          "dependencyConditions": [                              "$dependencyConditions"                          ]                      }                  ],                  "userProperties": [],                  "typeProperties": {                      "items": {                          "value": "@activity(''$dependentactivityname'').output.value",                          "type": "Expression"                      },                      "batchCount": $batchCount,       "isSequential": $isSequential,       "activities": [$activityjsoncode]                         }              }',NULL,NULL,NULL),
('Custom Logging','SP_Custom_Logging',1,'   {      "name": "$SPActivityName",      "description":"Description",      "type": "SqlServerStoredProcedure",     "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],     "linkedServiceName": {          "referenceName": "$MetadataDBLinkedServiceName",       "type": "LinkedServiceReference"      },      "typeProperties": {              "storedProcedureName": "$SPName",          "storedProcedureParameters": $SPParameters            }      }  }','1',NULL,NULL),
('Copy Activity','CP_DataSource_DataDestination',1,'  {"name": "$CopyActivityName","type": "Copy","dependsOn": [{
      "activity": "$dependson",
      "dependencyConditions": [ "$dependencyConditions" ]
    }],"policy": {   "timeout": "7.00:00:00",    "retry": 0,    "retryIntervalInSeconds": 30,    "secureOutput": false,    "secureInput": false},  "userProperties": [],"typeProperties": {    "source": {        "type": "$Source",        "sqlReaderQuery": {        "value": "$sqlReaderQuery",            "type": "Expression"        },        "queryTimeout": "02:00:00"    },     "sink": {        "type": "$Sink",        "storeSettings": {            "type": "AzureBlobFSWriteSettings"        }    },    "enableStaging": false},"inputs": [    {        "referenceName": "$inputDatasetReference",        "type": "DatasetReference"    }],"outputs": [    {        "referenceName": "$outputDatasetReference",        "type": "DatasetReference",        "parameters": {            $parameters            }        }    ]                          }   ',NULL,NULL,'OnPremiseSQLServer'),
('Copy Activity','CP_DataSource_DataDestination',1,'          {"name": "$CopyActivityName","type": "Copy","dependsOn": [         {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }  ],"policy": {      "timeout": "7.00:00:00",    "retry": 0,     "retryIntervalInSeconds": 30,       "secureOutput": false,    "secureInput": false},  "userProperties": [],    "typeProperties": {          "source": {                          "type": "RestSource",                                "httpRequestTimeout": "00:01:40",                            "requestInterval": "00.00:00:00.010",                         "requestMethod": "GET"    ,  "additionalHeaders": {
                            "Authorization": { "value": "@concat(''Bearer '',activity(''GetToken'').output.access_token)", "type": "Expression"
                            }
                        }                  },    "sink": {          "type": "$Sink",        "storeSettings": {            "type": "AzureBlobFSWriteSettings"        }  ,"formatSettings": {          "type": "JsonWriteSettings",          "filePattern": "setOfObjects"        }  },      "enableStaging": false},"inputs": [    {        "referenceName": "$inputDatasetReference",              "type": "DatasetReference"    }],"outputs": [    {        "referenceName": "$outputDatasetReference",               "type": "DatasetReference" ,"parameters": {            $parameters            }         } ]                          }             ',NULL,NULL,'RestService'),
('Get Token','GetToken',1,'{ "name": "GetToken","description": "Use this Web activity to get bearer token","type": "WebActivity","dependsOn": [               {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }       ],"policy": {"timeout": "7.00:00:00","retry": 0,"retryIntervalInSeconds": 30,"secureOutput": false,"secureInput": false},"userProperties": [],"typeProperties": {"url": "https://login.microsoftonline.com/$master_tenantId/oauth2/token","method": "POST",    "headers": { "Content-Type": "application/x-www-form-urlencoded" },"body": { "value":"@concat(''grant_type=client_credentials&client_id=$master_servicePrincipalId&client_secret='',activity(''GetSPNKey'').output.Value)",  "type": "Expression"	  }  }}',NULL,NULL,NULL),
('Get SPNKey from Vault','GetSPNKey',1,'{"name": "GetSPNKey", "type": "WebActivity","dependsOn": [               {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }       ],"policy": {"timeout": "7.00:00:00","retry": 0,"retryIntervalInSeconds": 30,"secureOutput": true,"secureInput": false},"userProperties": [],"typeProperties": {"url": "https://$master_keyvaultname.vault.azure.net/secrets/$master_servicePrincipalKey/?api-version=7.0","method": "GET","authentication": {"type": "MSI","resource": "https://vault.azure.net"}}}',NULL,NULL,NULL)
,('Copy Activity','CP_DataSource_DataDestination',1,'{"name": "$CopyActivityName","type": "Copy","dependsOn": [{
      "activity": "$dependson",
      "dependencyConditions": [ "$dependencyConditions" ]
    }],"policy": {   "timeout": "7.00:00:00",    "retry": 0,    "retryIntervalInSeconds": 30,    "secureOutput": false,    "secureInput": false},  "userProperties": [],"typeProperties": {    "source": {        "type": "$Source",        "oracleReaderQuery": {        "value": "$oracleReaderQuery",            "type": "Expression"        },        "queryTimeout": "02:00:00"    },     "sink": {        "type": "$Sink",        "storeSettings": {            "type": "AzureBlobFSWriteSettings"        }    },    "enableStaging": false},"inputs": [    {        "referenceName": "$inputDatasetReference",        "type": "DatasetReference"    }],"outputs": [    {        "referenceName": "$outputDatasetReference",        "type": "DatasetReference",        "parameters": {            $parameters            }        }    ]                          }   ',NULL,NULL,'OnPremiseOracle')
,
('Copy Activity Logging','SP_CopyActivity_Logging',1,' {      "name": "$SPActivityName",      "description":"Description",      "type": "SqlServerStoredProcedure",     "dependsOn": [                      {                          "activity": "$dependson",                   "dependencyConditions": [                              "$dependencyConditions"                           ]                      }                  ],     "linkedServiceName": {          "referenceName": "$MetadataDBLinkedServiceName",       "type": "LinkedServiceReference"      },      "typeProperties": {              "storedProcedureName": "$SPName",          "storedProcedureParameters": $SPParameters            }      }  ',NULL,NULL,NULL)
,

('Set Variable','SetVariable',1,'{
  "name": "$SetVaraibleActivityName",
  "type": "SetVariable",
  "dependsOn": [
    {
      "activity": "$dependson",
      "dependencyConditions": [
        "$dependencyConditions"
      ]
    }
  ],
  "userProperties": [],
  "typeProperties": {
    "variableName": "srcmaxval",
    "value": {
      "value": "@activity(''$dependson'').output.firstrow.maxval",
      "type": "Expression"
    }
  }
}',NULL,NULL,NULL),
('Update max refresh','SP_UpdateMaxRefresh',1,'{
  "name": "$SPActivityName",
  "description": "Description",
  "type": "SqlServerStoredProcedure",
  "dependsOn": [
    {
      "activity": "$dependson",
      "dependencyConditions": [ "$dependencyConditions" ]
    }
  ],
  "linkedServiceName": {
    "referenceName": "$MetadataDBLinkedServiceName",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "storedProcedureName": "$SPName",
    "storedProcedureParameters": $SPParameters
  }
}  
',NULL,NULL,NULL),
('IfCondition','If_Condition',1,'    {    "name": "$ifactivityname",    "type": "IfCondition",    "dependsOn": [      {        "activity": "$dependson",        "dependencyConditions": [ "$dependencyConditions" ]      }    ],    "userProperties": [],    "typeProperties": {      "expression": {        "value": "@greater(int(activity(''FE_LKP_CNT'').output.firstRow.cnt),0)",        "type": "Expression"      },      "ifFalseActivities": [ $ifFalseActivityCode ],      "ifTrueActivities": [ $ifTrueActivityCode ]    }  }  '
,NULL,NULL,NULL)


MERGE [T_List_Activities] AS mrg
USING (SELECT s.* FROM @SrcActivities s
      ) AS src
ON mrg.ActivityName = src.ActivityName
AND ISNULL(mrg.SourceType,'') = ISNULL(src.SourceType,'')
WHEN MATCHED THEN 
   UPDATE SET mrg.ActivityStandardName = src.ActivityStandardName,
   mrg.Enabled = src.Enabled,
   mrg.[JsonCode] = src.code,
   mrg.linkedserverrequired = src.linkedserverrequired,
   mrg.datasetrequired = src.datasetrequired,
   mrg.SourceType = src.SourceType
WHEN NOT MATCHED THEN
INSERT (ActivityName,
ActivityStandardName,
           Enabled,
           [JsonCode],
           linkedserverrequired,
           datasetrequired,
           SourceType
           )
VALUES(    src.ActivityName
           ,src.ActivityStandardName
           ,src.Enabled
           ,src.code
           ,src.linkedserverrequired,
           src.datasetrequired
           ,src.SourceType);



Print 'End - Inserting data to list activities table'

GO


Print 'Start - Inserting data to list activity parameters table'


DECLARE @SrcactivityParameters as TABLE
( ParameterName VARCHAR (100) , ParameterValue VARCHAR (8000) , ActivityName NVARCHAR (255),SourceType VARCHAR(200))

INSERT INTO @SrcactivityParameters
( ParameterName,ParameterValue,ActivityName,SourceType)
VALUES
('InvokedPipelineName','','Execute Pipeline',NULL),
('condition','','Filter Activity',NULL),
('inputarray','','Filter Activity',NULL),
('isSequential','false','For Each Activity',NULL),
('Metadataactivityname','','Get Metadata Activity',NULL),
('filedlist','','Get Metadata Activity',NULL),
('MyDataset','','Get Metadata Activity',NULL),
('Name_of_the_activity','','If Activity',NULL),
('LookupActivityname','','Lookup Activity','azureSQLDatabase'),
('query','select SS.Name as Schema_Name, ST.Name as Table_Name FROM SYS.TABLES ST JOIN SYS.SCHEMAS SS ON SS.schema_id= ST.schema_id','Lookup Activity','azureSQLDatabase'),
('dataset','','Lookup Activity','azureSQLDatabase'),
('firstrow','false','Lookup Activity','azureSQLDatabase'),
('foreachactivityname','','For Each Activity',NULL),
('dependson','','For Each Activity',NULL),
('dependencyConditions','','For Each Activity',NULL),
('dependentactivityname','','For Each Activity',NULL),
('batchCount','20','For Each Activity',NULL),
('activityjsoncode','','For Each Activity',NULL),
('dependson','','Lookup Activity','azureSQLDatabase'),
('CopyActivityName','CP_SqlServer_ADLSParquet','Copy Activity','azureSQLDatabase'),
('Source','AzureSqlSource','Copy Activity','azureSQLDatabase'),
('Sink','ParquetSink','Copy Activity','azureSQLDatabase'),
('inputDatasetReference','','Copy Activity','azureSQLDatabase'),
('outputDatasetReference','','Copy Activity','azureSQLDatabase'),
('dependson','','Copy Activity','azureSQLDatabase'),
('dependencyConditions','','Copy Activity','azureSQLDatabase'),
('parameters','       ""filename"": {""value"": ""@concat(item().tablename,''_'',utcnow())"",""type"": ""Expression""},                                          ""directory"": ""@item().tablename"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter""','Copy Activity','azureSQLDatabase'),
('sqlReaderQuery','@if(equals(item().IsIncremental,true),concat(item().Query,'' WHERE '',item().LastRefreshedBasedOn ,'' > CAST('''''',item().LastRefreshedDateTime,'''''' AS Datetime) AND '',item().LastRefreshedBasedOn,'' <= CAST('''''',activity(''FE_LKP'').output.firstrow.maxval,'''''' AS Datetime)''),item().Query)','Copy Activity','azureSQLDatabase'),
('SPName','usp_Log_PipelineStatus','Custom Logging',NULL),
('SPParameters','    { ""In_PipelineName"": {""value"":      {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},                     ""type"": ""String""                          },    ""In_PipelineStatus"": {                              ""value"": ""$pipelinestatus"",          ""type"": ""String""                          },                   ""In_ExecutionStartTime"": {                                 ""value"": {                                 ""value"": ""@utcnow()"",          ""type"": ""Expression""                              },                       ""type"": ""Datetime""                          },                           ""In_ExecutionEndTime"": {                              ""value"": ""@utcnow()"",                         ""type"": ""Datetime""                          }            ,              ""In_PipelineRunID"": {""value"":      {""value"": ""@pipeline().RunId"",""type"": ""Expression""},                     ""type"": ""String""                          }  ','Custom Logging',NULL),
('MetadataDBLinkedServiceName','','Custom Logging',NULL),
('SPActivityName','','Custom Logging',NULL),
('dependson','','Custom Logging',NULL),
('dependencyConditions','','Custom Logging',NULL),
('dependencyConditions','','Lookup Activity','azureSQLDatabase'),
('CopyActivityName','CP_SqlServer_ADLSParquet','Copy Activity','OnPremiseSQLServer'),
('Source','AzureSqlSource','Copy Activity','OnPremiseSQLServer'),
('Sink','ParquetSink','Copy Activity','OnPremiseSQLServer'),
('inputDatasetReference','','Copy Activity','OnPremiseSQLServer'),
('outputDatasetReference','','Copy Activity','OnPremiseSQLServer'),
('dependson','','Copy Activity','OnPremiseSQLServer'),
('dependencyConditions','','Copy Activity','OnPremiseSQLServer'),
('parameters','      ""filename"": {""value"": ""@concat(item().tablename,''_'',utcnow())"",""type"": ""Expression""},                                          ""directory"": ""@item().tablename"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter""','Copy Activity','OnPremiseSQLServer'),
('sqlReaderQuery','@if(equals(item().IsIncremental,true),concat(item().Query,'' WHERE '',item().LastRefreshedBasedOn ,'' > CAST('''''',item().LastRefreshedDateTime,'''''' AS Datetime) AND '',item().LastRefreshedBasedOn,'' <= CAST('''''',activity(''FE_LKP'').output.firstrow.maxval,'''''' AS Datetime)''),item().Query)','Copy Activity','OnPremiseSQLServer'),
('CopyActivityName','CP_RESTService_ADLSParquet','Copy Activity','RestService'),
('Source','RestService','Copy Activity','RestService'),
('Sink','ParquetSink','Copy Activity','RestService'),
('inputDatasetReference','','Copy Activity','RestService'),
('outputDatasetReference','','Copy Activity','RestService'),
('parameters','""filename"": ""output"",                                         ""directory"": ""restserviceoutput"",                                                ""fileformat"": ""json"",                                                ""fileextension"": ""json"",                                ""columnDelimiter"": "" ""','Copy Activity','RestService'),
('dependson','','Get Token',NULL),
('dependencyConditions','','Get Token',NULL),
('dependson','','Get SPNKey from Vault',NULL),
('dependencyConditions','','Get SPNKey from Vault',NULL),
('dependson','','Copy Activity','RestService'),
('dependencyConditions','','Copy Activity','RestService'),
('CopyActivityName','CP_Oracle_ADLSParquet','Copy Activity','OnPremiseOracle'),
('Source','OracleSource','Copy Activity','OnPremiseOracle'),
('Sink','ParquetSink','Copy Activity','OnPremiseOracle'),
('inputDatasetReference','','Copy Activity','OnPremiseOracle'),
('outputDatasetReference','','Copy Activity','OnPremiseOracle'),
('dependson','','Copy Activity','OnPremiseOracle'),
('dependencyConditions','','Copy Activity','OnPremiseOracle'),
('parameters','      ""filename"": {""value"": ""@concat(''item().tablename,''_'',utcnow())"",""type"": ""Expression""},                                          ""directory"": ""@item().tablename"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter""','Copy Activity','OnPremiseOracle'),
('oracleReaderQuery','@if(equals(item().IsIncremental,true),concat(item().Query,'' WHERE '',item().LastRefreshedBasedOn ,'' > CAST('''''',item().LastRefreshedDateTime,'''''' AS Datetime) AND '',item().LastRefreshedBasedOn,'' <= CAST('''''',activity(''FE_LKP'').output.firstrow.maxval,'''''' AS Datetime)''),item().Query)','Copy Activity','OnPremiseOracle'),
('SPName','usp_InsertPipelineCopyLogDetails','Copy Activity Logging',NULL),
('SPParameters','   {""In_PipelineRunID"": {""value"": {""value"": ""@pipeline().RunId"",""type"": ""Expression""},""type"": ""Guid""},""In_RowsCopied"": {""value"": {""value"": ""@activity(''$SP_CopyActivityLogging_dependson'').output.rowsCopied"",""type"": ""Expression""},""type"": ""Int64""  },""In_RowsRead"": {""value"": {""value"": ""@activity(''$SP_CopyActivityLogging_dependson'').output.rowsRead"",""type"": ""Expression""},""type"": ""Int64""},  ""In_Duration"": {""value"": {""value"": ""@activity(''$SP_CopyActivityLogging_dependson'').output.copyDuration"",""type"": ""Expression""},""type"": ""Int16""},  ""In_Status"": {""value"": {""value"": ""@activity(''$SP_CopyActivityLogging_dependson'').output.executionDetails[0].status"",""type"": ""Expression""},""type"": ""String""},""In_StartTime"": { ""value"": {  ""value"": ""@activity(''$SP_CopyActivityLogging_dependson'').output.executionDetails[0].start"",""type"": ""Expression""},""type"": ""Datetime""},""In_EndTime"": {  ""value"": {""value"": ""@utcnow()"",""type"": ""Expression""},""type"": ""Datetime""},""In_EntityName"": {""value"": {""value"": ""@item().tablename"",""type"": ""Expression""},""type"": ""String""  }  }  ','Copy Activity Logging',NULL),
('MetadataDBLinkedServiceName','','Copy Activity Logging',NULL),
('SPActivityName','','Copy Activity Logging',NULL),
('dependson','','Copy Activity Logging',NULL),
('dependencyConditions','','Copy Activity Logging',NULL),
('SPName','usp_UpdateMaxRefreshDate','Update max refresh',NULL),
('SPParameters','{""TableName"": { ""value"": {""value"": ""@item().TableName"", ""type"": ""Expression"" },""type"": ""String""},""SchemaName"": {
""value"": {""value"": ""@item().SchemaName"",""type"": ""Expression""},""type"": ""String""},
""PipelineName"": {""value"": {""value"": ""@pipeline().Pipeline"",""type"": ""Expression""},""type"": ""String""},
""MaxRefreshDateTime"": {""value"": {""value"": ""@activity(''FE_LKP'').output.firstrow.maxval"",""type"": ""Expression""},""type"": ""String""}
}','Update max refresh',NULL),
('MetadataDBLinkedServiceName','','Update max refresh',NULL),
('SPActivityName','','Update max refresh',NULL),
('dependson','','Update max refresh',NULL),
('dependencyConditions','','Update max refresh',NULL),
('SetVaraibleActivityName','','Set Variable',NULL),
('dependson','','Set Variable',NULL),
('dependencyConditions','','Set Variable',NULL),
('LookupActivityname','','Lookup Activity','SalesforceKeyVault'),
('query','select SS.Name as Schema_Name, ST.Name as Table_Name FROM SYS.TABLES ST JOIN SYS.SCHEMAS SS ON SS.schema_id= ST.schema_id','Lookup Activity','SalesforceKeyVault'),
('dataset','','Lookup Activity','SalesforceKeyVault'),
('firstrow','false','Lookup Activity','SalesforceKeyVault'),
('dependson','','Lookup Activity','SalesforceKeyVault'),
('dependencyConditions','','Lookup Activity','SalesforceKeyVault'),
('ifactivityname','','IfCondition',NULL),
('dependson','','IfCondition',NULL),
('dependencyConditions','','IfCondition',NULL),
('ifFalseActivityCode','','IfCondition',NULL),
('ifTrueActivityCode','','IfCondition',NULL),
('LookupActivityname','','Lookup Activity','OnPremiseSQLServer'),
('query','select SS.Name as Schema_Name, ST.Name as Table_Name FROM SYS.TABLES ST JOIN SYS.SCHEMAS SS ON SS.schema_id= ST.schema_id','Lookup Activity','OnPremiseSQLServer'),
('dataset','','Lookup Activity','OnPremiseSQLServer'),
('firstrow','false','Lookup Activity','OnPremiseSQLServer'),
('dependson','','Lookup Activity','OnPremiseSQLServer'),
('dependencyConditions','','Lookup Activity','OnPremiseSQLServer')

MERGE [T_List_Activity_Parameters] AS mrg
USING (
    SELECT S.*,t.ActivityId AS Id FROM @SrcactivityParameters s
    INNER JOIN T_List_Activities t
    ON s.ActivityName = t.[ActivityName]
    AND ISNULL(s.SourceType,'') = ISNULL(t.SourceType,'')
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