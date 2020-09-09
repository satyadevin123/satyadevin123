
CREATE PROCEDURE usp_updatepipelineactivityparameters
(@Category NVARCHAR(200),@DatasetId INT,@PipelineId INT,@LinkedServiceRef VARCHAR(200)='')
As
begin

DECLARE @DatasetName NVARCHAR(200)
DECLARE @Lkpactid INT
DECLARE @CPactid INT

SELECT @Lkpactid = TPA.PipelineStepsId
FROM T_Pipeline_Activities TPA INNER JOIN T_List_Activities TLA
ON TLA.ActivityId = TPA.ActivityID
WHERE PipelineId = @PipelineId AND TLA.ActivityName = 'Lookup Activity'

SELECT @CPactid = TPA.PipelineStepsId
FROM T_Pipeline_Activities TPA INNER JOIN T_List_Activities TLA
ON TLA.ActivityId = TPA.ActivityID
WHERE PipelineId = @PipelineId AND TLA.ActivityName = 'Copy Activity'


IF (@DatasetId <> 0)
BEGIN

SELECT TOP 1 @DatasetName = TPDP.ParameterValue
FROM T_Pipeline_DataSets TPD
INNER JOIN T_Pipeline_Dataset_Parameters TPDP
ON TPD.PipelineDatasetId = TPDP.DatasetId
WHERE TPD.PipelineDatasetId = @DatasetId
AND TPDP.ParameterName like '%DatasetName%'

END

IF(@Category = 'LKPdataset')
BEGIN

SET @LinkedServiceRef = 'LS_'+ @LinkedServiceRef

UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @DatasetName WHERE ParameterName like '%dataset%'
and pipelineid = @PipelineId AND PipelineActivityId = @Lkpactid

UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @LinkedServiceRef WHERE ParameterName like '%MetadataDBLinkedServiceName%'
and pipelineid = @PipelineId 

END

IF(@Category = 'CPInputReference')
BEGIN

UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @DatasetName WHERE ParameterName like '%inputdatasetreference%'
and pipelineid = @PipelineId AND PipelineActivityId = @CPactid

END


IF(@Category = 'CPOutputReference')
BEGIN

UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @DatasetName WHERE ParameterName like '%outputdatasetreference%'
and pipelineid = @PipelineId AND PipelineActivityId = @CPactid

END

IF(@Category = 'LKPQuery')
BEGIN

declare @sinkfileformat varchar(100)
declare @sinkfileextension varchar(100)
declare @sinkcoldelimiter varchar(3)
declare @qry varchar(2000)

SELECT @sinkfileformat =  ParameterValue 
FROM T_Pipeline_Dataset_Parameters WHERE DatasetId = @DatasetId
AND ParameterName like '%fileformat%'

SELECT @sinkfileextension =  ParameterValue 
FROM T_Pipeline_Dataset_Parameters WHERE DatasetId = @DatasetId
AND ParameterName like '%fileextension%'

SELECT @sinkcoldelimiter =  ParameterValue 
FROM T_Pipeline_Dataset_Parameters WHERE DatasetId = @DatasetId
AND ParameterName like '%ColumnDelimiter%'


set @qry = 
'SELECT Schema_Name,Table_Name,'''+@sinkfileformat+''' as fileformat,'''+@sinkfileextension+''' as fileextension,'''+@sinkcoldelimiter+''' as columnDelimiter FROM t_pipeline_tables_tobemoved WHERE pipelineid = '+ cAST(@PipelineId AS VARCHAR)


UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @qry WHERE ParameterName like '%query%'
and pipelineid = @PipelineId AND PipelineActivityId = @Lkpactid

END



end
