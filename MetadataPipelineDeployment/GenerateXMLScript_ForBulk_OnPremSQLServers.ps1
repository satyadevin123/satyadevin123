
Function SetActiveSheet([Object]$workbook, [string]$name)
{
    if (!$name) { return }
    $sheetNumber = FindSheet $workbook $name
    if ($sheetNumber -gt 0) { $workbook.Worksheets.Item($sheetNumber).Activate() }
    return ($sheetNumber -gt 0)
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

  
}     
 
 
    $excelfile = "D:\MetadataPoC_14Apr\Book1.xlsx"
        
    if(Test-Path "D:\MetadataPoC_14Apr\Book1.xlsx")
    {
        #generate json for onpremsqllinkedservices
        
        $csvfile1 = "D:\MetadataPoC_14Apr\OnPremSQLLinkedServices.csv"
        Import-Excel -FilePath $excelfile -SheetName 'OnPremSQLLinkedServices' -csvfile $csvfile1
        $csvfile1 = Import-Csv $csvfile1
        $OnPremSQLLinkedServicesjson= ' '
        foreach ($row in $csvfile1)
            {
                
                $OnPremSQLLinkedServicesjson = $OnPremSQLLinkedServicesjson+
               "<LinkedService Type='OnPremiseSQLServer' AuthenticationType='SQL Authentication' Description='$($row.LinkedServiceName)'>
                <Parameters><Parameter Name='`$onpremSqlDBServerName' Value = '$($row.onpremSqlDBServerName)'/><Parameter Name='`$onpremSqlDatabaseName' Value = '$($row.onpremSqlDatabaseName)'/><Parameter Name='`$onpremSqlDBUserName' Value = '$($row.onpremSqlDBUserName)'/><Parameter Name='`$IRName' Value = '$($row.IRName)'/></Parameters>
                </LinkedService>
                "
            }
        
       
        #generate json for AzureEnvSetup

        $csvfile2 = "D:\MetadataPoC_14Apr\AzureEnvSetup.csv"
        Import-Excel -FilePath $excelfile -SheetName 'AzureEnvSetup' -csvfile $csvfile2
        $csvfile2 = Import-Csv $csvfile2
        $AzureEnvSetupjson= ' '
        foreach ($row in $csvfile2)
            {
                $AzureEnvSetupjson = $AzureEnvSetupjson+
               "<AzureEnvSetup><Parameters>
                <Parameter Name='`$tenantid' Value = '$($row.tenantid)'/>
                <Parameter Name='`$subscriptionid' Value = '$($row.subscriptionid)'/>
                <Parameter Name='`$resourceGroupName' Value = '$($row.resourceGroupName)'/>
                <Parameter Name='`$dataFactoryName' Value = '$($row.dataFactoryName)'/>
                <Parameter Name='`$dataFactoryNameLocation' Value = '$($row.dataFactoryNameLocation)'/>
                <Parameter Name='`$SinkAccountName' Value = '$($row.SinkAccountName)'/>
                <Parameter Name='`$keyvaultname' Value = '$($row.keyvaultname)'/>
                <Parameter Name='`$keyvaultlocation' Value = '$($row.dataFactoryNameLocation)'/>
                <Parameter Name='`$EmailTo' Value = '$($row.EmailTo)'/></Parameters>
                </AzureEnvSetup>
                "
             }

         #generate json for IntegrationRunTimes

        $csvfile3 = "D:\MetadataPoC_14Apr\IntegrationRunTimes.csv"
        Import-Excel -FilePath $excelfile -SheetName 'IntegrationRunTimes' -csvfile $csvfile3
        $csvfile3 = Import-Csv $csvfile3
        $IntegrationRunTimesjson= '<IntegrationRunTimes>'
        foreach ($row in $csvfile3)
            {
                $IntegrationRunTimesjson = $IntegrationRunTimesjson+
               "<IntegrationRunTime Name='$($row.Name)' Type ='$($row.Type)'/>
                
                "
             }
        $IntegrationRunTimesjson = $IntegrationRunTimesjson+ '</IntegrationRunTimes>'
     }

      #generate json for KVLinkedServices
        
        $csvfile4 = "D:\MetadataPoC_14Apr\KVLinkedServices.csv"
        Import-Excel -FilePath $excelfile -SheetName 'KVLinkedServices' -csvfile $csvfile4
        $csvfile4 = Import-Csv $csvfile4
        $KVLinkedServicesjson= ' '
        foreach ($row in $csvfile4)
            {
               
                $KVLinkedServicesjson = $KVLinkedServicesjson+
               "<LinkedService Type='azureKeyVault' AuthenticationType='Managed Identity' Description='KeyVault'>
                <Parameters>
                <Parameter Name='`$keyvaultname' Value = '$($row.LinkedServiceName)'/>
                </Parameters>
                </LinkedService>
                "
            }
           
        #generate json for MetadataDBLinkedService
        
        $csvfile5 = "D:\MetadataPoC_14Apr\MetadataDBLinkedService.csv"
        Import-Excel -FilePath $excelfile -SheetName 'MetadataDBLinkedService' -csvfile $csvfile5
        $csvfile5 = Import-Csv $csvfile5
        $MetadataDBLinkedServicejson= ' '
        foreach ($row in $csvfile5)
            {
            $metadataserver = "$($row.azureSqlDBServerName)"
               $metadatabasename = "$($row.azureSqlDatabaseName)"

                $MetadataDBLinkedServicejson = $MetadataDBLinkedServicejson+
               "<LinkedService Type='azureSQLDatabase' AuthenticationType='Managed Identity' Description='$($row.LinkedServiceName)'>
                <Parameters>
                <Parameter Name='`$azureSqlDBServerName' Value = '$($row.azureSqlDBServerName)'/>
                <Parameter Name='`$azureSqlDatabaseName' Value = '$($row.azureSqlDatabaseName)'/>
                </Parameters>
                </LinkedService>
                "
            }

         #generate json for ADLSLinkedService
        
        $csvfile8 = "D:\MetadataPoC_14Apr\ADLSLinkedService.csv"
        Import-Excel -FilePath $excelfile -SheetName 'ADLSLinkedService' -csvfile $csvfile8
        $csvfile8 = Import-Csv $csvfile8
        $ADLSLinkedServicejson= ' '
        foreach ($row in $csvfile8)
            {
               
                $ADLSLinkedServicejson = $ADLSLinkedServicejson+
"
                <LinkedService Type='ADLSv2' AuthenticationType='Managed Identity' Description='$($row.LinkedServiceName)'>
<Parameters>
<Parameter Name='`$ADLSv2AccountName' Value='$($row.ADLSv2AccountName)'/>
<Parameter Name='`$URL' Value='$($row.URL)'/>
</Parameters>
</LinkedService>"

            
            }

         #generate json for PipelineSourceTables
        
        $csvfile6 = "D:\MetadataPoC_14Apr\PipelineSourceTables.csv"
        Import-Excel -FilePath $excelfile -SheetName 'PipelineSourceTables' -csvfile $csvfile6
        $csvfile6 = Import-Csv $csvfile6
        
        $csvfile7 = "D:\MetadataPoC_14Apr\PipelineSink.csv"
        Import-Excel -FilePath $excelfile -SheetName 'PipelineSink' -csvfile $csvfile7
        $csvfile7 = Import-Csv $csvfile7

#        $ls = $csvfile6 |  Foreach-Object { $_.LinkedServiceReference } |  Select-Object -unique   

        $PipelineSourceTablesjson= ' '
        $ints = Import-Csv "D:\MetadataPoC_14Apr\PipelineSourceTables.csv" |  Foreach-Object { $_.PipelineName } |  Select-Object -unique    
                
        foreach ($row in $ints)
            {
            $ls = $csvfile6 |  ? PipelineName -eq $row |  Foreach-Object { $_.LinkedServiceReference } | Select-Object -unique   
            $lssink = $csvfile7 |  ? PipelineName -eq $row |  Foreach-Object { $_.LinkedServiceReference } | Select-Object -unique   

             $PipelineSourceTablesjson = $PipelineSourceTablesjson + " <Pipeline Name = '$row'>
            <Activities>
            <Activity Type='Lookup Activity' LinkedServiceReference='MetadataDB'>
            </Activity>
            <Activity Type ='Copy Activity' Description='DataCopy'>
            <Source LinkedServiceReference='$ls'>
            <Tables>"
           $pipes = $csvfile6 | ? PipelineName -eq $row
             foreach ($row1 in $pipes)
            {
            $PipelineSourceTablesjson = $PipelineSourceTablesjson +" <Table Name='$($row1.TableName)' schema='$($row1.Schema)' />"
         
            }
           
            $PipelineSourceTablesjson = $PipelineSourceTablesjson + " </Tables>
            </Source>"
            
             $pipes = $csvfile7 | ? PipelineName -eq $row
             foreach ($row1 in $pipes)
            {
            $PipelineSourceTablesjson = $PipelineSourceTablesjson +" 
           <Sink LinkedServiceReference='$lssink'>
<SinkParameters>
<Parameter Name='`$fileSystemFolderName' Value ='$($row1.fileSystemFolderName)'/>
<Parameter Name='`$CompressionCodectype' Value ='$($row1.CompressionCodectype)'/>
<Parameter Name='`$fileformat' Value ='$($row1.fileformat)'/>
<Parameter Name='`$fileextension' Value ='$($row1.fileextension)'/>
<Parameter Name='`$columndelimiter' Value ='$($row1.columndelimiter)'/>
</SinkParameters>
</Sink></Activity></Activities></Pipeline>"
            }
           
      
        }
        $metadatadbjson = "

        <MetadataDB Type ='azureSQLDatabase' AuthenticationType='SQL Authentication'>
<Parameters>
<Parameter Name='`$azureSqlDBServerName' Value = '$metadataserver'/>
<Parameter Name='`$azureSqlDatabaseName' Value = '$metadatabasename'/>
</Parameters>
</MetadataDB>"
 

New-item -Path "D:\MetadataPoC_14Apr\XMLInput_SqlOnPrem_GeneratedFromScript.xml" -ItemType "file" -Value "<Metadata>$AzureEnvSetupjson$IntegrationRunTimesjson<LinkedServices>$KVLinkedServicesjson$MetadataDBLinkedServicejson$ADLSLinkedServicejson$OnPremSQLLinkedServicesjson</LinkedServices>$metadatadbjson<Pipelines>$PipelineSourceTablesjson</Pipelines></Metadata>" -Force
