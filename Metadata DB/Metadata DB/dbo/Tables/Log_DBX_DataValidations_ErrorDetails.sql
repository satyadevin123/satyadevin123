CREATE TABLE [dbo].[Log_DBX_DataValidations_ErrorDetails] (
    [Error_Id]       INT             IDENTITY (1, 1) NOT NULL,
    [Error_Desc]     NVARCHAR (2000) NULL,
    [Error_File]     NVARCHAR (100)  NULL,
    [Error_Time]     NVARCHAR (50)   NULL,
    [Validationtype] NVARCHAR (50)   NULL,
    [DataDomain]     NVARCHAR (50)   NULL
);

