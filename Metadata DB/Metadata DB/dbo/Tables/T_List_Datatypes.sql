CREATE TABLE [dbo].[T_List_Datatypes] (
    [id]                  INT            NOT NULL,
    [DateSource_id]       INT            NULL,
    [DateDestination_id]  INT            NULL,
    [SourceDatatype]      NVARCHAR (255) NULL,
    [DestinationDatatype] NVARCHAR (255) NULL,
    [Source_Size]         NVARCHAR (255) NULL,
    [Destination_Size]    NVARCHAR (255) NULL,
    [Enabled]             INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    FOREIGN KEY ([DateDestination_id]) REFERENCES [dbo].[T_List_DataSources] ([id]),
    FOREIGN KEY ([DateSource_id]) REFERENCES [dbo].[T_List_DataSources] ([id])
);

