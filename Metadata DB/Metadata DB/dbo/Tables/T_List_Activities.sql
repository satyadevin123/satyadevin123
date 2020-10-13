CREATE TABLE [dbo].[T_List_Activities] (
    [ActivityId]                   INT        IDENTITY(1,1)    NOT NULL,
    [ActivityName]         NVARCHAR (255) NULL,
    [ActivityStandardName] NVARCHAR (255) NULL,
    [Enabled]              INT            NULL,
    [JsonCode]                 VARCHAR (MAX) NULL,
    [linkedserverrequired] CHAR (3)       NULL,
    [datasetrequired]      CHAR (3)       NULL,
    SourceType        VARCHAR(200) NULL,
    PRIMARY KEY CLUSTERED ([ActivityId] ASC)
);

