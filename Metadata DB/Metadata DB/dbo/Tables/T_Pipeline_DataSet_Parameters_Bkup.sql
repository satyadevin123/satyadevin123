CREATE TABLE [dbo].[T_Pipeline_DataSet_Parameters_Bkup] (
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (500) NOT NULL,
    [DatasetId]      INT           NOT NULL,
    [pipelineid]     INT           NULL
);

