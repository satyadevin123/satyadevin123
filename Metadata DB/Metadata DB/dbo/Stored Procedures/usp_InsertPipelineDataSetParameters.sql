
CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSetParameters]
(@LinkedServiceName VARCHAR(200),@DatasetId INT,@PipelineId INT)
AS
BEGIN
declare @LinkedServiceType VARCHAR(200)
DECLARE @datasetparamname varchar(200)
DECLARE @datasetparamval varchar(200)
DECLARE @lsparamname varchar(200)
DECLARE @lsparamval varchar(200)

SET @datasetparamval = 'DS_'+@LinkedServiceName+'_'+CAST(@DatasetId AS NVARCHAR(10))+'_'+CAST(@PipelineId AS NVARCHAR(10))
            
SET @lsparamval = 'LS_'+@LinkedServiceName


INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId,pipelineid )
SELECT REPLACE(tldp.ParameterName,'$','$'+CAST(@DatasetId AS nvarchar)+'_'+CAST(@pipelineid AS nvarchar)+'_') AS ParameterName,
ParameterValue,@DatasetId,@PipelineId
FROM T_List_Dataset_Parameters tldp
INNER JOIN T_List_DataSets tld
ON tldp.DatasetId = tld.[DatasetId]
INNER JOIN T_Pipeline_DataSets tpd
ON tld.[DatasetId] = tpd.DataSetId
WHERE tpd.[PipelineDatasetId] = @DatasetId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @datasetparamval
WHERE ParameterName like '%Datasetname%'
AND DatasetId = @DatasetId
AND pipelineid= @PipelineId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @lsparamval
WHERE ParameterName like '%LinkedServicename%'
AND DatasetId = @DatasetId
AND pipelineid= @PipelineId


END
GO


