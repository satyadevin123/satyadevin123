CREATE TABLE [dbo].[T_Pipeline_Tables_ToBeMoved] (
    [PipelineSourceId]              INT            IDENTITY (1, 1) NOT NULL,
    [pipelineid]      INT            NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId]),
    [TableName]      NVARCHAR (200) NULL,
    [SchemaName]     NVARCHAR (200) NULL,
    [linkedserviceid] INT            NULL,
    [Query] [varchar](8000) NULL,
	[ColumnList] [varchar](8000) NULL,
	[IsIncremental] [bit]  NULL,
	[IsActive] [bit]  NULL,
	[LastRefreshedBasedOn] [varchar](200) NULL,
	[LastRefreshedDateTime] [datetime] NULL,
	[IsWhereCondition] [bit] NULL,
	[BuildQuery] [varchar](8000) NULL,
	[IsRestart] [bit] NULL,
	[FrequencyType] [varchar](50) NULL,
	[FrequencyHours] [int] NULL,
	[ProcessingCompletionDate] [datetime] NULL

);

