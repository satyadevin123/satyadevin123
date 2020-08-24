CREATE TABLE [dbo].[T_List_Queries] (
    [id]            INT            NOT NULL,
    [DateSource_id] INT            NULL,
    [Query]         NVARCHAR (255) NULL,
    [Enabled]       INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([DateSource_id]) REFERENCES [dbo].[T_List_DataSources] ([id])
);

