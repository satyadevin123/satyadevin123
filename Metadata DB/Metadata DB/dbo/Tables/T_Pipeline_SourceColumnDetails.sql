CREATE TABLE [dbo].[T_Pipeline_SourceColumnDetails](
	[PipelineSourceColumnDetailsId] [bigint] IDENTITY(1,1) NOT NULL,
	[PipelineSourceId] [bigint] NULL,
	[ColumnName] [varchar](255) NULL,
	[KEY] [int] NULL,
	[Type] [varchar](30) NULL,
	[Length] [varchar](6) NULL,
	[OutputLen] [varchar](6) NULL,
	[Decimals] [varchar](6) NULL
) ON [PRIMARY]
