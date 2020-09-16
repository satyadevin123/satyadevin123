CREATE TABLE [dbo].T_Pipeline_IntegrationRunTime (
    IntegrationRunTimeId                       INT           IDENTITY (1, 1) NOT NULL,
    IntegrationRunTimeName               VARCHAR(100)           NULL,
    IntegrationRunTimeType              VARCHAR(20)           NULL
    PRIMARY KEY CLUSTERED (IntegrationRunTimeId ASC)
);

