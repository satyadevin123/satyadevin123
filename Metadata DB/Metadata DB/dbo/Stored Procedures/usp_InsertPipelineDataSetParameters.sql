
CREATE PROCEDURE usp_InsertPipelineDataSetParameters
(@ParameterName NVARCHAR(200),@ParameterValue NVARCHAR(200),@DatasetId INT)
AS
BEGIN
 INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
            VALUES(@ParameterName,@ParameterValue,@DatasetId)

END

