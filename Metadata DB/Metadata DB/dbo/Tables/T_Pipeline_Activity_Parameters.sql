CREATE TABLE [dbo].[T_Pipeline_Activity_Parameters] (
    [PipelineActivityParameterId]                 INT            IDENTITY (1, 1) NOT NULL,
    [ParameterName]      VARCHAR (100)  NOT NULL,
    [Parametervalue]     VARCHAR (8000) NULL,
    [PipelineActivityId] INT            NOT NULL,
    [PipelineId]         INT            NULL Foreign Key References DBO.[T_Pipelines] ([PipelineId])
);

