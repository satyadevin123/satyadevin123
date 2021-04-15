CREATE TABLE [dbo].[T_List_Dataset_Parameters] (
    [DatasetParameterId]             INT   IDENTITY(1,1)        NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [ParameterValue] VARCHAR (MAX) NOT NULL,
    [DatasetId]      INT           NOT NULL
);

