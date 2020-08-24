CREATE TABLE [dbo].[T_Pipelines_steps] (
    [id]                       INT           IDENTITY (1, 1) NOT NULL,
    [PipelineId]               INT           NULL,
    [Activity_ID]              INT           NULL,
    [DependsOn]                VARCHAR (10)  NULL,
    [Child_Activity]           INT           NULL,
    [EmailNotificationEnabled] TINYINT       NULL,
    [Activityname]             VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([Activity_ID]) REFERENCES [dbo].[T_List_Activities] ([id]),
    FOREIGN KEY ([PipelineId]) REFERENCES [dbo].[T_Pipelines] ([id])
);

