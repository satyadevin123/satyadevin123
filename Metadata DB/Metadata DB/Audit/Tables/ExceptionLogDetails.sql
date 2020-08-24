CREATE TABLE [Audit].[ExceptionLogDetails] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [PipelineID]        VARCHAR (250)  NULL,
    [PipelineName]      VARCHAR (250)  NULL,
    [Source]            VARCHAR (300)  NULL,
    [ActivityName]      VARCHAR (250)  NULL,
    [ActivityID]        VARCHAR (250)  NULL,
    [ErrorCode]         VARCHAR (10)   NULL,
    [ErrorDescription]  VARCHAR (5000) NULL,
    [FailureType]       VARCHAR (50)   NULL,
    [PipelineStartTime] DATETIME       NULL,
    [ActivityStartTime] DATETIME       NULL,
    [BatchID]           VARCHAR (100)  NULL,
    [ErrorLogTime]      DATETIME       NULL,
    [EntityName]        VARCHAR (200)  NULL
);

