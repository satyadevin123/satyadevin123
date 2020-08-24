CREATE TABLE [dbo].[TBL_LookUp_Range] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [range_type] TINYINT      NULL,
    [range_desc] VARCHAR (50) NULL,
    [range_min]  BIGINT       NULL,
    [range_max]  BIGINT       NULL
);

