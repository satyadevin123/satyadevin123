CREATE TABLE [dbo].[T_List_DataSources] (
    [id]                    INT            IDENTITY (1, 1) NOT NULL,
    [DataSource_name]       NVARCHAR (255) NULL,
    [created_date]          DATE           NULL,
    [source_Type]           VARCHAR (100)  NULL,
    [source_metadata_query] VARCHAR (MAX)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

