

CREATE PROCEDURE [dbo].[usp_InsertPipelineDataSets]
(@LinkedServiceName NVARCHAR(200),@LinkedServiceId INT,@PipelineId INT,@AdditionalConfigurationType NVARCHAR(100) = '',@AdditionalConfigurationValue NVARCHAR(100)='')
AS
BEGIN

INSERT INTO dbo.T_Pipeline_DataSets (PipelineId,LinkedServericeId,DataSetId )
SELECT @PipelineId,tpl.[PipelineLinkedServicesID],tld.[DatasetId] FROM dbo.T_List_DataSets tld inner join 
dbo.T_List_LinkedServices tll on tld.[LinkedServiceId] = tll.[LinkedServiceId] inner join dbo.T_Pipeline_LinkedServices tpl 
ON tpl.LinkedServiceId = tll.[LinkedServiceId]
where tll.[LinkedServiceName] = @LinkedServiceName and tpl.[PipelineLinkedServicesID] = @LinkedServiceId
AND ISNULL(tld.AdditionalConfigurationType,'')=@AdditionalConfigurationType
AND ISNULL(tld.AdditionalConfigurationValue,'')=@AdditionalConfigurationValue

END
GO


