CREATE procedure [dbo].[usp_generate_pipelinecode]
--@Load_Teradata_Tables varchar(500)
as
Declare @PipelineName varchar(500)
set @PipelineName =(select PipelineName from [dbo].[T_Pipelines] Where Enabled=1)
declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+[JsonCode] from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipeline_Activities] PS on P.[PipelineId] = PS.PipelineId
join [dbo].[T_List_Activities] LS on LS.[ActivityId] = PS.[ActivityID]
SELECT '{
	"$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
	"contentVersion": "1.0.0.0",
	"parameters": {
		"factoryName": {
			"type": "string",
			"metadata": "Data Factory name"
		},
		"AzureSql_gcdm_epi_gap": {
			"type": "string"
		},
		"Teradata_NewDEV_Azure_IR": {
			"type": "string"
		},
		"Teradata_Dev_AZ_IR": {
			"type": "string"
		}
	},
	"variables": {
		"factoryId": "[concat(''Microsoft.DataFactory/factories/'', parameters(''factoryName''))]"
	},
	"resources": [
		{
			"name": "[concat(parameters(''factoryName''), ''/'+@PipelineName+''')]",
			"type": "Microsoft.DataFactory/factories/pipelines",
			"apiVersion": "2018-06-01",
			"properties": {
				"activities": ['
					+@activity_code+'
		
	]
}'