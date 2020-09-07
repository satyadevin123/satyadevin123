CREATE TABLE [dbo].[T_List_Activities_config] (
    [ActivityConfigId]         INT            NOT NULL,
    [ActivityId] INT            NULL,
    [JsonCode]       NVARCHAR (255) NULL,
    [Enabled]    INT            NULL,
    PRIMARY KEY CLUSTERED ([ActivityConfigId] ASC),
    FOREIGN KEY ([ActivityId]) REFERENCES [dbo].[T_List_DataSources] ([DataSourceId])
);

