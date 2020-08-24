CREATE TABLE [dbo].[T_Master_Pipelines_Parameters_List] (
    [Id]               INT           NOT NULL,
    [ParameterName]    VARCHAR (255) NOT NULL,
    [ParameterValue]   VARCHAR (MAX) NOT NULL,
    [MasterPipelineId] INT           NOT NULL
);

