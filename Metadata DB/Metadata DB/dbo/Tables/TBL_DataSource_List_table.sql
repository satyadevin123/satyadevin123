CREATE TABLE [dbo].[TBL_DataSource_List_table] (
    [id]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [schemaname]     VARCHAR (50)  NULL,
    [tablename]      VARCHAR (50)  NOT NULL,
    [total_range]    BIGINT        NULL,
    [destination]    VARCHAR (150) NULL,
    [query]          VARCHAR (150) NULL,
    [partition_num]  INT           NULL,
    [filename]       VARCHAR (50)  NULL,
    [inserted_date]  DATETIME      NULL,
    [load_tables_id] INT           NULL
);

