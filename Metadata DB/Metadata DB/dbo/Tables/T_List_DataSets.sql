CREATE TABLE [dbo].[T_List_DataSets] (
    [DatasetId]                           INT       IDENTITY(1,1)     NOT NULL,
    [DataSetName]                 NVARCHAR (140) NULL,
    [LinkedServiceId]             INT            NULL,
    [CreatedDate]                 DATE           NULL,
    [Jsoncode]                     VARCHAR (MAX) NULL,
    [DataSetStandardName]          NVARCHAR (140) NULL,
    [AdditionalConfigurationType]  NVARCHAR (100) NULL,
    [AdditionalConfigurationValue] NVARCHAR (140) NULL,
    PRIMARY KEY CLUSTERED ([DatasetId] ASC)
);

