CREATE TABLE [dbo].[T_Pipeline_LinkedServices] (
    [Id]              INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]      INT NOT NULL Foreign Key References [dbo].[T_Pipelines] ([Id]),
    [LinkedServiceId] INT NOT NULL
);

