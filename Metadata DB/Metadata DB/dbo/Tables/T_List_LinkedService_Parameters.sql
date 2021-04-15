CREATE TABLE [dbo].[T_List_LinkedService_Parameters] (
    [id]              INT      IDENTITY(1,1)     NOT NULL,
    [ParameterName]   VARCHAR (200) NOT NULL,
    [ParameterValue]  VARCHAR (MAX) NOT NULL,
    [LinkedServiceId] INT           NOT NULL,
    [ReferFromKeyVault] INT  NULL,
    [KeyVaultReferenceDescription] VARCHAR(200) 
);

