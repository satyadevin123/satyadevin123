CREATE TABLE [dbo].[TBL_DataSource_load_Tables_Columns_Scripts] (
    [SchemaName]         VARCHAR (50)  NOT NULL,
    [TableName]          VARCHAR (80)  NOT NULL,
    [ColumnName]         VARCHAR (150) NOT NULL,
    [ColumnType]         VARCHAR (50)  NOT NULL,
    [ColumnLength]       INT           NULL,
    [ColumnFormat]       VARCHAR (100) NULL,
    [Nullable]           CHAR (1)      NULL,
    [ColumnID]           INT           NULL,
    [CharType]           CHAR (1)      NULL,
    [PartitioningColumn] CHAR (1)      NULL,
    [ParquetDataType]    VARCHAR (100) NULL,
    [SQLDataType]        VARCHAR (100) NULL
);

