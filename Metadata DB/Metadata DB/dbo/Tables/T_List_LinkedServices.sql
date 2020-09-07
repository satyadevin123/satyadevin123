CREATE TABLE [dbo].[T_List_LinkedServices] (
    [LinkedServiceId]                 INT   IDENTITY(1,1)        ,
    [LinkedServiceName] VARCHAR (100)  NULL,
    [DataSourceId]      INT            NULL,
    [Jsoncode]           VARCHAR (4000) NULL,
    AuthenticationType   VARCHAR(200) ,
    KeyVaultReferenceReq  INT
);

