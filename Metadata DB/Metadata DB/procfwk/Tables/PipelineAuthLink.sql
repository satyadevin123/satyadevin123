CREATE TABLE [procfwk].[PipelineAuthLink] (
    [AuthId]        INT IDENTITY (1, 1) NOT NULL,
    [PipelineId]    INT NOT NULL,
    [DataFactoryId] INT NOT NULL,
    [CredentialId]  INT NOT NULL,
    CONSTRAINT [PK_PipelineAuthLink] PRIMARY KEY CLUSTERED ([AuthId] ASC),
    CONSTRAINT [FK_PipelineAuthLink_DataFactorys] FOREIGN KEY ([DataFactoryId]) REFERENCES [procfwk].[DataFactorys] ([DataFactoryId]),
    CONSTRAINT [FK_PipelineAuthLink_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [procfwk].[Pipelines] ([PipelineId]),
    CONSTRAINT [FK_PipelineAuthLink_ServicePrincipals] FOREIGN KEY ([CredentialId]) REFERENCES [dbo].[ServicePrincipals] ([CredentialId])
);

