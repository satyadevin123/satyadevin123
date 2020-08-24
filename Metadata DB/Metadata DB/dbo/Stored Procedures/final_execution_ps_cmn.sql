
-- =============================================
-- Author			Create Date      Description		Changes
-- Venkat Satish					Initial Stored Proc
-- Chandra Mohan					Modifications		CHG001
--
-- =============================================


CREATE PROCEDURE [dbo].[final_execution_ps_cmn] @debug INT 
AS 
    SET NOCOUNT ON

	DECLARE @pipelinename VARCHAR(100), 
            @PipelineId   INT ,
			@parameterFolder VARCHAR(255)

    SET @pipelinename = (SELECT pipelinename 
                         FROM   [dbo].[t_pipelines] 
                         WHERE  id = 1) 
    SET @pipelinename = (SELECT id 
                         FROM   [dbo].[t_pipelines] 
                         WHERE  id = 1) 

    DECLARE @activity_code VARCHAR(max) 

    SELECT @activity_code = COALESCE(@activity_code+ ',', '') + code 
    FROM   [dbo].[t_pipelines] P 
           JOIN [dbo].[t_pipelines_steps] PS 
             ON P.id = PS.pipelineid 
           JOIN [dbo].[t_list_activities] LS 
             ON LS.id = PS.activity_id 
    WHERE  p.enabled = 1 

    DECLARE @LSCount       INT, 
            @LinkedService VARCHAR(200) 
    DECLARE @CompleteJsoncode TABLE 
      ( 
         jsoncode VARCHAR(max) 
      ) 

    SET @LSCount =(SELECT Count(*) 
                   FROM   t_pipeline_linkedservices 
                   WHERE  pipelineid = 1) 

    /** CHG 001 start**/
	SELECT @parameterFolder = parametervalue 
	FROM dbo.t_master_parameters_list
	WHERE parametername='$parameterFolder'

	IF @debug = 1
	BEGIN
		PRINT '@activity_code -> ' + TRY_CONVERT(VARCHAR,@activity_code)
		PRINT '@LSCount -> ' + TRY_CONVERT(VARCHAR,@LSCount)
	END
	/** CHG 001 end**/

	WHILE @LSCount > 0 
	--WHILE @LSCount > 4
      BEGIN 
          SET @LinkedService= (SELECT linkedservice_name 
                               FROM   [t_linkedservices] 
                               WHERE  id = @LSCount) 

          INSERT INTO @CompleteJsoncode 
          SELECT '$' + @LinkedService + 'Definition = @"' 

			IF @debug = 1
			BEGIN
				SELECT '$' + @LinkedService + 'Definition = @"' 			
			END

          INSERT INTO @CompleteJsoncode 
          SELECT jsoncode 
          FROM   [dbo].[t_linkedservices] 
          WHERE  id = @LSCount 

          INSERT INTO @CompleteJsoncode 
          SELECT '"@' 

          INSERT INTO @CompleteJsoncode 
          SELECT '$' + @LinkedService 
                 --+ 'Definition | Out-File C:\ADF-MetaData\$' 
				 + 'Definition | Out-File '+ @parameterFolder+'$' 
                 + @LinkedService + '.json' 

		  
		  INSERT INTO @CompleteJsoncode 
          SELECT 
'New-AzDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "$' 
--+ @LinkedService + '" -File "C:\ADF-MetaData\$' 
+ @LinkedService + '" -File "'+ @parameterFolder+'$' 
+ @LinkedService + '.json"' 

    SET @LSCount=@LSCount - 1 
END 

    --select * from @CompleteJsoncode 
    SELECT  CASE WHEN parametername ='$parameterFolder' --chandra added CHG 001
			THEN parametername + ' = ' + '"' + parametervalue + '"' 
			ELSE parametername + ' = ' + parametervalue  END
    FROM   t_master_parameters_list 
    UNION ALL 
    SELECT parametername + ' = ' + parametervalue 
    FROM   [dbo].[t_linkedservice_parameters] 
    UNION ALL 
    SELECT * 
    FROM   @CompleteJsoncode 
    UNION ALL 
    SELECT '$pipelineDefinition = @"' 
    UNION ALL 
    SELECT '{' 
    UNION ALL 
    SELECT '"name": "$pipelinename",' 
    UNION ALL 
    SELECT '"properties": {' 
    UNION ALL 
    SELECT '"activities": [' 
    UNION ALL 
    SELECT @activity_code + ']' 
    --union all select         ']' 
    UNION ALL 
    SELECT '}' 
    UNION ALL 
    SELECT '}' 
    UNION ALL 
    SELECT '"@' 
    UNION ALL 
    --SELECT '$pipelineDefinition | Out-File C:\ADF-MetaData\$finaloutput.json' 
	SELECT '$pipelineDefinition | Out-File '+ @parameterFolder+'$finaloutput.json' 
    UNION ALL 
    SELECT 
--'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelinename -File "C:\ADF-MetaData\$finaloutput.json"' 
'New-AzDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelinename -File "'+@parameterFolder+'$finaloutput.json"' 

SET NOCOUNT OFF