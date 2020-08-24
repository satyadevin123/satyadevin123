CREATE TABLE [dbo].[TBL_Teradata_Table_Indices] (
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [TblName]        VARCHAR (80)  NULL,
    [SchemaName]     VARCHAR (50)  NULL,
    [ColumnName]     VARCHAR (150) NULL,
    [IndexType]      VARCHAR (50)  NULL,
    [IndexNumber]    TINYINT       NULL,
    [IndexName]      VARCHAR (150) NULL,
    [ColumnPosition] TINYINT       NULL,
    [uniqueness]     VARCHAR (15)  NULL
);

