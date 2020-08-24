CREATE TABLE [dbo].[T_DataSource_Queries] (
    [id]           INT            NOT NULL,
    [QueryName]    VARCHAR (255)  NULL,
    [Query]        VARCHAR (8000) NOT NULL,
    [DatasourceId] TINYINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

