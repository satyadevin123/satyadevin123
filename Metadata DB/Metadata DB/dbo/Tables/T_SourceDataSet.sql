CREATE TABLE [dbo].[T_SourceDataSet] (
    [id]                 INT            IDENTITY (1, 1) NOT NULL,
    [DataSource_name]    NVARCHAR (255) NULL,
    [connection_details] NVARCHAR (255) NULL,
    [DataSource_id]      INT            NULL,
    [created_date]       DATE           NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

