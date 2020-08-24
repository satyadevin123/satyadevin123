CREATE TABLE [dbo].[TBL_DataSource_load_Tables] (
    [id]            INT           IDENTITY (1, 1) NOT NULL,
    [TblName]       VARCHAR (80)  NULL,
    [total]         BIGINT        NULL,
    [range_type]    SMALLINT      NULL,
    [DateCreated]   DATETIME      NULL,
    [schemaname]    VARCHAR (50)  NULL,
    [destination]   VARCHAR (150) NULL,
    [ColumnName]    VARCHAR (50)  NULL,
    [sel_max_part]  VARCHAR (200) NULL,
    [max_partition] INT           NULL
);

