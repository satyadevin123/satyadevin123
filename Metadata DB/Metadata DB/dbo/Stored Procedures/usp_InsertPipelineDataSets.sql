
CREATE PROCEDURE usp_InsertPipelineDataSets
(@LinkedServiceName NVARCHAR(200),@LinkedServiceId INT,@PipelineId INT,@AdditionalConfigurationType NVARCHAR(100) = '',@AdditionalConfigurationValue NVARCHAR(100)='')
AS
BEGIN

INSERT INTO dbo.T_Pipeline_DataSets (PipelineId,LinkedServericeId,DataSetId )
SELECT @PipelineId,tpl.Id,tld.id FROM dbo.T_List_DataSets tld inner join 
dbo.T_List_LinkedServices tll on tld.LinkedService_id = tll.Id inner join dbo.T_Pipeline_LinkedServices tpl 
ON tpl.LinkedServiceId = tll.Id
where tll.LinkedService_Name = @LinkedServiceName and tpl.id = @LinkedServiceId
AND ISNULL(tld.AdditionalConfigurationType,'')=@AdditionalConfigurationType
AND ISNULL(tld.AdditionalConfigurationValue,'')=@AdditionalConfigurationValue

END

