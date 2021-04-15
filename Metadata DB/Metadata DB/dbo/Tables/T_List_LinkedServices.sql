CREATE TABLE [dbo].[T_List_LinkedServices] (
    [LinkedServiceId]                 INT   IDENTITY(1,1)        ,
    [LinkedServiceName] VARCHAR (140)  NULL,
    [DataSourceId]      INT            NULL,
    [Jsoncode]           VARCHAR (MAX) NULL,
    AuthenticationType   VARCHAR(200) ,
    KeyVaultReferenceReq  INT
);

