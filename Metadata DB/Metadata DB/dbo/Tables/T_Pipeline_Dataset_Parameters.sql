﻿CREATE TABLE [dbo].[T_Pipeline_Dataset_Parameters] (
    [PipelineDatasetParameterId]             INT           IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (500) NOT NULL,
    [PipelineDatasetId]      INT           NOT NULL Foreign Key References [dbo].[T_Pipeline_DataSets] ([PipelineDataSetId]),
    [pipelineid]     INT           NULL Foreign Key References [dbo].[T_Pipelines] ([PipelineId])
);

