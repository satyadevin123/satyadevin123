CREATE TABLE [dbo].[T_List_DataSets] (
    [id]                           INT            NOT NULL,
    [DataSet_name]                 NVARCHAR (255) NULL,
    [LinkedService_id]             INT            NULL,
    [created_date]                 DATE           NULL,
    [Jsoncode]                     VARCHAR (8000) NULL,
    [DataSetStandardName]          NVARCHAR (200) NULL,
    [AdditionalConfigurationType]  NVARCHAR (100) NULL,
    [AdditionalConfigurationValue] NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

