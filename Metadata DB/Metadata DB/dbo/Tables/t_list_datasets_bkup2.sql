CREATE TABLE [dbo].[t_list_datasets_bkup2] (
    [id]                  INT            NOT NULL,
    [DataSet_name]        NVARCHAR (255) NULL,
    [LinkedService_id]    INT            NULL,
    [created_date]        DATE           NULL,
    [Jsoncode]            VARCHAR (8000) NULL,
    [DataSetStandardName] NVARCHAR (200) NULL
);

