CREATE TABLE [dbo].[T_ChildPipelines_Activities] (
    [id]                       INT          NOT NULL,
    [PipelineActivityId]       INT          NULL,
    [Activity_ID]              INT          NULL,
    [DependsOn]                VARCHAR (10) NULL,
    [Child_Activity]           INT          NULL,
    [EmailNotificationEnabled] TINYINT      NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

