CREATE TABLE [dbo].[TBL_Start_Load] (
    [id]            INT           IDENTITY (1, 1) NOT NULL,
    [schemaname]    VARCHAR (50)  NULL,
    [destination]   VARCHAR (100) NULL,
    [date_inserted] DATETIME      NULL,
    [FreshDataLoad] CHAR (1)      NULL
);

