CREATE TABLE [dbo].[T_Columns] (
    [id]            INT            NOT NULL,
    [DateSource_id] INT            NULL,
    [Table_id]      INT            NULL,
    [Columnname]    NVARCHAR (255) NULL,
    [Datatype]      NVARCHAR (255) NULL,
    [Size]          NVARCHAR (255) NULL,
    [Enabled]       INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([DateSource_id]) REFERENCES [dbo].[T_List_DataSources] ([id]),
    FOREIGN KEY ([Table_id]) REFERENCES [dbo].[T_Tables] ([id])
);

