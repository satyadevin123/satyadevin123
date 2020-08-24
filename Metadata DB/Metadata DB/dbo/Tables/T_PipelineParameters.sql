CREATE TABLE [dbo].[T_PipelineParameters] (
    [ParameterId]    INT           IDENTITY (1, 1) NOT NULL,
    [PipelineId]     INT           NOT NULL,
    [ParameterName]  VARCHAR (128) NOT NULL,
    [ParameterValue] VARCHAR (128) NULL,
    CONSTRAINT [PK_T_PipelineParameters] PRIMARY KEY CLUSTERED ([ParameterId] ASC),
    CONSTRAINT [FK_T_PipelineParameters_T_Pipelines] FOREIGN KEY ([PipelineId]) REFERENCES [dbo].[T_Pipelines] ([id])
);

