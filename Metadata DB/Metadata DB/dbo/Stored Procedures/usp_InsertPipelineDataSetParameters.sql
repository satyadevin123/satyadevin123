
CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSetParameters]
(@ParameterName NVARCHAR(200),@ParameterValue NVARCHAR(200),@DatasetId INT,@PipelineId INT)
AS
BEGIN
 INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId,pipelineid )
            VALUES(@ParameterName,@ParameterValue,@DatasetId,@PipelineId)

END
GO


