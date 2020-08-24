CREATE TABLE [dbo].[T_List_DataSets_bkup] (
    [id]               INT            NOT NULL,
    [DataSet_name]     NVARCHAR (255) NULL,
    [LinkedService_id] INT            NULL,
    [created_date]     DATE           NULL,
    [Jsoncode]         VARCHAR (8000) NULL
);

