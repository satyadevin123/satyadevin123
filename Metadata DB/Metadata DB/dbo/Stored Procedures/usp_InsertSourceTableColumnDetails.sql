CREATE PROCEDURE [dbo].[usp_InsertSourceTableColumnDetails]
(
	@PipelineId INT
	,@SchemaName VARCHAR(30)
	,@TableName VARCHAR(128)
	,@ColumnName VARCHAR(128)
	,@KEY INT
	,@Type VARCHAR(30)
	,@Length VARCHAR(6)
	,@OutputLen VARCHAR(6),
	@Decimals VARCHAR(6)
)
AS 
BEGIN

	SELECT @Length = CASE WHEN @Length = 'NULL' THEN '' ELSE @Length END
	SELECT @OutputLen = CASE WHEN @OutputLen = 'NULL' THEN '' ELSE @OutputLen END
	SELECT @Decimals = CASE WHEN @Decimals = 'NULL' THEN '' ELSE @Decimals END

	INSERT INTO dbo.T_Pipeline_SourceColumnDetails
	(
			PipelineSourceId
			,ColumnName
			,[KEY]
			,[Type]
			,[Length]
			,OutputLen
			,Decimals
	)
	SELECT
			PipelineSourceId
			,@ColumnName
			,@KEY
			,@Type
			,STUFF('000000',6-LEN(@Length)+1,LEN(@Length),@Length)
			,STUFF('000000',6-LEN(@OutputLen)+1,LEN(@OutputLen),@OutputLen)
			,STUFF('000000',6-LEN(@Decimals)+1,LEN(@Decimals),@Decimals)
	FROM	[dbo].[T_Pipeline_Tables_ToBeMoved] tpt
	WHERE	[PipelineID] = @PipelineId 
			AND TableName = @TableName 
			AND SchemaName = @SchemaName

END
GO
