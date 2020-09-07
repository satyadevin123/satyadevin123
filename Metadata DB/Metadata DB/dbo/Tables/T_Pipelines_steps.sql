CREATE TABLE [dbo].[T_Pipeline_Activities] (
    [PipelineStepsId]                       INT           IDENTITY (1, 1) NOT NULL,
    [PipelineId]               INT           NULL,
    [ActivityID]              INT           NULL,
    [DependsOn]                VARCHAR (10)  NULL,
    [ChildActivity]           INT           NULL,
    [EmailNotificationEnabled] TINYINT       NULL,
    [Activityname]             VARCHAR (100) NULL,
    [DependencyCondition]        NVARCHAR(20)
    PRIMARY KEY CLUSTERED ([PipelineStepsId] ASC),
    FOREIGN KEY ([ActivityID]) REFERENCES [dbo].[T_List_Activities] ([ActivityId]),
    FOREIGN KEY ([PipelineId]) REFERENCES [dbo].[T_Pipelines] ([PipelineId])
);

