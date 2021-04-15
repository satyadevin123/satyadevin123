CREATE TABLE [dbo].[T_Master_Pipelines] (
    [MasterPipelineId]                 INT       IDENTITY(1,1)     NOT NULL,
    [MasterPipelineName] NVARCHAR (140) NULL,
    [Enabled]            INT            NULL,
    [Jsoncode]           VARCHAR (MAX)  NOT NULL,
    PRIMARY KEY CLUSTERED ([MasterPipelineId] ASC)
);

