CREATE TABLE [dbo].[T_List_Activities] (
    [id]                   INT            NOT NULL,
    [ActivityName]         NVARCHAR (255) NULL,
    [ActivityStandardName] NVARCHAR (255) NULL,
    [Enabled]              INT            NULL,
    [code]                 VARCHAR (8000) NULL,
    [linkedserverrequired] CHAR (3)       NULL,
    [datasetrequired]      CHAR (3)       NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

