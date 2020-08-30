CREATE TABLE [dbo].[T_List_Activity_Parameters] (
    [id]             INT   IDENTITY(1,1)        NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [Parametervalue] VARCHAR (8000) NOT NULL,
    [ActivityId]     INT           NOT NULL
);

