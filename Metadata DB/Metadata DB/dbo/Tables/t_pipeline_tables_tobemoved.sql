CREATE TABLE [dbo].[T_Pipeline_Tables_ToBeMoved] (
    [PipelineSourceId]              INT            IDENTITY (1, 1) NOT NULL,
    [pipelineid]      INT            NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId]),
    [TableName]      NVARCHAR (200) NULL,
    [SchemaName]     NVARCHAR (200) NULL,
    [linkedserviceid] INT            NULL
);

