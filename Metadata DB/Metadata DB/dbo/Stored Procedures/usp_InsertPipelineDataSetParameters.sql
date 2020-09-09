
CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSetParameters]
(@LinkedServiceId INT,@DatasetId INT,@PipelineId INT)
AS
BEGIN
declare @LinkedServiceType VARCHAR(200)
DECLARE @datasetparamname varchar(200)
DECLARE @datasetparamval varchar(200)
DECLARE @lsparamname varchar(200)
DECLARE @lsparamval varchar(200)


SELECT @LinkedServiceType = tll.[LinkedServiceName]
FROM T_Pipeline_LinkedServices tpl JOIN T_List_LinkedServices tll
ON tpl.LinkedServiceId = tll.[LinkedServiceId]
WHERE tpl.[PipelineLinkedServicesID] = @LinkedServiceId

SET @datasetparamname = '$'+CAST(@LinkedServiceId AS NVARCHAR(10))+'_'+@LinkedServiceType+'DatasetName'
SET @datasetparamval = 'DS_POC_'+@LinkedServiceType+'_'+CAST(@LinkedServiceId AS NVARCHAR(10))
            
SET @lsparamname = '$'+CAST(@LinkedServiceId AS NVARCHAR(10))+'_'+@LinkedServiceType+'LinkedServiceName'
SET @lsparamval = 'LS_POC_'+@LinkedServiceType+'_'+CAST(@LinkedServiceId AS NVARCHAR(10))


INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,[PipelineDatasetId],pipelineid )
SELECT REPLACE(tldp.ParameterName,'$','$'+CAST(@LinkedServiceId AS nvarchar)+'_') AS ParameterName,
ParameterValue,@DatasetId,@PipelineId
FROM T_List_Dataset_Parameters tldp
INNER JOIN T_List_DataSets tld
ON tldp.DatasetId = tld.[DatasetId]
INNER JOIN T_Pipeline_DataSets tpd
ON tld.[DatasetId] = tpd.DataSetId
WHERE tpd.[PipelineDatasetId] = @DatasetId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @datasetparamval
WHERE ParameterName = @datasetparamname
AND [PipelineDatasetId] = @DatasetId
AND pipelineid= @PipelineId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @lsparamval
WHERE ParameterName = @lsparamname
AND [PipelineDatasetId] = @DatasetId
AND pipelineid= @PipelineId


END
GO


