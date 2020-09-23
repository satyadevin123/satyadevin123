﻿CREATE TABLE [Audit].[pipeline_Copy_Activity_log](
	[PipelineCopyActivityLogId] BIGINT IDENTITY(1,1),
	[RunId] [nvarchar](500) NULL,
	[rowsCopied] [nvarchar](500) NULL,
	[RowsRead] [int] NULL,
	[copyDuration_in_secs] [nvarchar](500) NULL,
	[Execution_Status] [nvarchar](500) NULL,
	[CopyActivity_Start_Time] [datetime] NULL,
	[CopyActivity_End_Time] [datetime] NULL,
	[EntityName] [varchar](100) NULL
) ON [PRIMARY]
