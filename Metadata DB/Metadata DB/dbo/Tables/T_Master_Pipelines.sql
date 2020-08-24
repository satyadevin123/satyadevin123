CREATE TABLE [dbo].[T_Master_Pipelines] (
    [id]                 INT            NOT NULL,
    [MasterPipelineName] NVARCHAR (255) NULL,
    [Enabled]            INT            NULL,
    [Jsoncode]           VARCHAR (MAX)  NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

