CREATE TABLE [dbo].[T_Pipeline_LinkedServices] (
    [Id]              INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]      INT NOT NULL,
    [LinkedServiceId] INT NOT NULL
);

