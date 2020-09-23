CREATE TABLE [dbo].[T_Pipeline_Activities] (
    [PipelineActivityId]                       INT           IDENTITY (1, 1) NOT NULL,
    [PipelineId]               INT           NULL,
    [ActivityID]              INT           NULL,
    [DependsOn]                VARCHAR (10)  NULL,
    [ChildActivity]           VARCHAR(100)           NULL,
    [EmailNotificationEnabled] TINYINT       NULL,
    [Activityname]             VARCHAR (100) NULL,
    [DependencyCondition]        NVARCHAR(20)
    PRIMARY KEY CLUSTERED ([PipelineActivityId] ASC),
    FOREIGN KEY ([ActivityID]) REFERENCES [dbo].[T_List_Activities] ([ActivityId]),
    FOREIGN KEY ([PipelineId]) REFERENCES [dbo].[T_Pipelines] ([PipelineId])
);

