CREATE TABLE [dbo].[TBL_Teradata_to_SQL_Datatype] (
    [TeradataColumnType]      VARCHAR (100) NULL,
    [TeradataColumnLength]    INT           NULL,
    [TeradataColumnFormat]    VARCHAR (100) NULL,
    [SQLServerDataType]       VARCHAR (100) NULL,
    [UseTeradataColumnLength] CHAR (1)      NULL,
    [ParquetDataType]         VARCHAR (100) NULL
);

