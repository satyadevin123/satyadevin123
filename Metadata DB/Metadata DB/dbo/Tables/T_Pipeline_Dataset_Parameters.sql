CREATE TABLE [dbo].[T_Pipeline_Dataset_Parameters] (
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (500) NOT NULL,
    [DatasetId]      INT           NOT NULL,
    [pipelineid]     INT           NULL
);

