CREATE TABLE [dbo].[T_List_LinkedService_Parameters] (
    [id]              INT           NOT NULL,
    [ParameterName]   VARCHAR (100) NOT NULL,
    [ParameterValue]  VARCHAR (500) NOT NULL,
    [LinkedServiceId] INT           NOT NULL
);

