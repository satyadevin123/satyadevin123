
CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSetParameters]
(@LinkedServiceId INT,@DatasetId INT,@PipelineId INT)
AS
BEGIN
declare @LinkedServiceType VARCHAR(200)
DECLARE @datasetparamname varchar(200)
DECLARE @datasetparamval varchar(200)
DECLARE @lsparamname varchar(200)
DECLARE @lsparamval varchar(200)


SELECT @LinkedServiceType = tll.LinkedService_Name
FROM T_Pipeline_LinkedServices tpl JOIN T_List_LinkedServices tll
ON tpl.LinkedServiceId = tll.Id
WHERE tpl.Id = @LinkedServiceId

SET @datasetparamname = '$'+CAST(@LinkedServiceId AS NVARCHAR(10))+'_'+@LinkedServiceType+'DatasetName'
SET @datasetparamval = 'DS_POC_'+@LinkedServiceType+'_'+CAST(@LinkedServiceId AS NVARCHAR(10))
            
SET @lsparamname = '$'+CAST(@LinkedServiceId AS NVARCHAR(10))+'_'+@LinkedServiceType+'LinkedServiceName'
SET @lsparamval = 'LS_POC_'+@LinkedServiceType+'_'+CAST(@LinkedServiceId AS NVARCHAR(10))


INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId,pipelineid )
SELECT REPLACE(tldp.ParameterName,'$','$'+CAST(@LinkedServiceId AS nvarchar)+'_') AS ParameterName,
ParameterValue,@DatasetId,@PipelineId
FROM T_List_Dataset_Parameters tldp
INNER JOIN T_List_DataSets tld
ON tldp.DatasetId = tld.id
INNER JOIN T_Pipeline_DataSets tpd
ON tld.id = tpd.DataSetId
WHERE tpd.Id = @DatasetId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @datasetparamval
WHERE ParameterName = @datasetparamname
AND DatasetId = @DatasetId
AND pipelineid= @PipelineId

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue = @lsparamval
WHERE ParameterName = @lsparamname
AND DatasetId = @DatasetId
AND pipelineid= @PipelineId


END
GO


