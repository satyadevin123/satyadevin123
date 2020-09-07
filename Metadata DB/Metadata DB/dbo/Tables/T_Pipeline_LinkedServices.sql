CREATE TABLE [dbo].[T_Pipeline_LinkedServices] (
    [PipelineLinkedServicesID]              INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]      INT NOT NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId]),
    [LinkedServiceId] INT NOT NULL
);

