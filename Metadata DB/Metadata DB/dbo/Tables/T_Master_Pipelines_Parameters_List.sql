CREATE TABLE [dbo].[T_Master_Pipelines_Parameters_List] (
    [MasterParameterPipelineId]               INT       IDENTITY(1,1)    NOT NULL,
    [ParameterName]    VARCHAR (255) NOT NULL,
    [ParameterValue]   VARCHAR (MAX) NOT NULL,
    [MasterPipelineId] INT           NOT NULL
);

