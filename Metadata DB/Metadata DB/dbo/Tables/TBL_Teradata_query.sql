CREATE TABLE [dbo].[TBL_Teradata_query] (
    [id]              INT           IDENTITY (1, 1) NOT NULL,
    [date_created]    DATETIME      NULL,
    [query_condition] VARCHAR (200) NULL,
    [TblName]         VARCHAR (60)  NULL,
    [ColumnName]      VARCHAR (50)  NULL,
    [partition]       INT           NULL,
    [schemaname]      VARCHAR (80)  NULL,
    [destination]     VARCHAR (150) NULL,
    [FileName]        VARCHAR (60)  NULL
);

