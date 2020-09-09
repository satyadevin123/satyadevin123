CREATE TABLE [dbo].[T_Pipeline_LinkedServices] (
    [PipelineLinkedServicesID]              INT IDENTITY (1, 1) NOT NULL,
    [LinkedServiceId] INT NOT NULL,
    [LinkedServiceName] VARCHAR(200)
);

