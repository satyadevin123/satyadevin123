

CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSets]
(@LinkedServiceName NVARCHAR(200),@PipelineId INT,@AdditionalConfigurationType NVARCHAR(100) = '',@AdditionalConfigurationValue NVARCHAR(100)='')
AS
BEGIN

DECLARE @PipelineLinkedServicesID INT

SELECT TOP 1 @PipelineLinkedServicesID = PipelineLinkedServicesID
FROM T_Pipeline_LinkedServices WHERE LinkedServiceName = @LinkedServiceName

INSERT INTO dbo.T_Pipeline_DataSets (PipelineId,LinkedServericeId,DataSetId )
SELECT @PipelineId,tpl.[PipelineLinkedServicesID],tld.[DatasetId] FROM dbo.T_List_DataSets tld inner join 
dbo.T_List_LinkedServices tll on tld.[LinkedServiceId] = tll.[LinkedServiceId] inner join dbo.T_Pipeline_LinkedServices tpl 
ON tpl.LinkedServiceId = tll.[LinkedServiceId]
where tpl.[PipelineLinkedServicesID] = @PipelineLinkedServicesID
AND ISNULL(tld.AdditionalConfigurationType,'')=@AdditionalConfigurationType
AND ISNULL(tld.AdditionalConfigurationValue,'')=@AdditionalConfigurationValue

END
GO


