CREATE TABLE [dbo].[T_LinkedService_Parameters] (
    [id]             INT           NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (500) NOT NULL,
    [LinkedServerId] INT           NOT NULL
);

