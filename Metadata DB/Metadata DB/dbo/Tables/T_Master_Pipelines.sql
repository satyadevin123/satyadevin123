CREATE TABLE [dbo].[T_Master_Pipelines] (
    [id]                 INT       IDENTITY(1,1)     NOT NULL,
    [MasterPipelineName] NVARCHAR (255) NULL,
    [Enabled]            INT            NULL,
    [Jsoncode]           VARCHAR (MAX)  NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

