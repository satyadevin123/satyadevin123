CREATE TABLE [Audit].[PipelineStatusDetails] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [PipelineId]              VARCHAR (100) NULL,
    [PipelineName]            VARCHAR (100) NULL,
    [PipelineStatus]          VARCHAR (50)  NULL,
    [ExecutionStartTime]      DATETIME      NULL,
    [ExecutionEndTime]        DATETIME      NULL,
    [DistrictName]            VARCHAR (200) NULL,
    [CopyToADLSTimeInSeconds] INT           NULL,
    [CopiedRowCount]          INT           NULL,
    [TotalRecords]            INT           NULL,
    [InsertedRecords]         INT           NULL,
    [UpdatedRecords]          INT           NULL,
    [NoImpactRecords]         INT           NULL,
    [EntityName]              VARCHAR (200) NULL
);

