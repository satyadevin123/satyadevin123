/****** Object:  Table [dbo].[Log_DataFeedRepository]    Script Date: 11/4/2020 12:18:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Log_DataFeedRepository](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[File_Name] [nvarchar](500) NULL,
	[Source] [nvarchar](500) NULL,
	[Status_Flag] [int] NULL,
	[Start_Time] [datetime] NULL,
	[End_Time] [datetime] NULL,
	[Entity] [nvarchar](500) NULL,
	[File_Time] [datetime] NULL,
	[Loaded_By] [nvarchar](100) NULL,
	[Loaded_Time] [datetime] NULL,
	[Updated_By] [nvarchar](100) NULL,
	[Updated_Time] [datetime] NULL,
	[Zone_Filepath] [nvarchar](500) NULL,
	[DataDomain] [nvarchar](100) NULL
) ON [PRIMARY]
GO


