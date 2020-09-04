CREATE TABLE [dbo].[T_List_LinkedServices] (
    [Id]                 INT   IDENTITY(1,1)        ,
    [LinkedService_Name] VARCHAR (100)  NULL,
    [DataSource_Id]      INT            NULL,
    [Jsoncode]           VARCHAR (4000) NULL,
    AuthenticationType   VARCHAR(200) ,
    KeyVaultReferenceReq  INT
);

