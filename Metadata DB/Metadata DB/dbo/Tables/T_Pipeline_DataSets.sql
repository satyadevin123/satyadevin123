CREATE TABLE [dbo].[T_Pipeline_DataSets] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [PipelineId]        INT            NOT NULL Foreign Key References [dbo].[T_Pipelines] ([Id]),
    [LinkedServericeId] INT            NOT NULL,
    [DataSetId]         INT            NOT NULL,
    [datasetname]       NVARCHAR (200) NULL
);

