CREATE TABLE [dbo].[T_Pipeline_DataSets] (
    [PipelineDataSetId] INT            IDENTITY (1, 1) Primary Key,
    [PipelineId]        INT            NOT NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId]),
    [LinkedServericeId] INT            NOT NULL,
    [DataSetId]         INT            NOT NULL,
    [DataSetName]       NVARCHAR (140) NULL
);

