
$XMLfile = 'D:\Metadata PoC\XMLInput.xml'
[XML]$MetaDetails = Get-Content $XMLfile

<# function to log details to file #>
Function Log-Message([String]$Message) { Add-Content -Path "D:\Metadata PoC\MetadataCreationLogFile.txt" $Message }

<# SQL connection setup to the metadata database  #>

Log-Message "Beginning exeuction of the script:"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = poc-metadatadriven.database.windows.net; Database = MetadataDBPublishTest; Integrated Security = False; User ID = vsagala; Password = Pass@123;"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.Connection = $SqlConnection
Log-Message "Start :  Open Connection to Metadata database"
$SqlConnection.Open()
Log-Message "End :  Open Connection to Metadata database"

<# truncate the pipeline tables as part of each run #>

Log-Message "Start :  Trunate pipeline parameter,activity,dataset, linked server tables"
$SqlCmd.CommandText = "EXEC usp_TruncateParameterTables"
$SqlCmd.ExecuteNonQuery()
Log-Message "End :  Trunate pipeline parameter,activity,dataset, linked server tables"


foreach($ppdetail in $MetaDetails.Metadata.Pipelines.Pipeline){
Write-Host "Pipeline Name :" $ppdetail.Name

Log-Message "Start :  Inserted pipeline details in T_Pipelines table"
$SqlCmd.CommandText = "INSERT INTO [dbo].[T_Pipelines] (PipelineName, Enabled,EmailNotificationEnabled) VALUES ('"+$ppdetail.Name+"',1,0)"
$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipelines] "
$pipelineid = $SqlCmd.ExecuteScalar()

Log-Message "End :  Inserted pipeline details in T_Pipelines table"

<# update the master parameters based on input in the XML file #>

Log-Message "Start :  Update Master parameters related to Azure Env setup like RG,location, ADFname"
foreach($parameterdetail in $MetaDetails.Metadata.AzureEnvSetup.Parameters.Parameter){
$paramval = '"'+$parameterdetail.Value+'"'
$paramname = $parameterdetail.Name
$SqlCmd.CommandText = "UPDATE T_Master_Parameters_List SET ParameterValue = '" + $paramval + "' WHERE ParameterName = '" + $paramname + "'"
$SqlCmd.ExecuteNonQuery()
}
$irname = '"Azure-IR-ADF"'
$SqlCmd.CommandText = "UPDATE T_Master_Parameters_List SET ParameterValue = '$irname' WHERE ParameterName = '$nameofintegrationruntime'"
$SqlCmd.ExecuteNonQuery()
Log-Message "End :  Update Master parameters related to Azure Env setup like RG,location, ADFname"




<# Linked service and dataset for the metadata database #>
foreach($MetadataDB in $ppdetail.MetadataDB)
{
Log-Message "Start :  Insert the metadata details to T_Pipeline_LinkedServices table"

$type = $MetadataDB.Type
$SqlCmd.CommandText = "INSERT INTO [dbo].[T_Pipeline_LinkedServices] (PipelineId, LinkedServiceId) SELECT $pipelineid,Id   FROM [dbo].[T_List_LinkedServices] WHERE LinkedService_Name = '" + $MetadataDB.Type + "'"
$SqlCmd.ExecuteNonQuery()
$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_LinkedServices] "
$metadblinkedservice_id = $SqlCmd.ExecuteScalar()
$metadblinkedservicename = '"LS_POC_'+$type+'_'+$metadblinkedservice_id +'"'
Log-Message "End :  Insert the metadata db details to T_Pipeline_LinkedServices table"

Log-Message "Start :  Insert the metadata db parameter details to T_Pipeline_LinkedService_Parameters table"

$SqlCmd.CommandText = "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters_New] $metadblinkedservice_id, $pipelineid"

Write-Host "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters_New] $metadblinkedservice_id, $pipelineid"

$SqlCmd.ExecuteNonQuery()


foreach($parameterdetail in $MetadataDB.Parameters.Parameter){
$paramval = '"'+$parameterdetail.Value+'"'
#$SqlCmd.CommandText = "INSERT INTO [dbo].[T_Pipeline_LinkedService_Parameters] (ParameterName,ParameterValue, LinkedServerId,pipelineid) VALUES ('"+$metadblinkedservice_id+"_"+$parameterdetail.Name+"','"+$paramval+"',$metadblinkedservice_id,$pipelineid)"
$paramname = $parameterdetail.Name.Replace('$','$'+$metadblinkedservice_id+'_')
$SqlCmd.CommandText = "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = '$paramval' WHERE LinkedServerId = $metadblinkedservice_id AND PipelineId = $pipelineid AND ParameterName = '$paramname'"
Write-Host "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = '$paramval' WHERE LinkedServerId = $metadblinkedservice_id AND PipelineId = $pipelineid AND ParameterName = '$paramname'"
$SqlCmd.ExecuteNonQuery()

}

$linkedserviceparamname = '$'+$metadblinkedservice_id +'_'+$type+'LinkedServiceName'
$SqlCmd.CommandText = "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters]  SET ParameterValue = '$metadblinkedservicename' WHERE ParameterName = '$linkedserviceparamname' AND LinkedServerId = $metadblinkedservice_id AND PipelineId = $pipelineid"

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = '$irname' WHERE ParameterName like '%nameofintegrationruntime%' AND LinkedServerId = $metadblinkedservice_id AND PipelineId = $pipelineid"
$SqlCmd.ExecuteNonQuery()


Log-Message "End :  Insert the metadata db parameter details to T_Pipeline_LinkedService_Parameters"


Log-Message "Start :  Insert the metadata db dataset"

$SqlCmd.CommandText = "
INSERT INTO dbo.T_Pipeline_DataSets (PipelineId,LinkedServericeId,DataSetId )
SELECT $pipelineid,tpl.Id,tld.id FROM dbo.T_List_DataSets tld inner join dbo.T_List_LinkedServices tll on tld.LinkedService_id = tll.Id inner join dbo.T_Pipeline_LinkedServices tpl 
ON tpl.LinkedServiceId = tll.Id where tll.LinkedService_Name = '$type' and tpl.id = $metadblinkedservice_id
"

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_DataSets] "
$metadbdataset_id = $SqlCmd.ExecuteScalar()
$met = '$'+$metadblinkedservice_id+'_'+$type+'DatasetName'
$metadbds = 'DS_POC_'+$type+'_'+$metadbdataset_id

$SqlCmd.CommandText = "
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('$met','$metadbds',$metadblinkedservice_id)"

$SqlCmd.ExecuteNonQuery()

Log-Message "End :  Insert the metadb dataset"

}



<# traverse through the pipelines tag in the XML file #>

<# Linked service and dataset for the metadata datab #>


<# traverse through the sink tag in the XML file #>
foreach($sinkdetail in $ppdetail.Sink)
{
Log-Message "Start :  Insert the ADLS sink details to T_Pipeline_LinkedServices table"

$type = $sinkdetail.Type
$SqlCmd.CommandText = "INSERT INTO [dbo].[T_Pipeline_LinkedServices] (PipelineId, LinkedServiceId) SELECT $pipelineid,Id   FROM [dbo].[T_List_LinkedServices] WHERE LinkedService_Name = '" + $sinkdetail.Type + "'"
$SqlCmd.ExecuteNonQuery()
$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_LinkedServices] "
$linkedservice_id = $SqlCmd.ExecuteScalar()
$sinklinkedservicename = '"LS_POC_'+$type+'_'+$linkedservice_id +'"'
$linkedserviceparameter = '$'+$linkedservice_id+'_'+$type+'LinkedServiceName'


Log-Message "End :  Insert the ADLS sink details to T_Pipeline_LinkedServices table"

Log-Message "Start :  Insert the ADLS sink parameter details to T_Pipeline_LinkedService_Parameters table"

$SqlCmd.CommandText = "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters_New] $linkedservice_id, $pipelineid"

Write-Host "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters_New] $linkedservice_id, $pipelineid"

$SqlCmd.ExecuteNonQuery()


foreach($parameterdetail in $sinkdetail.Parameters.Parameter){
$paramval = '"'+$parameterdetail.Value+'"'
$paramname = $parameterdetail.Name.Replace('$','$'+$linkedservice_id+'_')

$SqlCmd.CommandText = "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = '$paramval' WHERE LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid AND ParameterName = '$paramname'"
Write-Host "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = '$paramval' WHERE LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid AND ParameterName = '$paramname'"
$SqlCmd.ExecuteNonQuery()

Log-Message "End :  Insert the ADLS sink parameter details to T_Pipeline_LinkedService_Parameters"

}


$SqlCmd.CommandText = "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters]  SET ParameterValue = '$sinklinkedservicename' WHERE ParameterName = '$linkedserviceparameter' AND LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid"

$SqlCmd.ExecuteNonQuery()


$SqlCmd.CommandText = "UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = '$irname' WHERE ParameterName like '%nameofintegrationruntime%' AND LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid"
$SqlCmd.ExecuteNonQuery()


Log-Message "Start :  Insert the ADLS sink dataset"

$sinkfileformat = $sinkdetail.FileFormat

$SqlCmd.CommandText = "
INSERT INTO dbo.T_Pipeline_DataSets (PipelineId,LinkedServericeId,DataSetId )
SELECT $pipelineid,tpl.Id,tld.id FROM dbo.T_List_DataSets tld inner join dbo.T_List_LinkedServices tll on tld.LinkedService_id = tll.Id inner join dbo.T_Pipeline_LinkedServices tpl 
ON tpl.LinkedServiceId = tll.Id where tll.LinkedService_Name = '$type' AND AdditionalConfigurationType = 'SinkFileFormat' AND AdditionalConfigurationValue = '$sinkfileformat'
"

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_DataSets] "
$sinkdataset_id = $SqlCmd.ExecuteScalar()
$sinkparamname = '$'+$linkedservice_id+'_'+$type+'DatasetName'
$sinkds = 'DS_POC_'+$type+'_'+$linkedservice_id
$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$sinkparamname+''','''+ $sinkds+''','+$sinkdataset_id+')'

$SqlCmd.ExecuteNonQuery()

Log-Message "End :  Insert the ADLS sink dataset"


Log-Message "Start :  Insert the ADLS sink dataset parameters"

$refname = '$'+$linkedservice_id +'_LInkedServerReferneceName'

$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$refname+''','''+$sinklinkedservicename.Replace('"','')+''','+$sinkdataset_id+')'

$SqlCmd.ExecuteNonQuery()

$filesystemfolder = $sinkdetail.FolderName
$filesystemparam = '$'+$linkedservice_id+'_fileSystemFolderName'
$CompressionCodectype = $sinkdetail.CompressionCodectype

$compressioncodeparam = '$'+$linkedservice_id+'_CompressionCodectype'
$sinkfileformatParamName = '$'+$linkedservice_id+'_fileformat'
$sinkfileextensionParamName = '$'+$linkedservice_id+'_fileextension'
$sinkcolumndelimiterParamName = '$'+$linkedservice_id+'_columndelimiter'
$sinkfileextension = $sinkdetail.FileExtension
$sinkcolumndelimiter = $sinkdetail.ColumnDelimiter

$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$filesystemparam+''','''+$filesystemfolder+''','+$sinkdataset_id+')'

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$compressioncodeparam+''','''+$CompressionCodectype+''','+$sinkdataset_id+')'

$SqlCmd.ExecuteNonQuery()


$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$sinkfileformatParamName+''','''+$sinkfileformat+''','+$sinkdataset_id+')'
$SqlCmd.ExecuteNonQuery()


$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$sinkfileextensionParamName+''','''+$sinkfileextension+''','+$sinkdataset_id+')'
$SqlCmd.ExecuteNonQuery()


if($sinkfileformat -eq 'DelimitedText')
{
$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$sinkcolumndelimiterParamName+''','''+$sinkcolumndelimiter +''','+$sinkdataset_id+')'

$SqlCmd.ExecuteNonQuery()
}



Log-Message "End :  Insert the ADLS sink dataset parameters"
}

foreach($srcdetail in $ppdetail.Sources.Source)
{
$type = $srcdetail.Type
$SqlCmd.CommandText = "INSERT INTO [dbo].[T_Pipeline_LinkedServices] (PipelineId, LinkedServiceId) SELECT $pipelineid,Id   FROM [dbo].[T_List_LinkedServices] WHERE LinkedService_Name = '" + $srcdetail.Type + "'"
$SqlCmd.ExecuteNonQuery()
$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_LinkedServices] "
$linkedservice_id = $SqlCmd.ExecuteScalar()

$metalinkedservicename = '"LS_POC_'+$type+'_'+$metadblinkedservice_id +'"'

$linkedservicename = '"LS_POC_'+$type+'_'+$linkedservice_id +'"'
$linkedserviceparamname = '$'+$type +'_'+$linkedservice_id + 'LinkedServiceName'



$SqlCmd.CommandText = "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters_New] $linkedservice_id, $pipelineid"

Write-Host "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters_New] $linkedservice_id, $pipelineid"

$SqlCmd.ExecuteNonQuery()


foreach($parameterdetail in $srcdetail.Parameters.Parameter){
$paramval = '"'+$parameterdetail.Value+'"'
$paramname = $parameterdetail.Name.Replace('$','$'+$linkedservice_id+'_')
$SqlCmd.CommandText = "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = '$paramval' WHERE LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid AND ParameterName = '$paramname'"
Write-Host "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters] SET ParameterValue = '$paramval' WHERE LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid AND ParameterName = '$paramname'"
$SqlCmd.ExecuteNonQuery()

}

$linkedserviceparamname = '$'+$linkedservice_id +'_'+$type+'LinkedServiceName'
$SqlCmd.CommandText = "UPDATE [dbo].[T_Pipeline_LinkedService_Parameters]  SET ParameterValue = '$linkedservicename' WHERE ParameterName = '$linkedserviceparamname' AND LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid"

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = '$irname' WHERE ParameterName like '%nameofintegrationruntime%' AND LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid"
$SqlCmd.ExecuteNonQuery()


$SqlCmd.CommandText = "
INSERT INTO dbo.T_Pipeline_DataSets (PipelineId,LinkedServericeId,DataSetId )
SELECT $pipelineid,tpl.Id,tld.id FROM dbo.T_List_DataSets tld inner join dbo.T_List_LinkedServices tll on tld.LinkedService_id = tll.Id inner join dbo.T_Pipeline_LinkedServices tpl 
ON tpl.LinkedServiceId = tll.Id where tll.LinkedService_Name = '$type' and tpl.id = $linkedservice_id
"

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_DataSets] "
$dataset_id = $SqlCmd.ExecuteScalar()
$datasetname = '$'+$linkedservice_id+'_'+$type+'DatasetName'
$datasetval = 'DS_POC_'+$type+'_'+$linkedservice_id

$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipeline_DataSet_Parameters (ParameterName,ParameterValue,DataSetId )
VALUES('''+$datasetname+''','''+$datasetval+''','+$dataset_id+')'
$SqlCmd.ExecuteNonQuery()


$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName)
SELECT ' + $pipelineid + ',id,0,0,1,''LKP_'+$metalinkedservicename.Replace('"','')+''' 
FROM dbo.T_List_Activities where ActivityName = ''Lookup Activity'''

$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName)
SELECT ' + $pipelineid + ' ,id,0,0,1,''CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+''' FROM dbo.T_List_Activities where ActivityName = ''Copy Activity'''

$SqlCmd.ExecuteNonQuery()

$ls = $linkedservicename.Replace('"','')

$metls = $metalinkedservicename.Replace('"','')


$lssls = $ls+'_'+$sinklinkedservicename.Replace('"','')


$SqlCmd.CommandText = '

SELECT tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
on tps.activity_id = tla.id
where tla.activityname = ''Lookup Activity'' and tps.pipelineid = ' + $pipelineid +' and tps.activityname = ''LKP_'+$metls+''''


$dependsonid = $SqlCmd.ExecuteScalar()

$SqlCmd.CommandText = '

SELECT tps.id from [dbo].[T_Pipelines_Steps] tps inner join dbo.t_list_activities tla 
on tps.activity_id = tla.id
where tla.activityname = ''Copy Activity'' and tps.pipelineid = ' + $pipelineid +' and tps.activityname = ''CP_'+$lssls+''''

$childid = $SqlCmd.ExecuteScalar()


$SqlCmd.CommandText = '
INSERT INTO dbo.T_Pipelines_steps (PipelineId,Activity_ID,DependsOn,Child_Activity,EmailNotificationEnabled,ActivityName)
SELECT ' + $pipelineid + ' ,id,'+$dependsonid+','+$childid+',1,''Foreach_SourceEntity_'+ $linkedservice_id +''' 
FROM dbo.T_List_Activities where ActivityName = ''For Each Activity'''

$SqlCmd.ExecuteNonQuery()



$SqlCmd.CommandText = "EXEC [dbo].[usp_Insert_Pipeline_Parameters_New] 'LKP_$metls','Foreach_SourceEntity_$linkedservice_id' ,'CP_$lssls'"
Write-Host   "EXEC [dbo].[usp_Insert_Pipeline_Parameters_New] 'LKP_$metls','Foreach_SourceEntity_$linkedservice_id' ,'CP_$lssls'"

$SqlCmd.ExecuteNonQuery()

$dsparamval = 'DS_POC_'+$type+'_'+$metadblinkedservice_id
$linksetname = '$LKP_'+$metalinkedservicename.Replace('"','')+'_dataset'
$SqlCmd.CommandText = "
UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = '$dsparamval' WHERE ParameterName = '$linksetname' and pipelineid = $pipelineid "

$SqlCmd.ExecuteNonQuery()

$dsparamval1 = 'DS_POC_'+$type+'_'+$linkedservice_id

$cpactparamname = '$CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+"_inputDatasetReference"
$SqlCmd.CommandText = "UPDATE tap set tap.Parametervalue = '$dsparamval1' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN dbo.T_Pipelines_steps tps ON tap.PipelineActivityId = tps.id WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "


$SqlCmd.ExecuteNonQuery()


$cpactparamname = '$CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+"_outputDatasetReference"
$outref = 'DS_POC_'+$sinkdetail.Type+ '_'+$sinkdataset_id

$SqlCmd.CommandText = "UPDATE tap set tap.Parametervalue = '$outref' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN dbo.T_Pipelines_steps tps ON tap.PipelineActivityId = tps.id WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "

Write-Host "UPDATE tap set tap.Parametervalue = '$outref' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN dbo.T_Pipelines_steps tps ON tap.PipelineActivityId = tps.id WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "


$SqlCmd.ExecuteNonQuery()

#$qry = ' ' 
foreach($tbldetail in $srcdetail.Tables.Table){
#$qry = $qry + 'SELECT '''''+$tbldetail.schema +''''' as Schema_Name , ''''' + $tbldetail.Name + ''' as Table_Name UNION ALL '
$tblname = $tbldetail.Name
$schname = $tbldetail.schema

$SqlCmd.CommandText = "INSERT INTO dbo.t_pipeline_tables_tobemoved (pipelineid,Table_Name,Schema_Name,linkedserviceid) VALUES ($pipelineid, '$tblname','$schname',$linkedservice_id)"
$SqlCmd.ExecuteNonQuery()

}


$qry = "SELECT Schema_Name,Table_Name,''$sinkfileformat'' as fileformat,''$sinkfileextension'' as fileextension,''$sinkcolumndelimiter'' as columnDelimiter FROM t_pipeline_tables_tobemoved WHERE pipelineid = $pipelineid and linkedserviceid = $linkedservice_id"

$qryparamname = '$LKP_'+$metadblinkedservicename.Replace('"','') + '_query'
$SqlCmd.CommandText = "UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = '$qry' WHERE ParameterName = '$qryparamname' and pipelineid = $pipelineid "
Write-Host "UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = '$qry' WHERE ParameterName = '$qryparamname' and pipelineid = $pipelineid "
$SqlCmd.ExecuteNonQuery()

}


}


$SqlConnection.Close()
