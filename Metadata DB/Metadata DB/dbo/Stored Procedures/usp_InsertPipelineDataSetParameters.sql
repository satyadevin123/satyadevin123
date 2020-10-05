
CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSetParameters]
(@LinkedServiceName VARCHAR(200),@DataSetId INT,@PipelineId INT)
AS
BEGIN
declare @LinkedServiceType VARCHAR(200)
DECLARE @datasetparamname varchar(200)
DECLARE @datasetparamval varchar(200)
DECLARE @lsparamname varchar(200)
DECLARE @lsparamval varchar(200)

SELECT  @datasetparamval = DataSetName FROM
T_Pipeline_DataSets WHERE PipelineDataSetId = @DataSetId
AND pipelineid= @PipelineId

SET @lsparamval = 'LS_'+@LinkedServiceName


INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,PipelineDataSetId,pipelineid )
SELECT REPLACE(tldp.ParameterName,'$','$'+CAST(@DataSetId AS nvarchar)+'_'+CAST(@pipelineid AS nvarchar)+'_') AS ParameterName,
ParameterValue,@DataSetId,@PipelineId
FROM T_List_DataSet_Parameters tldp
INNER JOIN T_List_DataSets tld
ON tldp.DataSetId = tld.[DataSetId]
INNER JOIN T_Pipeline_DataSets tpd
ON tld.[DataSetId] = tpd.DataSetId
WHERE tpd.[PipelineDataSetId] = @DataSetId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @datasetparamval
WHERE ParameterName like '%Datasetname%'
AND PipelineDataSetId = @DataSetId
AND pipelineid= @PipelineId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @lsparamval
WHERE ParameterName like '%LinkedServicename%'
AND PipelineDataSetId = @DataSetId
AND pipelineid= @PipelineId


END
GO


