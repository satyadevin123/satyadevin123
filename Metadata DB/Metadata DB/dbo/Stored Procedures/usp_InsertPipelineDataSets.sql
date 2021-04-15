CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSets]
(
	 @DataSetName VARCHAR(140)
	,@LinkedServiceName VARCHAR(140)
	,@PipelineId INT
	,@AdditionalConfigurationType VARCHAR(100) = ''
	,@AdditionalConfigurationValue VARCHAR(140)=''
)
AS
BEGIN

	DECLARE @PipelineLinkedServicesID INT

	SELECT 
			TOP 1 @PipelineLinkedServicesID = PipelineLinkedServicesID
	FROM	dbo.T_Pipeline_LinkedServices 
	WHERE	LinkedServiceName = @LinkedServiceName

	IF (
			NOT EXISTS 
			(SELECT 1 FROM dbo.T_Pipeline_DataSets WHERE PipelineId = @PipelineId AND DataSetName = @DataSetName )
	    )

		INSERT INTO dbo.T_Pipeline_DataSets 
		(
				PipelineId
				,LinkedServericeId
				,DataSetId
				,DataSetName
		)
		SELECT 
				@PipelineId
				,tpl.[PipelineLinkedServicesID]
				,tld.[DatasetId]
				,@DataSetName 
		FROM	
				dbo.T_List_DataSets tld 
				INNER JOIN dbo.T_List_LinkedServices tll 
				ON tld.[LinkedServiceId] = tll.[LinkedServiceId] 
				INNER JOIN dbo.T_Pipeline_LinkedServices tpl 
				ON tpl.LinkedServiceId = tll.[LinkedServiceId]
		WHERE	tpl.[PipelineLinkedServicesID] = @PipelineLinkedServicesID
				AND ISNULL(tld.AdditionalConfigurationType,'')=@AdditionalConfigurationType
				AND ISNULL(tld.AdditionalConfigurationValue,'')=@AdditionalConfigurationValue


END
GO


