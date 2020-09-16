Param
(
[Parameter(Mandatory=$True,Position=1)]
[string]$MetadataDBUserName,
[Parameter(Mandatory=$True,Position=2)]
[Securestring]$MetadataDBPasswordSecure
)
<# function to log details to file #>
Function Log-Message([String]$Message) 
{ 
    
    $datetime = (Get-Date -UFormat "%Y-%m-%d_%I-%M%p").tostring()
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
    Log-Message "No.of rows affected : $Rows_Affected"    
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
    New-AzKeyVault -Name $keyvaultname.Replace('"','') -ResourceGroupName $resourceGroupName -Location $keyvaultlocation -ErrorAction SilentlyContinue -DisableSoftDelete -SoftDeleteRetentionInDays 7

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
        
        if ($paramname -eq '$servicePrincipalId')
        {
            $servicePrincipalId = $parameterdetail.Value
        }
        
        if ($paramname -eq '$dataFactoryName')
        {
            $dataFactoryName = $parameterdetail.Value
        }
        
        if ($paramname -eq '$servicePrincipalName')
        {
            $servicePrincipalName = $parameterdetail.Value
        }
        
        

        Sql-Execute -Qry "EXEC usp_UpdateMasterParametersList '$paramname','$paramval'" -Qrydetails "Update master parameter $paramname"
        
    }
        Create-KeyVault -keyvaultName $keyvaultname -keyvaultlocation $keyvaultlocation -resourceGroupName $resourceGroupName
      
        if($servicePrincipalId -ne $null -and $servicePrincipalId -ne '')
        {
            $SecretPassword = Read-Host "Type key for service principal : " -AsSecureString
            $kv = $keyvaultname.Replace('"','')
            $name = 'spkazurekeyvaultlinkedservicereference'
            Write-Host 'before error'
            $x = Set-AzKeyVaultSecret -VaultName $kv -Name $name -SecretValue $SecretPassword 
            Write-Host 'after error'
            $name = '"'+$name+'"'
            Write-Host $name
            Sql-Execute -Qry "EXEC usp_UpdateMasterParametersList '`$servicePrincipalKey','$name'"  -Qrydetails 'Update master parameter $servicePrincipalKey'
         }

        $res = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName  -Name "LogicAppDeployment" -TemplateFile "$ScriptPath\LogicAppDeploymenttemplate.json" 
        $logicappurl = (Get-AzLogicAppTriggerCallbackUrl  -ResourceGroupName $resourceGroupName -Name "LogicAppToSendMailFromADF" -TriggerName "manual").Value        $logicappurl = '"'+$logicappurl+'"'
        Write-Host "EXEC usp_UpdateMasterParametersList '`$LogicAppURL','$logicappurl'"
        Sql-Execute -Qry "EXEC usp_UpdateMasterParametersList '`$LogicAppURL','$logicappurl'"  -Qrydetails 'Update master parameter $logicappurl'

         [pscustomobject] @{
        kvname = $keyvaultname
        dfname = $dataFactoryName
        spnname = $servicePrincipalName
        }
  
    return [pscustomobject]
}

Function Truncate-Pipelinedetails
{
Param([string]$PipelineName)
   <# truncate the pipeline tables as part of each run #>
    Sql-Execute -Qry "EXEC usp_TruncateParameterTables '$PipelineName'" -Qrydetails "Trunate pipeline parameter,activity,dataset, linked server tables"
}
Function Insert-DatasetsAndParameters
{
Param([int]$PipelineId,[String]$LinkedServiceName,[String]$AdditionalType,[String]$AdditionalVal) 
    
             
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSets '$LinkedServiceName',$PipelineId,'$AdditionalType','$AdditionalVal'" -Qrydetails  "Insert datasets for metadata db"
            $SqlCmd.CommandText = "SELECT MAX(PipelineDatasetId) FROM [T_Pipeline_DataSets] "
            $dataset_id = Sql-ExecuteScalar -Qry "SELECT MAX(PipelineDatasetId) FROM [T_Pipeline_DataSets] " -Qrydetails "max dataset id"
            $SqlCmd.CommandText = "SELECT MAX(PipelineDatasetId) FROM [T_Pipeline_DataSets] "
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$LinkedServiceName',$dataset_id,$PipelineId" -Qrydetails  "Insert dataset parameters for metadata db"
            
      
    [pscustomobject] @{
    id = $dataset_id
    name = $dataset_name
    }

     

}        


Function Insert-KeyVaultReferenceToSQLDBLinkedService
{
Param([int]$Linkedservice_id,[string] $keyvaultname,[string]$messagetype )

           
            $SecretPassword = Read-Host "Type password for $messagetype database : " -AsSecureString
            $kv = $keyvaultname.Replace('"','')
            $name = $Linkedservice_id.ToString()+'azurekeyvaultlinkedservicereference'
            write-host $kv
            Write-Host 'in ket vaut ref'
            Set-AzKeyVaultSecret -VaultName $kv -Name $name -SecretValue $SecretPassword
            
            Write-Host 'afetr ket vaut ref'
            $name = '"'+$name+'"'
            
            Sql-Execute -Qry "EXEC usp_UpdateKeyVaultReferedLinkedServiceParameters $Linkedservice_id,'$name'" -Qrydetails "Insert value for parameter : $linkedserviceparamname"
           return $null
            

}

Function Insert-LinkedServicesAndParameters
{
Param([String]$LinkedServiceType,[String]$resourceGroupName,[string]$AuthenticationType,[string]$ir,[string]$LinkedServiceName) 
    
    $Qry = "EXEC usp_InsertPipelineLinkedServiceDetails '$LinkedServiceType','$AuthenticationType','$LinkedServiceName'"
    $QryDetails = "Insert the $LinkedServiceType details to T_Pipeline_LinkedServices table"
    Sql-Execute -Qry $Qry -Qrydetails $QryDetails 
    Sql-Execute -Qry "EXEC [dbo].[usp_Insert_Pipeline_LinkedServiceParameters] '$LinkedServiceName','$ir'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
    
    $linkedservice_id = Sql-ExecuteScalar -Qry "SELECT TOP 1 PipelineLinkedServicesId FROM T_Pipeline_LinkedServices WHERE LinkedServiceName = '$LinkedServiceName'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
  
    $kvreq = Sql-ExecuteScalar -Qry "SELECT TOP 1 KeyVaultReferenceReq FROM T_List_LinkedServices WHERE LinkedServiceName = '$LinkedServiceType' AND AuthenticationType = '$AuthenticationType'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
  
    if ($kvreq -eq 1)
    {
     $x = Insert-KeyVaultReferenceToSQLDBLinkedService -Linkedservice_id $linkedservice_id -keyvaultname $keyvaultname -messagetype "secret for $LinkedServiceType $LinkedServiceName"
    }
    "help text" |Out-File "$ScriptPath\OutputPostDeploymentScripts\Help.txt"
    if (($LinkedServiceType -notin ('azureKeyVault','ADLSv2')))
    {
    if ($AuthenticationType -eq 'Managed Identity'){
    "Create USER [$dataFactoryName] FROM EXTERNAL PROVIDER; exec sp_addrolemember 'db_owner','$dataFactoryName'" | Out-File "$ScriptPath\OutputPostDeploymentScripts\ScriptFor$LinkedServiceName.sql"
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\Help.txt" "Create database contained user for $dataFactoryName on $LinkedServiceName. Refer the script created"
    }
    if (($AuthenticationType -eq 'Service Principal'))
    {
    "Create USER [$servicePrincipalName]  FROM EXTERNAL PROVIDER; exec sp_addrolemember 'db_owner','$servicePrincipalName'" | Out-File "$ScriptPath\OutputPostDeploymentScripts\ScriptFor$LinkedServiceName.sql"
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\Help.txt" "Create database contained user for $servicePrincipalId on $LinkedServiceName. Refer the script created"
    
    }

    }



    [pscustomobject] @{
    id = $linkedservice_id
    name = $LinkedServiceName
    }

    return [pscustomobject]
    
}

try
{
$ScriptPath = Split-Path $MyInvocation.InvocationName
$ConfigXMLFilePath = "$ScriptPath\InputXMLFile\XMLInput.xml"
[XML]$MetaDetails = Get-Content $ConfigXMLFilePath

$logdate = get-date
$datetime = (Get-Date -UFormat "%Y-%m-%d_%I-%M%p").tostring()
$Logfilepath = "$ScriptPath\Logs\log_$datetime.txt"
Write-Host $Logfilepath
$logfilepath = $Logfilepath

"$logdate`t************ Start************"|Out-File $logfilepath

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
    $out = Update-MasterParametersToDB
    $keyvaultname = $out.kvname
    $datafactoryname = $out.dfname
    $servicePrincipalName = $out.spnname
    Write-Host 'spp'
   Write-Host $servicePrincipalName
    foreach($linkedservicedetail in $MetaDetails.Metadata.LinkedServices.LinkedService)
    {
       
        $out = Insert-LinkedServicesAndParameters -LinkedServiceType $linkedservicedetail.Type -AuthenticationType $linkedservicedetail.AuthenticationType -resourceGroupName $resourceGroupName -ir $irname -LinkedServiceName $linkedservicedetail.Description
        
        $linkedservice_id = $out.id
        $linkedservicename = $out.name
        
        foreach($parameterdetail in $linkedservicedetail.Parameters.Parameter)
        {
            $paramval = '"'+$parameterdetail.Value+'"'
            $paramname = $parameterdetail.Name.Replace('$','$'+$linkedservice_id+'_')

            Sql-Execute -Qry "EXEC usp_UpdateLinkedServiceParameters '$paramname','$paramval',$linkedservice_id" -Qrydetails  "Update linked service parameter : $paramname"
        }
        
    
    }

    foreach($IRdetail in $MetaDetails.Metadata.IntegrationRunTimes.IntegrationRunTime)
    {
       $irnam = $IRdetail.Name
       $irtype = $IRdetail.Type
       Sql-Execute -Qry "EXEC usp_InsertPipelineIntegrationRunTimeDetails '$irnam','$irtype' " -Qrydetails  "Update linked service parameter : $paramname"
       
       if ($irtype -eq 'SelfHosted')
       {
        Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\Help.txt" "Need to install/register the self hosted IR on on-prem server $irnam . powershell script avaiable in the post deployment scripts folder."
        
        Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\Help.txt" "Copy the Auth key from azure portal"
       } 
        
    
    }
   
    foreach($ppdetail in $MetaDetails.Metadata.Pipelines.Pipeline)
    {
        $pipelinename = $ppdetail.Name
        
        # each execution will truncate the data in the pipeline tables   
        Truncate-Pipelinedetails -PipelineName $pipelinename
        Sql-Execute -Qry "EXEC usp_InsertPipelineDetails '$pipelinename'" -Qrydetails "Insert pipeline details in T_Pipelines table"
        $pipelineid = Sql-ExecuteScalar -Qry "SELECT PipelineId FROM [T_Pipelines] WHERE PipelineName = '$pipelinename'" -Qrydetails "max pipeline id"
        
        foreach($actdetail in $ppdetail.Activities.Activity)
        {
             if($actdetail.Type -eq 'Copy Activity')
            {
                $lsr = $actdetail.Source.LinkedServiceReference
                Sql-Execute -Qry "EXEC usp_insertpipelinesteps $pipelineid,'$lsr'" -Qrydetails  "Insert pipeline steps"
                Sql-Execute -Qry "EXEC usp_Insert_Pipeline_Parameters $pipelineid" -Qrydetails  "Insert pipeline activity parameters"
           
            }
        }
        
        foreach($actdetail in $ppdetail.Activities.Activity)
        {
          
            if($actdetail.Type -eq 'Lookup Activity')
            {
                $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceName $actdetail.LinkedServiceReference -AdditionalType $null -AdditionalVal $null
            
                $dsid = $od.id
                $lsr = $actdetail.LinkedServiceReference
                Write-Host "EXEC usp_updatepipelineactivityparameters 'LKPdataset',$dsid,$pipelineid,$lsr" 
                Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters 'LKPdataset',$dsid,$pipelineid,$lsr" -Qrydetails  "update pipeline activity parameter :$linksetname "
                               
            
            }
            if($actdetail.Type -eq 'Copy Activity')
            {
                $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceName $actdetail.Source.LinkedServiceReference -AdditionalType $null -AdditionalVal $null
                $dsid = $od.id

                Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters 'CPInputReference',$dsid,$pipelineid" -Qrydetails  "update pipeline activity parameter :$linksetname "
                
                foreach($tbldetail in $actdetail.Source.Tables.Table)
                {
                    $tblname = $tbldetail.Name
                    $schname = $tbldetail.schema
                    Sql-Execute -Qry "EXEC  usp_InsertPipelineTablesToBeMoved $pipelineid,'$tblname','$schname'" -Qrydetails  "insert tables to be moved "
                    
                }

                $od =  Insert-DatasetsAndParameters -PipelineId $pipelineid -LinkedServiceName $actdetail.Sink.LinkedServiceReference -AdditionalType 'SinkFileFormat' -AdditionalVal 'DelimitedText'
                $dsid = $od.id
                Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters 'CPOutputReference',$dsid,$pipelineid" -Qrydetails  "update pipeline activity parameter :$linksetname "

                foreach($parameterdetail in $actdetail.Sink.SinkParameters.Parameter)
                {
                    $paramval = $parameterdetail.Value
                    $paramname = $parameterdetail.Name.Replace('$','$'+$dsid+'_'+$pipelineid+'_')
                    Sql-Execute -Qry "EXEC [usp_UpdatePipelineDataSetParameters] '$paramname','$paramval',$dsid,$pipelineid" -Qrydetails "Insert value for parameter : $paramname"
                    
                }
                
                Sql-Execute -Qry "EXEC  usp_updatepipelineactivityparameters 'LKPQuery',$dsid,$pipelineid" -Qrydetails  "update activity parameter :  $qryparamname"
                           
                                   
            }

        }


        $SqlCmd.CommandText = "EXEC final_execution_ps_new $pipelineid"
    
        $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SqlCmd
        $dataset = new-object System.Data.Dataset
        $DataAdapter.Fill($dataset)
        New-Item -Path "$ScriptPath\OutputPipelineScripts\$pipelinename.ps1" -ItemType File -Force
        Add-Content -Value ' Param([Parameter(Mandatory=$True,Position=1)][string]$logfilepath,[Parameter(Mandatory=$True,Position=2)][string]$ScriptPath)' -Path "$ScriptPath\OutputPipelineScripts\$pipelinename.ps1"
        for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++) 
        {
        Add-Content -Value ($dataset.Tables[0].Rows[$i][0].ToString()) -Path "$ScriptPath\OutputPipelineScripts\$pipelinename.ps1"
        }
        
        $scriptpath1 = "$ScriptPath\OutputPipelineScripts\$pipelinename.ps1"
        $params = "-logfilepath '$logfilepath' -Scriptpath '$Scriptpath'"
        Invoke-Expression "$scriptpath1 $params"
        }


    $SqlConnection.Close()
}

catch
{
#Write-host $error
Add-Content $LogFilePath $error
Add-Content $LogFilePath "Script failed with errors. Please check log file"
Write-Host "Deployment Failed with Errors. Please refer log file"
}

