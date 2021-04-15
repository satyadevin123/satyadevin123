
CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSetParameters]
(
	@LinkedServiceName VARCHAR(137),
	@DataSetId INT,
	@PipelineId INT
)
AS
BEGIN

	DECLARE @LinkedServiceType VARCHAR(260)
	DECLARE @datasetparamname varchar(200)
	DECLARE @datasetparamval varchar(MAX)
	DECLARE @lsparamname varchar(200)
	DECLARE @lsparamval varchar(MAX)

	SELECT  @datasetparamval = DataSetName 
	FROM	dbo.T_Pipeline_DataSets 
	WHERE	PipelineDataSetId = @DataSetId 
			AND pipelineid= @PipelineId

	SET @lsparamval = 'LS_'+@LinkedServiceName

	INSERT INTO dbo.T_Pipeline_DataSet_Parameters 
	(
		ParameterName
		,ParameterValue
		,PipelineDataSetId
		,PipelineId 
	)
	SELECT 
			REPLACE(tldp.ParameterName,'$','$'+CAST(@DataSetId AS nvarchar)+'_'+CAST(@pipelineid AS nvarchar)+'_') AS ParameterName
			,ParameterValue
			,@DataSetId
			,@PipelineId
	FROM	dbo.T_List_DataSet_Parameters tldp
			INNER JOIN dbo.T_List_DataSets tld
			ON tldp.DataSetId = tld.[DataSetId]
			INNER JOIN dbo.T_Pipeline_DataSets tpd
			ON tld.[DataSetId] = tpd.DataSetId
	WHERE	tpd.[PipelineDataSetId] = @DataSetId

	UPDATE	dbo.T_Pipeline_DataSet_Parameters
	SET		ParameterValue = @datasetparamval
	WHERE	ParameterName LIKE '%Datasetname%'
			AND PipelineDataSetId = @DataSetId
			AND PipelineId = @PipelineId

	UPDATE	dbo.T_Pipeline_DataSet_Parameters
	SET		ParameterValue = @lsparamval
	WHERE	ParameterName LIKE '%LinkedServicename%'
			AND PipelineDataSetId = @DataSetId
			AND PipelineId = @PipelineId


END
GO


