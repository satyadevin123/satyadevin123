CREATE TABLE [dbo].[T_List_Activities_config] (
    [id]         INT            NOT NULL,
    [ActivityId] INT            NULL,
    [Code]       NVARCHAR (255) NULL,
    [Enabled]    INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([ActivityId]) REFERENCES [dbo].[T_List_DataSources] ([id])
);

