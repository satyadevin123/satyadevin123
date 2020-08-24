CREATE TABLE [dbo].[T_Pipeline_LinkedService_Parameters_Bkup] (
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (500) NOT NULL,
    [LinkedServerId] INT           NOT NULL,
    [pipelineid]     INT           NULL
);

