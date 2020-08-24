CREATE TABLE [dbo].[ServicePrincipals] (
    [CredentialId]    INT              IDENTITY (1, 1) NOT NULL,
    [PrincipalName]   NVARCHAR (256)   NULL,
    [PrincipalId]     UNIQUEIDENTIFIER NOT NULL,
    [PrincipalSecret] VARBINARY (256)  NOT NULL,
    CONSTRAINT [PK_ServicePrincipals] PRIMARY KEY CLUSTERED ([CredentialId] ASC)
);

