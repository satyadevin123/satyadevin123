CREATE TABLE [dbo].[T_List_Activity_Parameters] (
    [ActivityParameterId]             INT   IDENTITY(1,1)        NOT NULL,
    [ParameterName]  VARCHAR (100) NOT NULL,
    [Parametervalue] VARCHAR (MAX) NOT NULL,
    [ActivityId]     INT           NOT NULL Foreign Key References [dbo].[T_List_Activities] ([ActivityId])
);

