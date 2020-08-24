


--EXEC [dbo].[final_execution_ps_new] 3

CREATE procedure [dbo].[final_execution_ps_new] 
 (@PipelineId INT)
as


Declare @MasterPipelineActivityJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
insert into @MasterPipelineActivityJsoncode select '$pipelineDefinition = @"'
insert into @MasterPipelineActivityJsoncode select Jsoncode From T_Master_Pipelines Where MasterPipelineName='Sendmail'
insert into @MasterPipelineActivityJsoncode select '"@'
insert into @MasterPipelineActivityJsoncode select '$pipelineDefinition | Out-File c:\$finaloutput.json'

insert into @MasterPipelineActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelinename -Force -File "c:\$finaloutput.json"'

Declare @pipelinename varchar(100)
set @pipelinename = (select PipelineName from [dbo].[T_Pipelines] where id=@PipelineId )

declare @activity_code varchar(max)
SELECT  @activity_code=coalesce(@activity_code+ ',','')+code from [dbo].[T_Pipelines] P
Join [dbo].[T_Pipelines_Steps] PS on P.Id = PS.PipelineiD
join [dbo].[T_List_Activities] LS on LS.ID = PS.Activity_ID
where p.Enabled=1

Declare @LSCount int,@LinkedService varchar(200),@name varchar(200)
Declare @LinkedServiceJsoncode table(Jsoncode varchar(max), ID INT IDENTITY(1,1))
set @LSCount =(SELECT count(*) from T_Pipeline_LinkedServices Where PipeLineId =@PipelineId )

declare @tbl table
(rownum int, id int)

insert into @tbl
select row_number() over(order by id),id from dbo.T_Pipeline_LinkedServices where PipelineId = @PipelineId


while @LSCount >0
begin
SELECT @LinkedService= LinkedService_Name , @name = parametervalue from [dbo].[T_Pipeline_LinkedServices] TPL 
JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.ID = TPL.LinkedServiceID 
JOIN [T_Pipeline_LinkedService_Parameters] TPLP on TPLP.LinkedServerId =TPL.Id
JOIN @tbl t ON t.id = tpl.Id
where TPLP.ParameterName like '%linkedservicename%'
AND t.rownum =@LSCount


insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition = @"'
insert into @LinkedServiceJsoncode select Jsoncode from [dbo].[T_Pipeline_LinkedServices] 
TPL JOIN [dbo].[T_List_LinkedServices] TLL ON TLL.ID = TPL.LinkedServiceID where TPL.id=@LSCount
insert into @LinkedServiceJsoncode select '"@'
insert into @LinkedServiceJsoncode select '$'+@LinkedService+'Definition | Out-File c:\'+@LinkedService+'.json'
insert into @LinkedServiceJsoncode select  'New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name '+@name+' -File "c:\'+@LinkedService+'.json"'

set @LSCount=@LSCount-1
End


Declare @DSCount int,@DataSet varchar(200)
Declare @DataSetJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
set @DSCount =(SELECT count(*) from [dbo].[T_Pipeline_DataSets] Where PipeLineId =@PipelineId )

declare @tbl1 table
(rownum int, id int)

insert into @tbl1
select row_number() over(order by id),id from dbo.[T_Pipeline_DataSets] where PipelineId = @PipelineId

while @DSCount >0
begin

SELECT @DataSet= DataSet_name , @name = parametervalue from [dbo].[T_Pipeline_DataSets] TPD
JOIN [dbo].[T_List_DataSets] TLD ON TLD.ID = TPD.DataSetId 
JOIN [T_Pipeline_DataSet_Parameters] TPDP on TPDP.DatasetId =TPD.Id
JOIN @tbl1 t ON t.Id = TPD.Id
where TPDP.ParameterName like '%datasetname%'
AND t.rownum =@DSCount

--set @Dataset= (select DataSet_Name from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.id where TPD.id =@DSCount)

insert into @DataSetJsoncode select '$'+@DataSet+'Definition = @"'
insert into @DataSetJsoncode select Jsoncode from [dbo].[T_Pipeline_DataSets] TPD JOIN [T_List_DataSets] TLD ON TPD.DataSetId= TLD.id where TPD.id=@DSCount
insert into @DataSetJsoncode select '"@'
insert into @DataSetJsoncode select '$'+@DataSet+'Definition | Out-File c:\'+@DataSet+'.json'
insert into @DataSetJsoncode select  'New-AzDataFactoryV2DataSet -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name "'+@name+'" -File "c:\'+@DataSet+'.json"'

set @DSCount=@DSCount-1
End


Declare @ActivityJsoncode table(Jsoncode varchar(max),ID INT IDENTITY(1,1))
insert into @ActivityJsoncode select '$pipelineDefinition = @"'
insert into @ActivityJsoncode select '{'
insert into @ActivityJsoncode select '"name": "$pipelinename",'
insert into @ActivityJsoncode select '"properties": {'
insert into @ActivityJsoncode select         '"activities": ['
insert into @ActivityJsoncode Exec [dbo].[usp_return_activitycode]@PipelineId 
insert into @ActivityJsoncode select ']'
insert into @ActivityJsoncode select     '}'
insert into @ActivityJsoncode select 	'}'
insert into @ActivityJsoncode select '"@'
insert into @ActivityJsoncode select '$pipelineDefinition | Out-File c:\$finaloutput.json'

insert into @ActivityJsoncode select  'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Force -Name $pipelinename -File "c:\$finaloutput.json"'





--select 'Decalre '+ParameterName from [dbo].[T_Dataset_Parameters]

--select 'SET '+ ParameterName+' = '+ ParameterValue from [dbo].[T_Dataset_Parameters]



--select * from @DataSetJsoncode
IF (Select MAX(EmailNotificationEnabled) From T_Pipelines_steps) =1
SELECT *
FROM (
		select '$pipelinename = "'+ @pipelinename +'"' AS Parameter,0 AS ID, 'MasterParameterList' AS DescType 
	   union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'MasterParameterList' AS DescType from T_Master_Parameters_List
		--union all
		--Select '#Pass values to Linked Service Parameters',0,'comments'
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters]
		--union all
		--Select '#Pass values to Dataset Parameters',0,'comments'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,ID, 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_Dataset_Parameters]
		--union all
		--Select '#Pass values to Activity Parameters',0,'comments'
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,ID, 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,ID, 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List
		union all
		select Jsoncode AS Parameter,ID, 'LSCode' AS DescType from @LinkedServiceJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'DSCode' AS DescType from @DataSetJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'Mastercode' AS DescTyp from @MasterPipelineActivityJsoncode
		Union all
		select Jsoncode AS Parameter, ID, 'ActivityCode' AS DescType from @ActivityJsoncode
) A
ORDER BY CASE WHEN DescType Like '%MasterParameterList%' THEN 1 
			  WHEN DescType Like '%LinkedServiceParameterList%' THEN 2 
			  WHEN DescType Like '%DatasetParameterList%' THEN 3
			  WHEN DescType Like '%ActivityParameterList%' THEN 4
			  WHEN DescType Like '%MasterPipelineParameterList%' THEN 5
			  WHEN DescType Like '%LSCode%' THEN 6
			  WHEN DescType Like '%DSCode%' THEN 7 
			  WHEN DescType Like '%Mastercode%' THEN 9
			  WHEN DescType Like '%ActivityCode%' THEN 10 END 
			  ,ID




ELSE
SELECT *
FROM (  
       select '$pipelinename = "'+ @pipelinename +'"' AS Parameter,0 AS ID, 'MasterParameterList' AS DescType 
	   union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'MasterParameterList' AS DescType from T_Master_Parameters_List
		union all
		select ParameterName+' = '+ ParameterValue AS Parameter,ID, 'LinkedServiceParameterList' AS DescType from [dbo].[T_Pipeline_LinkedService_Parameters]
		union all
		select ParameterName+' = "'+ ParameterValue +'"' AS Parameter,ID, 'DatasetParameterList' AS DescType from [dbo].[T_Pipeline_Dataset_Parameters]
		union all
		select ParameterName+' = "'+ ParameterValue+'"' AS Parameter,ID, 'ActivityParameterList' AS DescType from [dbo].[T_Pipeline_Activity_Parameters] where parametername not like '%activityjsoncode%'
		union all
		select ParameterName+' = '+ ParameterValue+'' AS Parameter,ID, 'MasterPipelineParameterList' AS DescType from T_Master_Pipelines_Parameters_List
		union all
		select Jsoncode AS Parameter,ID, 'LSCode' AS DescType from @LinkedServiceJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'DSCode' AS DescType from @DataSetJsoncode 
		union all
		select Jsoncode AS Parameter, ID, 'ActivityCode' AS DescType from @ActivityJsoncode
) A
ORDER BY CASE WHEN DescType Like '%MasterParameterList%' THEN 1 
			  WHEN DescType Like '%LinkedServiceParameterList%' THEN 2 
			  WHEN DescType Like '%DatasetParameterList%' THEN 3
			  WHEN DescType Like '%ActivityParameterList%' THEN 4
			  WHEN DescType Like '%MasterPipelineParameterList%' THEN 5
			  WHEN DescType Like '%LSCode%' THEN 6
			  WHEN DescType Like '%DSCode%' THEN 7 
			  WHEN DescType Like '%Mastercode%' THEN 9
			  WHEN DescType Like '%ActivityCode%' THEN 10 END