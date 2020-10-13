
CREATE PROCEDURE usp_InsertPipelineTablesToBeMoved
(@PipelineId INT, @TableName NVARCHAR(300), @SchemaName NVARCHAR(30),@IsIncremental VARCHAR(3),@RefreshBasedOn VARCHAR(255))
AS
BEGIN

IF EXISTS (SELECT 1 FROM dbo.[T_Pipeline_Tables_ToBeMoved] WHERE pipelineid = @PipelineId AND TableName = @TableName AND ISNULL(SchemaName,'')=ISNULL(@SchemaName,''))
BEGIN
	UPDATE [T_Pipeline_Tables_ToBeMoved]
	SET [IsIncremental] = CASE WHEN @IsIncremental = 'yes' THEN 1 ELSE 0 END,
	[IsActive] = 1,
	[IsWhereCondition] = CASE WHEN @IsIncremental = 'yes' THEN 1 ELSE 0 END,
	LastRefreshedBasedOn = @RefreshBasedOn
	WHERE pipelineid = @PipelineId AND TableName = @TableName AND ISNULL(SchemaName,'')=ISNULL(@SchemaName,'')

END
ELSE
BEGIN
	INSERT INTO dbo.[T_Pipeline_Tables_ToBeMoved]
	(pipelineid,[TableName],[SchemaName],[IsIncremental],[IsActive],[IsWhereCondition],[LastRefreshedBasedOn]) 
	SELECT @PipelineId,@TableName ,@SchemaName,CASE WHEN @IsIncremental = 'yes' THEN 1 ELSE 0 END,
	1,CASE WHEN @IsIncremental = 'yes' THEN 1 ELSE 0 END,@RefreshBasedOn
END




END