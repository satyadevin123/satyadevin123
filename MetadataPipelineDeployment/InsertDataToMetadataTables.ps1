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



Function Import-Excel([string]$FilePath, [string]$csvfile, [string]$SheetName = "")
{
    
    if (Test-Path -path $csvFile) { Remove-Item -path $csvFile }

    # convert Excel file to CSV file
    $xlCSVType = 6 # SEE: http://msdn.microsoft.com/en-us/library/bb241279.aspx
    $excelObject = New-Object -ComObject Excel.Application  
    $excelObject.Visible = $false 
    $workbookObject = $excelObject.Workbooks.Open($FilePath)
    SetActiveSheet $workbookObject $SheetName | Out-Null
    $workbookObject.SaveAs($csvFile,$xlCSVType) 
    $workbookObject.Saved = $true
    $workbookObject.Close()

     # cleanup 
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbookObject) |
        Out-Null
    $excelObject.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelObject) |
        Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    # now import and return the data 
  #  Import-Csv -path $csvFile
}

Function FindSheet([Object]$workbook, [string]$name)
{
    $sheetNumber = 0
    for ($i=1; $i -le $workbook.Sheets.Count; $i++) {
        if ($name -eq $workbook.Sheets.Item($i).Name) { $sheetNumber = $i; break }
    }
    return $sheetNumber
}

Function SetActiveSheet([Object]$workbook, [string]$name)
{
    if (!$name) { return }
    $sheetNumber = FindSheet $workbook $name
    if ($sheetNumber -gt 0) { $workbook.Worksheets.Item($sheetNumber).Activate() }
    return ($sheetNumber -gt 0)
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
       $x = Create-KeyVault -keyvaultName $keyvaultname -keyvaultlocation $keyvaultlocation -resourceGroupName $resourceGroupName
      
        if($servicePrincipalId -ne $null -and $servicePrincipalId -ne '')
        {
             
            $SecretPassword = Read-Host "Type key for service principal : " -AsSecureString
            $kv = $keyvaultname.Replace('"','')
            $name = 'spkazurekeyvaultlinkedservicereference'
            $x = Set-AzKeyVaultSecret -VaultName $kv -Name $name -SecretValue $SecretPassword 
            $name = '"'+$name+'"'
            Sql-Execute -Qry "EXEC usp_UpdateMasterParametersList '`$servicePrincipalKey','$name'"  -Qrydetails 'Update master parameter $servicePrincipalKey'
         }

        $res = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName  -Name "LogicAppDeployment" -TemplateFile "$ScriptPath\LogicAppDeploymenttemplate.json" 
        $logicappurl = (Get-AzLogicAppTriggerCallbackUrl  -ResourceGroupName $resourceGroupName -Name "LogicAppToSendMailFromADF" -TriggerName "manual").Value        $logicappurl = '"'+$logicappurl+'"'
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
Param([String]$DataSetName,[int]$PipelineId,[String]$LinkedServiceName,[String]$AdditionalType,[String]$AdditionalVal) 
    
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSets '$DataSetName','$LinkedServiceName',$PipelineId,'$AdditionalType','$AdditionalVal'" -Qrydetails  "Insert datasets for metadata db"
            $SqlCmd.CommandText = "SELECT PipelineDatasetId FROM [T_Pipeline_DataSets] WHERE PipelineId = $PipelineId AND DataSetName = '$DataSetName'"
            $dataset_id = Sql-ExecuteScalar -Qry "SELECT PipelineDatasetId FROM [T_Pipeline_DataSets] WHERE PipelineId = $PipelineId AND DataSetName = '$DataSetName'" -Qrydetails "max dataset id"
            
            Sql-Execute -Qry "EXEC usp_InsertPipelineDataSetParameters '$LinkedServiceName',$dataset_id,$PipelineId" -Qrydetails  "Insert dataset parameters for metadata db"
            
      
    [pscustomobject] @{
    id = $dataset_id
    name = $dataset_name
    }

     

}        


Function Insert-KeyVaultReferenceToSQLDBLinkedService
{
Param([int]$Linkedservice_id,[string] $keyvaultname,[string]$messagetype )

           
            $SqlCmd.CommandText = "EXEC [usp_GetKeyVaultReferedParameters] $Linkedservice_id"
            $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SqlCmd
            $dataset = new-object System.Data.Dataset
            $DataAdapter.Fill($dataset)
            $result = $dataset.Tables[0]
            $kv = $keyvaultname.Replace('"','')
           
            foreach($row in $result) 
            {
            $desc = $row.KeyVaultReferenceDescription.ToString()
            $SecretPassword = Read-Host "Type $desc : " -AsSecureString
            $paramname = $row.ParameterName.ToString()
            $name = $Linkedservice_id.ToString()+"$paramname"
            $name = $name.Replace('$','')
            
            Set-AzKeyVaultSecret -VaultName $kv -Name $name -SecretValue $SecretPassword
            $name = '"'+$name+'"'
            Sql-Execute -Qry "EXEC usp_UpdateKeyVaultReferedLinkedServiceParameters $Linkedservice_id,'$name','$paramname'" -Qrydetails "Insert value for parameter : $linkedserviceparamname"
            }
            return $null
            

}

Function Insert-LinkedServicesAndParameters
{
Param([String]$LinkedServiceType,[String]$resourceGroupName,[string]$AuthenticationType,[string]$ir,[string]$LinkedServiceName) 
    
    $Qry = "EXEC usp_InsertPipelineLinkedServiceDetails '$LinkedServiceType','$AuthenticationType','$LinkedServiceName'"
    $QryDetails = "Insert the $LinkedServiceType details to T_Pipeline_LinkedServices table"
    Sql-Execute -Qry $Qry -Qrydetails $QryDetails 
    Sql-Execute -Qry "EXEC [dbo].[usp_InsertPipelineLinkedServiceParameters] '$LinkedServiceName','$ir'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
    
    $linkedservice_id = Sql-ExecuteScalar -Qry "SELECT TOP 1 PipelineLinkedServicesId FROM T_Pipeline_LinkedServices WHERE LinkedServiceName = '$LinkedServiceName'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
  
    $kvreq = Sql-ExecuteScalar -Qry "SELECT TOP 1 KeyVaultReferenceReq FROM T_List_LinkedServices WHERE LinkedServiceName = '$LinkedServiceType' AND AuthenticationType = '$AuthenticationType'" -Qrydetails  "Insert the key vault parameter details to T_Pipeline_LinkedService_Parameters table"
  
    if ($kvreq -eq 1)
    {
     $x = Insert-KeyVaultReferenceToSQLDBLinkedService -Linkedservice_id $linkedservice_id -keyvaultname $keyvaultname -messagetype "secret for $LinkedServiceType $LinkedServiceName"
    }
    if (($LinkedServiceType -notin ('azureKeyVault','ADLSv2')))
    {
    if ($AuthenticationType -eq 'Managed Identity'){
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "--------------------------"
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "Create database contained user for $dataFactoryName on $LinkedServiceName. Refer the script created"
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "--------------------------"
    "Create USER [$dataFactoryName] FROM EXTERNAL PROVIDER; exec sp_addrolemember 'db_owner','$dataFactoryName'" | Out-File "$ScriptPath\OutputPostDeploymentScripts\ScriptFor$LinkedServiceName.sql"
    
    }
    if (($AuthenticationType -eq 'Service Principal'))
    {
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "--------------------------"
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "Create database contained user for $servicePrincipalId on $LinkedServiceName. Refer the script created"
    Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "--------------------------"
    "Create USER [$servicePrincipalName]  FROM EXTERNAL PROVIDER; exec sp_addrolemember 'db_owner','$servicePrincipalName'" | Out-File "$ScriptPath\OutputPostDeploymentScripts\ScriptFor$LinkedServiceName.sql"
    
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
if(!(Test-Path -path "$Scriptpath\Logs")){New-Item -ItemType directory -Path "$Scriptpath\Logs"}
if(!(Test-Path -path "$Scriptpath\OutputPipelineScripts")){New-Item -ItemType directory -Path "$Scriptpath\OutputPipelineScripts"}
if(!(Test-Path -path "$Scriptpath\OutputPostDeploymentScripts")){New-Item -ItemType directory -Path "$Scriptpath\OutputPostDeploymentScripts"}
if(!(Test-Path -path "$Scriptpath\Archive")){New-Item -ItemType directory -Path "$Scriptpath\Archive"}

Get-ChildItem "$ScriptPath\InputXMLFile\" -Filter *.xml | 
Foreach-Object {
    $content = Get-Content $_.FullName
    
$ConfigXMLFilePath = $_.FullName
[XML]$MetaDetails = Get-Content $ConfigXMLFilePath

Connect-AzAccount

$logdate = get-date
$datetime = (Get-Date -UFormat "%Y-%m-%d_%I-%M%p").tostring()

$archivexmlfilepath =  ($_.BaseName + "_$datetime.xml")
$Logfilepath = "$ScriptPath\Logs\log_$datetime.txt"

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

"help text:" |Out-File "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt"
    
# Update master parameters to t_master_parameters table   
    $out = Update-MasterParametersToDB
    $keyvaultname = $out.kvname
    $datafactoryname = $out.dfname
    $servicePrincipalName = $out.spnname
    
    $LinkedServices = ''
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
        
        $LinkedServices = $LinkedServices+$linkedservicedetail.Description+','
    
    }
    $LinkedServices = $LinkedServices.Substring(0,$LinkedServices.Length-1)
   
    $IntegrationRunTimes = ''

    foreach($IRdetail in $MetaDetails.Metadata.IntegrationRunTimes.IntegrationRunTime)
    {
       $irnam = $IRdetail.Name
       $irtype = $IRdetail.Type
       Sql-Execute -Qry "EXEC usp_InsertPipelineIntegrationRunTimeDetails '$irnam','$irtype' " -Qrydetails  "Update linked service parameter : $paramname"
       
       if ($irtype -eq 'SelfHosted')
       {
        Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "--------------------------"
        Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "Need to install/register the self hosted IR on on-prem server $irnam . powershell script avaiable in the post deployment scripts folder."
        Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "Copy the Auth key from azure portal"
        Add-Content -Path "$ScriptPath\OutputPostDeploymentScripts\PostDeploySteps.txt" "--------------------------"
       } 
       $IntegrationRunTimes = $IntegrationRunTimes+$irnam+','
    
    }
    $IntegrationRunTimes = $IntegrationRunTimes.Substring(0,$IntegrationRunTimes.Length-1)
   
    foreach($ppdetail in $MetaDetails.Metadata.Pipelines.Pipeline)
    {
        $pipelinename = $ppdetail.Name
        
        # each execution will truncate the data in the pipeline tables   
        Truncate-Pipelinedetails -PipelineName $pipelinename
        Sql-Execute -Qry "EXEC usp_InsertPipelineDetails '$pipelinename'" -Qrydetails "Insert pipeline details in T_Pipelines table"
        $pipelineid = Sql-ExecuteScalar -Qry "SELECT PipelineId FROM [T_Pipelines] WHERE PipelineName = '$pipelinename'" -Qrydetails "max pipeline id"
        
       

        foreach($actdetail in $ppdetail.Activities.Activity)
        {
            
            if($actdetail.Type -eq 'Copy Activity' -and $actdetail.Description -eq 'DataCopy')
            {
                $lsr = $actdetail.Source.LinkedServiceReference
                Sql-Execute -Qry "EXEC usp_insertpipelinesteps $pipelineid,'$lsr','no'" -Qrydetails  "Insert pipeline steps"
            }
                    
        
        }
        foreach($actdetail in $ppdetail.Activities.Activity)
        {
            if($actdetail.Type -eq 'Copy Activity' -and $actdetail.Description -eq 'SchemaCopy')
            {
                $lsr = $actdetail.Source.LinkedServiceReference
             Sql-Execute -Qry "EXEC usp_insertpipelinesteps $pipelineid,'$lsr','yes'" -Qrydetails  "Insert pipeline steps"
            }

        }
        Sql-Execute -Qry "EXEC usp_InsertPipelineActivityParameters $pipelineid" -Qrydetails  "Insert pipeline activity parameters"
        foreach($actdetail in $ppdetail.Activities.Activity)
        {
          
            if($actdetail.Type -eq 'Lookup Activity')
            {
                $datasetname = "DS_LKP_$pipelineid"
                $od =  Insert-DatasetsAndParameters -DataSetName $datasetname -PipelineId $pipelineid -LinkedServiceName $actdetail.LinkedServiceReference -AdditionalType $null -AdditionalVal $null
            
                $dsid = $od.id
                $lsr = $actdetail.LinkedServiceReference
                Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters 'LKPdataset',$dsid,$pipelineid,$lsr" -Qrydetails  "update pipeline activity parameter :$linksetname "
                               
            }
            if($actdetail.Type -eq 'Copy Activity')
            {
                $desc = $actdetail.Description
                
                $datasetname = "DS_CP_SRC_"+$desc+"_$pipelineid"
                $od =  Insert-DatasetsAndParameters -DataSetName $datasetname -PipelineId $pipelineid -LinkedServiceName $actdetail.Source.LinkedServiceReference -AdditionalType $null -AdditionalVal $null
                $dsid = $od.id
                Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters 'CPInputReference',$dsid,$pipelineid,'','$desc'" -Qrydetails  "update pipeline activity parameter :$linksetname "
                
                foreach($tbldetail in $actdetail.Source.Tables.Table)
                {
                    $tblname = $tbldetail.Name
                    $schname = $tbldetail.schema
                    $IsIncremental = $tbldetail.IsIncremental
                    $RefreshBasedOn = $tbldetail.LastRefreshBasedOnColumn
                    Sql-Execute -Qry "EXEC  usp_InsertPipelineTablesToBeMoved $pipelineid,'$tblname','$schname','$IsIncremental','$RefreshBasedOn'" -Qrydetails  "insert tables to be moved "
                    
                }
                $datasetname = "DS_CP_SINK_"+$desc+"_$pipelineid"
                
                $od =  Insert-DatasetsAndParameters -DataSetName $datasetname -PipelineId $pipelineid -LinkedServiceName $actdetail.Sink.LinkedServiceReference -AdditionalType 'SinkFileFormat' -AdditionalVal 'DelimitedText'
                $dsid = $od.id
                
                Sql-Execute -Qry "EXEC usp_updatepipelineactivityparameters 'CPOutputReference',$dsid,$pipelineid,'','$desc'" -Qrydetails  "update pipeline activity parameter :$linksetname "
                
                
                foreach($parameterdetail in $actdetail.Sink.SinkParameters.Parameter)
                {
                    $paramval = $parameterdetail.Value
                    $paramname = $parameterdetail.Name.Replace('$','$'+$dsid+'_'+$pipelineid+'_')
                    Sql-Execute -Qry "EXEC [usp_UpdatePipelineDataSetParameters] '$paramname','$paramval',$dsid,$pipelineid" -Qrydetails "Insert value for parameter : $paramname"
                    
                }
                if($actdetail.Description -eq 'DataCopy')
                {
                
                Sql-Execute -Qry "EXEC  usp_updatepipelineactivityparameters 'LKPQuery',$dsid,$pipelineid" -Qrydetails  "update activity parameter :  $qryparamname"
                
                }           
            }


        }
        
        $excelfile = "$ScriptPath\InputXMLFile\SourceTableSchemaDetails.xlsx"
        
        $csvfile = "$ScriptPath\InputXMLFile\SourceTableSchemaDetails.csv"
        if(Test-Path "$ScriptPath\InputXMLFile\SourceTableSchemaDetails.xlsx")
        {
        Import-Excel -FilePath $excelfile -SheetName 'Sheet1' -csvfile $csvfile
        Import-Csv "$ScriptPath\InputXMLFile\SourceTableSchemaDetails.csv" | ? PipelineName -eq $pipelinename | ForEach-Object{

        Sql-Execute -Qry "EXEC usp_InsertSourceTableColumnDetails  $pipelineid,'$($_.SchemaName)','$($_.TableName)','$($_.ColumnName)','$($_.Key)','$($_.Type)','$($_.Length)','$($_.OutputLen)','$($_.Decimals)'"  -Qrydetails "sd"
        }
        }

        foreach($tbldetail in $actdetail.Source.Tables.Table)
        {
                    $tblname = $tbldetail.Name
                    $schname = $tbldetail.schema
                    $IsIncremental = $tbldetail.IsIncremental
                    $RefreshBasedOn = $tbldetail.LastRefreshBasedOnColumn
                    Sql-Execute -Qry "EXEC  usp_UpdatePipelineTablesQuery $pipelineid,'$tblname','$schname','$IsIncremental','$RefreshBasedOn'" -Qrydetails  "update tables to be moved "
                    
        }

        $SqlCmd.CommandText = "EXEC final_execution_ps_new $pipelineid,'$LinkedServices','$IntegrationRunTimes'"
    
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
        Login-AzAccount
        Invoke-Expression "$scriptpath1 $params"
        }


    $SqlConnection.Close()

    Move-Item -Path $_.FullName -Destination "$Scriptpath\Archive\$archivexmlfilepath" -Force

    if(Test-Path $excelfile){ Move-Item -Path $excelfile -Destination "$Scriptpath\Archive\SourceTableSchemaDetails_$datetime.xlsx" -Force}
    
    if(Test-Path $csvfile){ Move-Item -Path $csvfile -Destination "$Scriptpath\Archive\SourceTableSchemaDetails_$datetime.csv" -Force}

}
}
catch
{
#Write-host $error
Add-Content $LogFilePath $error
Add-Content $LogFilePath "Script failed with errors. Please check log file"
Write-Host "Deployment Failed with Errors. Please refer log file"
}

