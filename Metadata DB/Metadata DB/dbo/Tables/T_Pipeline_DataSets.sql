CREATE TABLE [dbo].[T_Pipeline_DataSets] (
    [PipelineDatasetId] INT            IDENTITY (1, 1) Primary Key,
    [PipelineId]        INT            NOT NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId]),
    [LinkedServericeId] INT            NOT NULL,
    [DataSetId]         INT            NOT NULL,
    [datasetname]       NVARCHAR (200) NULL
);

