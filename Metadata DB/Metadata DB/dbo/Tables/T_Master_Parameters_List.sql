CREATE TABLE [dbo].[T_Master_Parameters_List] (
    [MasterParameterId]             INT            IDENTITY (1, 1) NOT NULL,
    [ParameterName]  VARCHAR (1000) NOT NULL,
    [ParameterValue] VARCHAR (MAX) NOT NULL
);

