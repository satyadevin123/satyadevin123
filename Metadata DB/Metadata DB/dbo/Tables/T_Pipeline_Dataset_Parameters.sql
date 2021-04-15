CREATE TABLE [dbo].[T_Pipeline_DataSet_Parameters] (
    [PipelineDatasetParameterId]             INT           IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (200) NOT NULL,
    [ParameterValue] VARCHAR (MAX) NOT NULL,
    [PipelineDataSetId]      INT           NOT NULL Foreign Key References [dbo].[T_Pipeline_DataSets] ([PipelineDataSetId]),
    [PipelineId]     INT           NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId])
);

