CREATE TABLE [dbo].[T_Pipeline_LinkedService_Parameters] (
    [PipelineLinkedServicesParameterID]             INT           IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (500) NOT NULL,
    [LinkedServerId] INT           NOT NULL,
    [pipelineid]     INT           NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId])
);

