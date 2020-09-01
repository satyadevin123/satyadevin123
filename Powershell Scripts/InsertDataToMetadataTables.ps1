Param
(
[Parameter(Mandatory=$True,Position=1)]
[string]$ConfigXMLFilePath,
[Parameter(Mandatory=$True,Position=2)]
[string]$MetadataDBUserName,
[Parameter(Mandatory=$True,Position=3)]
[Securestring]$MetadataDBPasswordSecure
)

#try
#{
$XMLfile = 'D:\Metadata PoC\XMLInput.xml'
[XML]$MetaDetails = Get-Content $XMLfile

$logdate = get-date
$logfilepath = "D:\Metadata PoC\MetadataCreationLogFile.txt"

"$logdate`t************ Start************"|Out-File $logfilepath


<# function to log details to file #>
Function Log-Message([String]$Message) 
{ 
    $datetime = (Get-Date -UFormat "%Y-%m-%d_%I-%M-%S_%p").tostring()
    Add-Content -Path $logfilepath $Message 
    Write-Host $Message
}

<# function to execute sql commands #>
Function Sql-Execute
{

    Param([String]$Qry,[String]$Qrydetails) 
    $logdate = get-date
    Log-Message "$logdate`tStart :  $Qrydetails"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandText = "$Qry"
    $Rows_Affected = $SqlCmd.ExecuteNonQuery()
    Log-Message "No.of rows affected :  $Rows_Affected"    
    Log-Message "$logdate`tEnd :  $Qrydetails" 
}

Function Sql-ExecuteScalar
{

    Param([String]$Qry,[String]$Qrydetails) 
    Log-Message "Start :  $Qrydetails"
    $SqlCmd.CommandText = "$Qry"
    $scalarval = $SqlCmd.ExecuteScalar()
    Log-Message "No.of rows affected :  $scalarval"    
    Log-Message "End :  $Qrydetails" 
    return   $scalarval
}

Function Create-KeyVault
{
    Param([String]$keyvaultName,[String]$keyvaultlocation,[String]$resourceGroupName) 
    New-AzKeyVault -Name $keyvaultname.Replace('"','') -ResourceGroupName 'RG-data-pipeline-framework-poc' -Location 'west us' -ErrorAction SilentlyContinue -DisableSoftDelete -SoftDeleteRetentionInDays 7

}
<# Master parameters #>

Function Update-MasterParametersToDB
{
    
    foreach($parameterdetail in $MetaDetails.Metadata.AzureEnvSetup.Parameters.Parameter)
    {
        $paramval = '"'+$parameterdetail.Value+'"'
        $paramname = $parameterdetail.Name
        if ($paramname -eq '$keyvaultname')
        {
            $keyvaultname = '"'+$parameterdetail.Value+'"'
        }
        if ($paramname -eq '$keyvaultlocation')
        {
            $keyvaultlocation = $parameterdetail.Value
        }
        if ($paramname -eq '$resourceGroupName')
        {
            $resourceGroupName = $parameterdetail.Value
        }

        Sql-Execute -Qry "EXEC usp_UpdateMasterParametersList '$paramname','$paramval'" -Qrydetails "Update master parameter $paramname"
    }
    Write-Host $keyvaultname
    Write-Host $resourceGroupName
    Write-host $keyvaultlocation
    Create-KeyVault -keyvaultName $keyvaultname -keyvaultlocation $keyvaultlocation -resourceGroupName $resourceGroupName

return $keyvaultname
}

Function Truncate-Pipelinedetails
{
   <# truncate the pipeline tables as part of each run #>
    Sql-Execute -Qry "EXEC usp_TruncateParameterTables" -Qrydetails "Trunate pipeline parameter,activity,dataset, linked server tables"
}


Write-Host 'started'

Log-Message "Beginning exeuction of the script"
<# SQL connection setup to the metadata database  #>
foreach($parameterdetail in $MetaDetails.Metadata.MetadataDB.Parameters.Parameter)
{
    if ($parameterdetail.Name -eq '$azureSqlDBServerName')
    {
    $MetadataDBServerName = $parameterdetail.Value
    }
    if ($parameterdetail.Name -eq '$azureSqlDatabaseName')
    {
    $MetadataDBdatabaseName = $parameterdetail.Value
    }

}
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MetadataDBPasswordSecure)
$MetadataDBPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $MetadataDBServerName.database.windows.net; Database = $MetadataDBdatabaseName; Integrated Security = False; User ID = $MetadataDBUserName; Password = $MetadataDBPassword;"

Log-Message "Start :  Opening Connection to Metadata database"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.Connection = $SqlConnection
$SqlConnection.Open()
Log-Message "End :  Opening Connection to Metadata database"

$irname = '"Azure-IR-ADF"'
$keyvaulttype = 'azurekeyvault'
   
$keyvaultname = Update-MasterParametersToDB
Truncate-Pipelinedetails

Function Insert-DatasetsAndParameters
{
Param([int]$PipelineId,[String]$LinkedServiceType,[int]$LinkedServiceId,[String]$AdditionalType,[String]$AdditionalVal) 
    
           Write-Host "id: $LinkedServiceId"
           
           if($AdditionalType -eq $null -or $AdditionalType -eq '')
           {
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSets '$LinkedServiceType',$LinkedServiceId,$PipelineId" -Qrydetails  "Insert datasets for metadata db"
            }
            else
            {
             Sql-Execute -Qry "EXEC usp_InsertPipelineDataSets '$LinkedServiceType',$LinkedServiceId,$PipelineId,$AdditionalType,$AdditionalVal" -Qrydetails  "Insert datasets for metadata db"
            }
            $SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_DataSets] "
            $dataset_id = Sql-ExecuteScalar -Qry "SELECT MAX(Id) FROM [T_Pipeline_DataSets] " -Qrydetails "max dataset id"
            $datasetparamname = '$'+$LinkedServiceId+'_'+$LinkedServiceType+'DatasetName'
            $datasetparamval = 'DS_POC_'+$LinkedServiceType+'_'+$LinkedServiceId.ToString()
            Write-Host "EXEC usp_InsertPipelineDataSetParameters '$datasetparamname','$datasetparamval',$dataset_id"
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$datasetparamname','$datasetparamval',$dataset_id" -Qrydetails  "Insert dataset parameters for metadata db"
            
      
    [pscustomobject] @{
    id = $dataset_id
    name = $datasetparamval
    }

     

}        


Function Insert-KeyVaultReferenceToSQLDBLinkedService
{
Param([int]$Linkedservice_id,[string]$kvlinkedservicename,[int]$pipelineid,[string]$type,[string] $keyvaultname,[string]$messagetype )

            $linkedserviceparamname = '$'+$Linkedservice_id +'_'+'azurekeyvaultlinkedservicereference'
            Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$linkedserviceparamname','$kvlinkedservicename',$pipelineid,$Linkedservice_id" -Qrydetails "Insert value for parameter : $linkedserviceparamname"
            $SecretPassword = Read-Host "Type password for $messagetype database : " -AsSecureString
            $kv = $keyvaultname.Replace('"','')
            $name = $Linkedservice_id.ToString()+'azurekeyvaultlinkedservicereference'
            
            Write-Host $name
            
            Set-AzKeyVaultSecret -VaultName $kv -Name $name -SecretValue $SecretPassword
            $name = '"'+$name+'"'
            Write-Host $type
            if($type -eq 'azureSQLDatabase')
            {
            
            $param = '$'+$Linkedservice_id +'_'+'azureSqlDBPassword'
            Write-Host $param

            }
            else
            {
            $param = '$'+$Linkedservice_id +'_'+'onpremSqlDBPassword'
            }
            Write-Host $param
            Write-Host "EXEC usp_UpdateLinkedServiceParameters '$param','$name',$pipelineid,$Linkedservice_id"
            Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$param','$name',$pipelineid,$Linkedservice_id" -Qrydetails "Insert value for parameter : $linkedserviceparamname"
            

}

Function Insert-LinkedServicesAndParameters
{
Param([int]$PipelineId,[String]$LinkedServiceType,[String]$resourceGroupName) 
    
    $Qry = "EXEC usp_InsertPipelineLinkedServiceDetails $PipelineId,'$LinkedServiceType'"
    Write-Host $Qry
    $QryDetails = "Insert the $LinkedServiceType details to T_Pipeline_LinkedServices table"
    Write-Host $QryDetails
    Sql-Execute -Qry $Qry -Qrydetails $QryDetails 
    $SqlCmd.CommandText = "SELECT MAX(Id) FROM [T_Pipeline_LinkedServices] "
    $linkedservice_id = $SqlCmd.ExecuteScalar()
    $linkedservicename = '"LS_POC_'+$LinkedServiceType+'_'+$linkedservice_id +'"'
    Sql-Execute -Qry "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters] $linkedservice_id, $pipelineid" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
    $linkedserviceparamname = '$'+$linkedservice_id +'_'+$LinkedServiceType+'LinkedServiceName'
    Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$linkedserviceparamname','$linkedservicename',$pipelineid,$linkedservice_id" -Qrydetails  "Update linked service parameter : $linkedservicename"
    
    if ($LinkedServiceType -eq 'azurekeyvault')
    {  
    $keyvaultnameparam = '$'+$linkedservice_id +'_keyvaultname'
    $keyvaultnameparamval = $keyvaultname
    Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$keyvaultnameparam','$keyvaultnameparamval',$pipelineid,$linkedservice_id" -Qrydetails  "Update linked service parameter : $linkedservicename"
     }
     if($LinkedServiceType -ne 'azurekeyvault')
     {
     $SqlCmd.CommandText = "UPDATE T_Pipeline_LinkedService_Parameters SET ParameterValue = '$irname' WHERE ParameterName like '%nameofintegrationruntime%' AND LinkedServerId = $linkedservice_id AND PipelineId = $pipelineid"
     $SqlCmd.ExecuteNonQuery()
     }
     Write-Host 'in'
     
    [pscustomobject] @{
    id = $linkedservice_id
    name = $linkedservicename
    }

}


foreach($ppdetail in $MetaDetails.Metadata.Pipelines.Pipeline)
{
    $pipelinename = $ppdetail.Name
    Sql-Execute -Qry "EXEC usp_InsertPipelineDetails '$pipelinename'" -Qrydetails "Insert pipeline details in T_Pipelines table"
    $pipelineid = Sql-ExecuteScalar -Qry "SELECT MAX(Id) FROM [T_Pipelines] " -Qrydetails "max pipeline id"
    
    $out = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType 'azurekeyvault' -resourceGroupName 'RG-data-pipeline-framework-poc'
    
    $kvlinkedserviceid = $out.id
    $kvlinkedservicename = $out.name

    write-host "key vault id: $kvlinkedserviceid "
        <# Linked service and dataset for the metadata database #>
       foreach($MetadataDB in $MetaDetails.Metadata.MetadataDB)
        {

            $type = $MetadataDB.Type
            $metatype = $type
            $out = ""
           $out = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType $metatype -resourceGroupName 'RG-data-pipeline-framework-poc'
           
            $metadblinkedservice_id = $out.id
            $metadblinkedservicename = $out.name

            if($type -eq 'azureSQLDatabase')
            {
            write-host 'inside kv ref for meta db'
            Insert-KeyVaultReferenceToSQLDBLinkedService -Linkedservice_id $metadblinkedservice_id -kvlinkedservicename $kvlinkedservicename -pipelineid $pipelineid -type $type -keyvaultname $keyvaultname -messagetype 'Metadata' 
            }

            
            foreach($parameterdetail in $MetadataDB.Parameters.Parameter)
            {
                $paramval = '"'+$parameterdetail.Value+'"'
                $paramname = $parameterdetail.Name.Replace('$','$'+$metadblinkedservice_id+'_')
                Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$paramname','$paramval',$pipelineid,$metadblinkedservice_id" -Qrydetails  "Update linked service parameter : $paramname"
                
            }
          $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceType $metatype -LinkedServiceId $metadblinkedservice_id -AdditionalType $null -AdditionalVal $null
            



            }
  

<# traverse through the sink tag in the XML file #>
    foreach($sinkdetail in $ppdetail.Sink)
    {
    $type = $sinkdetail.Type
    
    $out = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType $type -resourceGroupName 'RG-data-pipeline-framework-poc'

    $sinklinkedservice_id = $out.id
    $sinklinkedservicename = $out.name
    
    write-host "sink db  id: $sinklinkedservice_id "

    foreach($parameterdetail in $sinkdetail.Parameters.Parameter)
    {
        $paramval = '"'+$parameterdetail.Value+'"'
        $paramname = $parameterdetail.Name.Replace('$','$'+$sinklinkedservice_id+'_')
        Write-Host $paramname
       Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$paramname','$paramval',$pipelineid,$sinklinkedservice_id" -Qrydetails "Insert value for parameter : $paramname"

    }


    $sinkfileformat = $sinkdetail.FileFormat
    $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceType $type -LinkedServiceId $sinklinkedservice_id -AdditionalType 'SinkFileFormat' -AdditionalVal $sinkfileformat
    
    $sinkdataset_id = $od.id
    $refname = '$'+$sinklinkedservice_id +'_LInkedServerReferneceName'
    $sinklinkedservicename1 = $sinklinkedservicename.Replace('"','')
    
    Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$refname','$sinklinkedservicename1',$sinkdataset_id" -Qrydetails  "Insert dataset parameters for sink : $sinkparamname"
    

    $filesystemfolder = $sinkdetail.FolderName
    $filesystemparam = '$'+$sinklinkedservice_id+'_fileSystemFolderName'
    $CompressionCodectype = $sinkdetail.CompressionCodectype
    $compressioncodeparam = '$'+$sinklinkedservice_id+'_CompressionCodectype'
    $sinkfileformatParamName = '$'+$sinklinkedservice_id+'_fileformat'
    $sinkfileextensionParamName = '$'+$sinklinkedservice_id+'_fileextension'
    $sinkcolumndelimiterParamName = '$'+$sinklinkedservice_id+'_columndelimiter'
    $sinkfileextension = $sinkdetail.FileExtension
    $sinkcolumndelimiter = $sinkdetail.ColumnDelimiter

    Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$filesystemparam','$filesystemfolder',$sinkdataset_id" -Qrydetails  "Insert dataset parameters for sink : $filesystemparam"
    Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$compressioncodeparam','$CompressionCodectype',$sinkdataset_id" -Qrydetails  "Insert dataset parameters for sink : $compressioncodeparam"
    Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$sinkfileformatParamName','$sinkfileformat',$sinkdataset_id" -Qrydetails  "Insert dataset parameters for sink : $sinkfileformatParamName"
    Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$sinkfileextensionParamName','$sinkfileextension',$sinkdataset_id" -Qrydetails  "Insert dataset parameters for sink : $sinkfileextensionParamName"
    

    if($sinkfileformat -eq 'DelimitedText')
    {
       Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$sinkcolumndelimiterParamName','$sinkcolumndelimiter',$sinkdataset_id" -Qrydetails  "Insert dataset parameters for sink : $sinkcolumndelimiterParamName"
    }
}



foreach($srcdetail in $ppdetail.Sources.Source)
    {
    $type = $srcdetail.Type
    $o = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType $type -resourceGroupName 'RG-data-pipeline-framework-poc'
    $linkedservice_id = $o.id
    $linkedservicename = $o.name

    
    foreach($parameterdetail in $srcdetail.Parameters.Parameter)
    {
        $paramval = '"'+$parameterdetail.Value+'"'
        $paramname = $parameterdetail.Name.Replace('$','$'+$linkedservice_id+'_')
        Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$paramname','$paramval',$pipelineid,$linkedservice_id" -Qrydetails "Insert value for parameter : $paramname"

    }

    if(($type -eq 'azureSQLDatabase') -or ($type -eq 'OnPremiseSQLServer'))
    {
        Insert-KeyVaultReferenceToSQLDBLinkedService -Linkedservice_id $linkedservice_id -kvlinkedservicename $kvlinkedservicename -pipelineid $pipelineid -type $type -keyvaultname $keyvaultname -messagetype 'Source' 
    }
    

    $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceType $type -LinkedServiceId $linkedservice_id     
    $dataset_id = $od.id
    
    $ls = $linkedservicename.Replace('"','')
    $metls = $metadblinkedservicename.Replace('"','')
    $lssls = $ls+'_'+$sinklinkedservicename.Replace('"','')
    Write-Host "EXEC usp_insertpipelinesteps $pipelineid,'LKP_$metls','CP_$lssls','Foreach_SourceEntity_$linkedservice_id'"
    
    Sql-Execute -Qry "EXEC usp_insertpipelinesteps $pipelineid,'LKP_$metls','CP_$lssls','Foreach_SourceEntity_$linkedservice_id'" -Qrydetails  "Insert pipeline steps"
    Sql-Execute -Qry "EXEC usp_Insert_Pipeline_Parameters 'LKP_$metls','Foreach_SourceEntity_$linkedservice_id' ,'CP_$lssls',$pipelineid" -Qrydetails  "Insert pipeline activity parameters"
        

    $dsparamval = 'DS_POC_'+$metatype+'_'+$metadblinkedservice_id
    $linksetname = '$LKP_'+$metadblinkedservicename.Replace('"','')+'_dataset'
    
    Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters '$linksetname','$dsparamval',$pipelineid" -Qrydetails  "update pipeline activity parameter :$linksetname "
    
    $dsparamval1 = 'DS_POC_'+$type+'_'+$linkedservice_id

    $cpactparamname = '$CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+"_inputDatasetReference"
    
    $SqlCmd.CommandText = "UPDATE tap set tap.Parametervalue = '$dsparamval1' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN
     dbo.T_Pipelines_steps tps ON tap.PipelineActivityId = tps.id WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "


    $SqlCmd.ExecuteNonQuery()


    $cpactparamname = '$CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+"_outputDatasetReference"
    $outref = 'DS_POC_'+$sinkdetail.Type+ '_'+$sinklinkedservice_id

    $SqlCmd.CommandText = "UPDATE tap set tap.Parametervalue = '$outref' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN dbo.T_Pipelines_steps tps ON tap.PipelineActivityId = tps.id WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "

      $SqlCmd.ExecuteNonQuery()

    foreach($tbldetail in $srcdetail.Tables.Table){
    $tblname = $tbldetail.Name
    $schname = $tbldetail.schema

    Sql-Execute -Qry "EXEC  usp_InsertPipelineTablesToBeMoved $pipelineid,'$tblname','$schname',$linkedservice_id" -Qrydetails  "insert tables to be moved "

    }


    $qry = "SELECT Schema_Name,Table_Name,''$sinkfileformat'' as fileformat,''$sinkfileextension'' as fileextension,''$sinkcolumndelimiter'' as columnDelimiter FROM t_pipeline_tables_tobemoved WHERE pipelineid = $pipelineid and linkedserviceid = $linkedservice_id"

    $qryparamname = '$LKP_'+$metadblinkedservicename.Replace('"','') + '_query'
    
    
     Sql-Execute -Qry "EXEC  usp_updatepipelineactivityparameters '$qryparamname','$qry',$pipelineid" -Qrydetails  "update activity parameter :  $qryparamname"


    }


    }

    $SqlConnection.Close()
   #     }
<#
catch
{

Add-Content $LogFilePath $error
Add-Content $LogFilePath "Deployment failed with errors. Please check log file"
Write-Host "Deployment Failed with Errors. Please refer log file"
}#>