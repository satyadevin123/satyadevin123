CREATE TABLE [dbo].[T_Pipelines] (
    [id]                       INT            NOT NULL,
    [PipelineName]             NVARCHAR (255) NULL,
    [Enabled]                  INT            NULL,
    [EmailNotificationEnabled] TINYINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

