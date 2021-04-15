CREATE TABLE [dbo].[T_List_Activities] (
    [ActivityId]                   INT        IDENTITY(1,1)    NOT NULL,
    [ActivityName]         VARCHAR (55) NULL,
    [ActivityStandardName] VARCHAR (55) NULL,
    [Enabled]              INT            NULL,
    [JsonCode]             VARCHAR (MAX) NULL,
    [linkedserverrequired] CHAR (1)       NULL,
    [datasetrequired]      CHAR (1)       NULL,
    SourceType        VARCHAR(55) NULL,
    PRIMARY KEY CLUSTERED ([ActivityId] ASC)
);

