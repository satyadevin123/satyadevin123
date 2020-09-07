Param
(
[Parameter(Mandatory=$True,Position=1)]
[string]$ConfigXMLFilePath,
[Parameter(Mandatory=$True,Position=2)]
[string] $Logfilepath,
[Parameter(Mandatory=$True,Position=3)]
[string]$MetadataDBUserName,
[Parameter(Mandatory=$True,Position=4)]
[Securestring]$MetadataDBPasswordSecure
)

try
{
[XML]$MetaDetails = Get-Content $ConfigXMLFilePath

$logdate = get-date
$logfilepath = $Logfilepath

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
    Log-Message "No.of rows affected :
      $Rows_Affected"    
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
    New-AzKeyVault -Name $keyvaultname.Replace('"','') -ResourceGroupName $resourceGroupName -Location 'west us' -ErrorAction SilentlyContinue -DisableSoftDelete -SoftDeleteRetentionInDays 7

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
    Create-KeyVault -keyvaultName $keyvaultname -keyvaultlocation $keyvaultlocation -resourceGroupName $resourceGroupName

    return $keyvaultname
}

Function Truncate-Pipelinedetails
{
   <# truncate the pipeline tables as part of each run #>
    Sql-Execute -Qry "EXEC usp_TruncateParameterTables" -Qrydetails "Trunate pipeline parameter,activity,dataset, linked server tables"
}
Function Insert-DatasetsAndParameters
{
Param([int]$PipelineId,[String]$LinkedServiceType,[int]$LinkedServiceId,[String]$AdditionalType,[String]$AdditionalVal) 
    
    Write-Host "EXEC usp_InsertPipelineDataSets '$LinkedServiceType',$LinkedServiceId,$PipelineId,'$AdditionalType','$AdditionalVal'"
           Sql-Execute -Qry "EXEC usp_InsertPipelineDataSets '$LinkedServiceType',$LinkedServiceId,$PipelineId,'$AdditionalType','$AdditionalVal'" -Qrydetails  "Insert datasets for metadata db"
            
            $SqlCmd.CommandText = "SELECT MAX(PipelineDatasetId) FROM [T_Pipeline_DataSets] "
            $dataset_id = Sql-ExecuteScalar -Qry "SELECT MAX(PipelineDatasetId) FROM [T_Pipeline_DataSets] " -Qrydetails "max dataset id"
            Write-Host  "EXEC usp_InsertPipelineDataSetParameters $LinkedServiceId,$dataset_id,$PipelineId"
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters $LinkedServiceId,$dataset_id,$PipelineId" -Qrydetails  "Insert dataset parameters for metadata db"
            
      
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
            Set-AzKeyVaultSecret -VaultName $kv -Name $name -SecretValue $SecretPassword
            $name = '"'+$name+'"'
            if($type -eq 'azureSQLDatabase')
            {
            
            $param = '$'+$Linkedservice_id +'_'+'azureSqlDBPassword'
            }
            else
            {
            $param = '$'+$Linkedservice_id +'_'+'onpremSqlDBPassword'
            }
            Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$param','$name',$pipelineid,$Linkedservice_id" -Qrydetails "Insert value for parameter : $linkedserviceparamname"
            

}

Function Insert-LinkedServicesAndParameters
{
Param([int]$PipelineId,[String]$LinkedServiceType,[String]$resourceGroupName,[string]$AuthenticationType,[string]$ir) 
    
    $Qry = "EXEC usp_InsertPipelineLinkedServiceDetails $PipelineId,'$LinkedServiceType','$AuthenticationType'"
    Write-Host $Qry
    $QryDetails = "Insert the $LinkedServiceType details to T_Pipeline_LinkedServices table"
    Write-Host $QryDetails
    Sql-Execute -Qry $Qry -Qrydetails $QryDetails 
    $SqlCmd.CommandText = "SELECT MAX(PipelineLinkedServicesId) FROM [T_Pipeline_LinkedServices] "
    $linkedservice_id = $SqlCmd.ExecuteScalar()
    $linkedservicename = '"LS_POC_'+$LinkedServiceType+'_'+$linkedservice_id +'"'
    Write-Host "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters] $linkedservice_id, $pipelineid,'$ir'"
    Sql-Execute -Qry "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters] $linkedservice_id, $pipelineid,'$ir'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
    
    [pscustomobject] @{
    id = $linkedservice_id
    name = $linkedservicename
    }

}

<#Variables Initiation#>
$irname = '"Azure-IR-ADF"'
$keyvaulttype = 'azurekeyvault'



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

# Update master parameters to t_master_parameters table   
    $keyvaultname = Update-MasterParametersToDB

# each execution will truncate the data in the pipeline tables   
    Truncate-Pipelinedetails
    
    foreach($ppdetail in $MetaDetails.Metadata.Pipelines.Pipeline)
    {
        $pipelinename = $ppdetail.Name
        Sql-Execute -Qry "EXEC usp_InsertPipelineDetails '$pipelinename'" -Qrydetails "Insert pipeline details in T_Pipelines table"
        $pipelineid = Sql-ExecuteScalar -Qry "SELECT MAX(PipelineId) FROM [T_Pipelines] " -Qrydetails "max pipeline id"
        <#start - Insert linked service for the key vault#>
        $out = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType 'azurekeyvault' -resourceGroupName $resourceGroupName -AuthenticationType 'Managed Identity' -ir $irname
        $kvlinkedserviceid = $out.id
        $kvlinkedservicename = $out.name
        <#end - Insert linked service for the key vault#>
        
        <#start - Insert linked service for the metadata DB#>
        
        $MetadataDB = $MetaDetails.Metadata.MetadataDB
        $type = $MetadataDB.Type
        $authtype = $MetadataDB.AuthenticationType
        $metatype = $type
        $out = ""
        $out = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType $metatype -resourceGroupName $resourceGroupName -AuthenticationType $authtype -ir $irname
        $metadblinkedservice_id = $out.id
        $metadblinkedservicename = $out.name
        <# start - save the azure sql db password in key vault #>
        if($type -eq 'azureSQLDatabase')
        {
            Insert-KeyVaultReferenceToSQLDBLinkedService -Linkedservice_id $metadblinkedservice_id -kvlinkedservicename $kvlinkedservicename -pipelineid $pipelineid -type $type -keyvaultname $keyvaultname -messagetype 'Metadata' 
        }
        <# end - save the azure sql db password in key vault #>
        
        foreach($parameterdetail in $MetadataDB.Parameters.Parameter)
        {
            $paramval = '"'+$parameterdetail.Value+'"'
            $paramname = $parameterdetail.Name.Replace('$','$'+$metadblinkedservice_id+'_')
            Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$paramname','$paramval',$pipelineid,$metadblinkedservice_id" -Qrydetails  "Update linked service parameter : $paramname"
        }
        <# start - insert data set and parameters for metadata db#>
        $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceType $metatype -LinkedServiceId $metadblinkedservice_id -AdditionalType $null -AdditionalVal $null
        <# end - insert data set and parameters for metadata db#>
               
        <# traverse through the sink tag in the XML file #>
        $sinkdetail = $ppdetail.Sink
        $type = $sinkdetail.Type
        $Authtype = $sinkdetail.AuthenticationType
        $out = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType $type -resourceGroupName $resourceGroupName -AuthenticationType $Authtype -ir $irname
        $sinklinkedservice_id = $out.id
        $sinklinkedservicename = $out.name
        foreach($parameterdetail in $sinkdetail.Parameters.Parameter)
        {
            $paramval = '"'+$parameterdetail.Value+'"'
            $paramname = $parameterdetail.Name.Replace('$','$'+$sinklinkedservice_id+'_')
            Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$paramname','$paramval',$pipelineid,$sinklinkedservice_id" -Qrydetails "Insert value for parameter : $paramname"
        }
        
         foreach($parameterdetail in $sinkdetail.SinkParameters.Parameter)
        {
            $paramval = $parameterdetail.Value
            if($parameterdetail.Name -eq '$fileformat'){
            $sinkfileformat = $paramval
            }
            if($parameterdetail.Name -eq '$fileextension'){
            $sinkfileextension = $paramval
            }
            if($parameterdetail.Name -eq '$columndelimiter'){
            $sinkcolumndelimiter = $paramval
            }
        }
                
        $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceType $type -LinkedServiceId $sinklinkedservice_id -AdditionalType 'SinkFileFormat' -AdditionalVal $sinkfileformat
        $sinkdataset_id = $od.id
        $refname = '$'+$sinklinkedservice_id +'_LInkedServerReferneceName'
        $sinklinkedservicename1 = $sinklinkedservicename.Replace('"','')
        Sql-Execute -Qry "EXEC [usp_UpdatePipelineDataSetParameters] '$refname','$sinklinkedservicename1',$sinkdataset_id,$pipelineid" -Qrydetails  "Insert dataset parameters for sink : $sinkparamname"
        
        foreach($parameterdetail in $sinkdetail.SinkParameters.Parameter)
        {
            $paramval = $parameterdetail.Value
            if($parameterdetail.Name -eq '$fileformat'){
            $sinkfileformat = $paramval
            }
            if($parameterdetail.Name -eq '$fileextension'){
            $sinkfileextension = $paramval
            }
            if($parameterdetail.Name -eq '$columndelimiter'){
            $sinkcolumndelimiter = $paramval
            }
            $paramname = $parameterdetail.Name.Replace('$','$'+$sinklinkedservice_id+'_')

            Sql-Execute -Qry "EXEC [usp_UpdatePipelineDataSetParameters] '$paramname','$paramval',$sinkdataset_id,$pipelineid" -Qrydetails "Insert value for parameter : $paramname"
        }
        
       foreach($srcdetail in $ppdetail.Sources.Source)
       {
            $type = $srcdetail.Type
            $authtype = $srcdetail.AuthenticationType
            $o = Insert-LinkedServicesAndParameters -PipelineId $pipelineid -LinkedServiceType $type -resourceGroupName $resourceGroupName -AuthenticationType $authtype -ir $irname
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
            
            <#Start - Insert pipeline activities #>
            
            $ls = $linkedservicename.Replace('"','')
            $metls = $metadblinkedservicename.Replace('"','')
            $lssls = $ls+'_'+$sinklinkedservicename.Replace('"','')
            
            Sql-Execute -Qry "EXEC usp_insertpipelinesteps $pipelineid,'LKP_$metls','CP_$lssls','Foreach_SourceEntity_$linkedservice_id','$type'" -Qrydetails  "Insert pipeline steps"
            Sql-Execute -Qry "EXEC usp_Insert_Pipeline_Parameters 'LKP_$metls','Foreach_SourceEntity_$linkedservice_id' ,'CP_$lssls',$pipelineid" -Qrydetails  "Insert pipeline activity parameters"
            $dsparamval = 'DS_POC_'+$metatype+'_'+$metadblinkedservice_id
            $linksetname = '$LKP_'+$metadblinkedservicename.Replace('"','')+'_dataset'
            Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters '$linksetname','$dsparamval',$pipelineid" -Qrydetails  "update pipeline activity parameter :$linksetname "
            $dsparamval1 = 'DS_POC_'+$type+'_'+$linkedservice_id
            $cpactparamname = '$CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+"_inputDatasetReference"
            $SqlCmd.CommandText = "UPDATE tap set tap.Parametervalue = '$dsparamval1' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN
             dbo.T_Pipeline_Activities tps ON tap.PipelineActivityId = tps.PipelineStepsid WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "
            $SqlCmd.ExecuteNonQuery()
            $cpactparamname = '$CP_'+$linkedservicename.Replace('"','')+'_'+$sinklinkedservicename.Replace('"','')+"_outputDatasetReference"
            $outref = 'DS_POC_'+$sinkdetail.Type+ '_'+$sinklinkedservice_id
            $SqlCmd.CommandText = "UPDATE tap set tap.Parametervalue = '$outref' FROM dbo.T_Pipeline_Activity_Parameters tap INNER JOIN dbo.T_Pipeline_Activities tps ON tap.PipelineActivityId = tps.Pipelinestepsid WHERE ParameterName = '$cpactparamname' and tap.pipelineid = $pipelineid and tps.Activityname = 'CP_$lssls' "
            $SqlCmd.ExecuteNonQuery()
            foreach($tbldetail in $srcdetail.Tables.Table)
            {
                $tblname = $tbldetail.Name
                $schname = $tbldetail.schema

                Sql-Execute -Qry "EXEC  usp_InsertPipelineTablesToBeMoved $pipelineid,'$tblname','$schname',$linkedservice_id" -Qrydetails  "insert tables to be moved "

            }

            $qry = "SELECT Schema_Name,Table_Name,''$sinkfileformat'' as fileformat,''$sinkfileextension'' as fileextension,''$sinkcolumndelimiter'' as columnDelimiter FROM t_pipeline_tables_tobemoved WHERE pipelineid = $pipelineid and linkedserviceid = $linkedservice_id"

            $qryparamname = '$LKP_'+$metadblinkedservicename.Replace('"','') + '_query'
    
    
            Sql-Execute -Qry "EXEC  usp_updatepipelineactivityparameters '$qryparamname','$qry',$pipelineid" -Qrydetails  "update activity parameter :  $qryparamname"
            <#End - Insert pipeline activities #>

        }


    }

    $SqlConnection.Close()
}

catch
{
Write-host $error
Add-Content $LogFilePath $error
Add-Content $LogFilePath "Script failed with errors. Please check log file"
Write-Host "Deployment Failed with Errors. Please refer log file"
}