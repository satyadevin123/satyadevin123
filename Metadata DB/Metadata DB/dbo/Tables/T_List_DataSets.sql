CREATE TABLE [dbo].[T_List_DataSets] (
    [DatasetId]                           INT       IDENTITY(1,1)     NOT NULL,
    [DataSetName]                 NVARCHAR (255) NULL,
    [LinkedServiceId]             INT            NULL,
    [CreatedDate]                 DATE           NULL,
    [Jsoncode]                     VARCHAR (8000) NULL,
    [DataSetStandardName]          NVARCHAR (200) NULL,
    [AdditionalConfigurationType]  NVARCHAR (100) NULL,
    [AdditionalConfigurationValue] NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([DatasetId] ASC)
);

