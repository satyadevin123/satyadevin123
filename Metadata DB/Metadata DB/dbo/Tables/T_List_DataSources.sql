CREATE TABLE [dbo].[T_List_DataSources] (
    [DataSourceId]                    INT            IDENTITY (1, 1) NOT NULL,
    [DataSourceName]       NVARCHAR (255) NULL,
    [CreatedDate]          DATE           NULL,
    [SourceType]           VARCHAR (100)  NULL,
    [SourceMetadataQuery] VARCHAR (MAX)  NULL,
    PRIMARY KEY CLUSTERED ([DataSourceId] ASC)
);

