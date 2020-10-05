
CREATE PROCEDURE usp_updatepipelineactivityparameters
(@Category NVARCHAR(200),@DatasetId INT,@PipelineId INT,@LinkedServiceRef VARCHAR(200)='',@ActDescription VARCHAR(30)='')
As
begin

DECLARE @DatasetName NVARCHAR(200)
DECLARE @Lkpactid INT
DECLARE @FELkpactid INT
DECLARE @CPactid INT

SELECT @Lkpactid = TPA.[PipelineActivityId]
FROM T_Pipeline_Activities TPA INNER JOIN T_List_Activities TLA
ON TLA.ActivityId = TPA.ActivityID
WHERE PipelineId = @PipelineId AND TLA.ActivityName = 'Lookup Activity' AND TPA.Activityname like 'LKP_%'

SELECT @FELkpactid = TPA.[PipelineActivityId]
FROM T_Pipeline_Activities TPA INNER JOIN T_List_Activities TLA
ON TLA.ActivityId = TPA.ActivityID
WHERE PipelineId = @PipelineId AND TLA.ActivityName = 'Lookup Activity' AND TPA.Activityname = 'FE_LKP'


SELECT @CPactid = TPA.[PipelineActivityId]
FROM T_Pipeline_Activities TPA INNER JOIN T_List_Activities TLA
ON TLA.ActivityId = TPA.ActivityID
WHERE PipelineId = @PipelineId AND TLA.ActivityName = 'Copy Activity'
AND 
TPA.Activityname like CASE WHEN @ActDescription = 'SchemaCopy' THEN 'SchemaCP%' ELSE 'CP%' END 



IF (@DatasetId <> 0)
BEGIN

SELECT TOP 1 @DatasetName = TPDP.ParameterValue
FROM T_Pipeline_DataSets TPD
INNER JOIN T_Pipeline_Dataset_Parameters TPDP
ON TPD.PipelineDatasetId = TPDP.PipelineDatasetId
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


UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @DatasetName WHERE ParameterName like '%dataset%'
and pipelineid = @PipelineId AND PipelineActivityId = @FELkpactid


UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = 'true' WHERE ParameterName like '%firstrow%'
and pipelineid = @PipelineId AND PipelineActivityId = @FELkpactid


END


IF(@Category = 'CPOutputReference')
BEGIN

UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @DatasetName WHERE ParameterName like '%outputdatasetreference%'
and pipelineid = @PipelineId AND PipelineActivityId = @CPactid


UPDATE dbo.T_Pipeline_Activity_Parameters 
SET Parametervalue = CASE WHEN @ActDescription = 'SchemaCopy' THEN
'@concat(''SELECT ''''COLUMN|FIELDNAME|KEY|TYPE|LENGTH|OUTPUTLEN|DECIMALS'''' UNION ALL '',  ''select CONCAT(ROW_NUMBER() OVER(ORDER BY PipelineSourceColumnDetailsId),''''|'''',ColumnName,''''|'''',ISNULL([Key],''''''''),''''|'''',[Type],''''|'''',ISNULL([Length],''''''''),''''|'''',ISNULL(OutputLen,''''''''),''''|'''',ISNULL(Decimals,'''''''')) from T_Pipeline_SourceColumnDetails ts inner join [T_Pipeline_Tables_ToBeMoved] t ON ts.PipelineSourceId = t.PipelineSourceId WHERE TableName ='''''', item().tablename ,'''''' AND SchemaName = '''''',item().schemaname,'''''' AND pipelineid =  '+CAST(@PipelineId AS VARCHAR)+''') '
ELSE Parametervalue END
WHERE pipelineid = @PipelineId AND PipelineActivityId = @CPactid
AND ParameterName like '%sqlReaderQuery%'


UPDATE dbo.T_Pipeline_Activity_Parameters 
SET Parametervalue = CASE WHEN @ActDescription = 'SchemaCopy' THEN
'       ""filename"": {""value"": ""@concat(''S_'',item().tablename,''_'',utcnow())"",""type"": ""Expression""},                                          ""directory"": ""@item().tablename"",                                          ""fileformat"": ""@item().fileformat"",                                          ""fileextension"": ""@item().fileextension"",                                          ""columnDelimiter"": ""@item().columndelimiter""'
ELSE Parametervalue END
WHERE pipelineid = @PipelineId AND PipelineActivityId = @CPactid 
AND ParameterName like '%parameters%' 

END

IF(@Category = 'LKPQuery')
BEGIN

declare @sinkfileformat varchar(100)
declare @sinkfileextension varchar(100)
declare @sinkcoldelimiter varchar(3)
declare @qry varchar(2000)

SELECT @sinkfileformat =  ParameterValue 
FROM T_Pipeline_Dataset_Parameters WHERE PipelineId = @PipelineId
AND ParameterName like '%fileformat%' and PipelineDataSetId = @DatasetId

SELECT @sinkfileextension =  ParameterValue 
FROM T_Pipeline_Dataset_Parameters WHERE PipelineId = @PipelineId
AND ParameterName like '%fileextension%' and PipelineDataSetId = @DatasetId

SELECT @sinkcoldelimiter =  ParameterValue 
FROM T_Pipeline_Dataset_Parameters WHERE PipelineId = @PipelineId
AND ParameterName like '%ColumnDelimiter%' and PipelineDataSetId = @DatasetId


set @qry = 
'SELECT SchemaName,TableName,'''+@sinkfileformat+''' as fileformat,'''+@sinkfileextension+''' as fileextension,'''
+@sinkcoldelimiter+''' as columnDelimiter,Query, IsIncremental, LastRefreshedBasedOn, 
ISNULL(LastRefreshedDateTime,CAST(''1900-01-01 00:00:00.000'' AS DATETime)) AS LastRefreshedDateTime 
FROM t_pipeline_tables_tobemoved WHERE pipelineid = '+ cAST(@PipelineId AS VARCHAR)




UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @qry WHERE ParameterName like '%query%'
and pipelineid = @PipelineId AND PipelineActivityId = @Lkpactid

set @qry =
'@if(equals(item().IsIncremental,true),concat(''select max('',item().LastRefreshedBasedOn,'') as maxval from '',''['',item().schemaname,'']'',''.'',''['',item().tablename,'']''),''SELECT ''''NULL'''' AS maxval'')'

UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @qry WHERE ParameterName like '%query%'
and pipelineid = @PipelineId AND PipelineActivityId = @FELkpactid

END
end
