CREATE TABLE [procfwk].[CurrentExecution] (
    [LocalExecutionId]       UNIQUEIDENTIFIER NOT NULL,
    [StageId]                INT              NOT NULL,
    [PipelineId]             INT              NOT NULL,
    [CallingDataFactoryName] NVARCHAR (200)   NOT NULL,
    [ResourceGroupName]      NVARCHAR (200)   NOT NULL,
    [DataFactoryName]        NVARCHAR (200)   NOT NULL,
    [PipelineName]           NVARCHAR (200)   NOT NULL,
    [StartDateTime]          DATETIME         NULL,
    [PipelineStatus]         NVARCHAR (200)   NULL,
    [EndDateTime]            DATETIME         NULL,
    [IsBlocked]              BIT              DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CurrentExecution] PRIMARY KEY CLUSTERED ([LocalExecutionId] ASC, [StageId] ASC, [PipelineId] ASC)
);

