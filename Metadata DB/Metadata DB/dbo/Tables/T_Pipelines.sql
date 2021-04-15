CREATE TABLE [dbo].[T_Pipelines] (
    [PipelineId]               INT    IDENTITY(1,1)        NOT NULL,
    [PipelineName]             VARCHAR (140) NULL,
    [Enabled]                  INT            NULL,
    [EmailNotificationEnabled] TINYINT        NULL,
    PRIMARY KEY CLUSTERED ([PipelineId] ASC)
);

