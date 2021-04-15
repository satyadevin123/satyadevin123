CREATE TABLE [dbo].[T_Pipeline_Tables_ToBeMoved] (
    [PipelineSourceId]              INT            IDENTITY (1, 1) NOT NULL,
    [PipelineId]      INT            NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineID]),
    [TableName]      NVARCHAR (128) NULL,
    [SchemaName]     NVARCHAR (30) NULL,
    [linkedserviceid] INT            NULL,
    [Query] [varchar](MAX) NULL,
	[ColumnList] [varchar](MAX) NULL,
	[IsIncremental] [bit]  NULL,
	[IsActive] [bit]  NULL,
	[LastRefreshedBasedOn] [varchar](128) NULL,
	[LastRefreshedDateTime] [datetime] NULL,
	[IsWhereCondition] [bit] NULL,
	[BuildQuery] [varchar](MAx) NULL,
	[CntQuery] [varchar](max) NULL,
	[IsRestart] [bit] NULL,
	[FrequencyType] [varchar](50) NULL,
	[FrequencyHours] [int] NULL,
	[ProcessingCompletionDate] [datetime] NULL

);

