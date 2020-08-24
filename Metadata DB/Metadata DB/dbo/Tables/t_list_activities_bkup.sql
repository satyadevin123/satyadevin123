CREATE TABLE [dbo].[t_list_activities_bkup] (
    [id]                   INT            NOT NULL,
    [ActivityName]         NVARCHAR (255) NULL,
    [ActivityStandardName] NVARCHAR (255) NULL,
    [Enabled]              INT            NULL,
    [code]                 VARCHAR (8000) NULL,
    [linkedserverrequired] CHAR (3)       NULL,
    [datasetrequired]      CHAR (3)       NULL
);

