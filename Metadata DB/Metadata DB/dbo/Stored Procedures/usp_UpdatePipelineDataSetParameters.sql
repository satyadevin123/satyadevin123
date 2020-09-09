CREATE PROCEDURE [dbo].[usp_UpdatePipelineDataSetParameters]
(@ParameterName NVARCHAR(200),@ParameterValue NVARCHAR(200),@DatasetId INT,@PipelineId INT)
AS
BEGIN

UPDATE T_Pipeline_DataSet_Parameters
SET ParameterValue  = @ParameterValue
WHERE ParameterName = @ParameterName
AND [PipelineDatasetId] = @DatasetId
AND pipelineid = @PipelineId

END
GO
