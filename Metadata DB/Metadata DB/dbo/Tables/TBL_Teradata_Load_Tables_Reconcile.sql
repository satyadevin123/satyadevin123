CREATE TABLE [dbo].[TBL_Teradata_Load_Tables_Reconcile] (
    [id]                              INT          IDENTITY (1, 1) NOT NULL,
    [TblName]                         VARCHAR (80) NULL,
    [SchemaName]                      VARCHAR (50) NULL,
    [NoOfRowsInTeradata]              BIGINT       NULL,
    [NoOfRowsInParquetFiles]          BIGINT       NULL,
    [NoOfRowsLoadedInDW]              BIGINT       NULL,
    [NoOfRowsMatchBWTeradata_Parquet] CHAR (1)     NULL,
    [NoOfRowsMatchBWTeradata_DW]      CHAR (1)     NULL
);

