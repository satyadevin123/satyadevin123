CREATE TABLE [dbo].[T_Pipelines_steps_Bkup] (
    [id]                       INT           NOT NULL,
    [PipelineId]               INT           NULL,
    [Activity_ID]              INT           NULL,
    [DependsOn]                VARCHAR (10)  NULL,
    [Child_Activity]           INT           NULL,
    [EmailNotificationEnabled] TINYINT       NULL,
    [Activityname]             VARCHAR (100) NULL
);

