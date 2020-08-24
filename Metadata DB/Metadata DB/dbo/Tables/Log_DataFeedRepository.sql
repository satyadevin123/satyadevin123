CREATE TABLE [dbo].[Log_DataFeedRepository] (
    [Id]            INT            IDENTITY (1, 1) NOT NULL,
    [File_Name]     NVARCHAR (500) NULL,
    [Source]        NVARCHAR (500) NULL,
    [Status_Flag]   INT            NULL,
    [Start_Time]    DATETIME       NULL,
    [End_Time]      DATETIME       NULL,
    [Entity]        NVARCHAR (500) NULL,
    [File_Time]     DATETIME       NULL,
    [Loaded_By]     NVARCHAR (100) NULL,
    [Loaded_Time]   DATETIME       NULL,
    [Updated_By]    NVARCHAR (100) NULL,
    [Updated_Time]  DATETIME       NULL,
    [Zone_Filepath] NVARCHAR (500) NULL,
    [DataDomain]    NVARCHAR (100) NULL
);

