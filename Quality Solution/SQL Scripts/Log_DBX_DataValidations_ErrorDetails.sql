/****** Object:  Table [dbo].[Log_DBX_DataValidations_ErrorDetails]    Script Date: 11/4/2020 12:19:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Log_DBX_DataValidations_ErrorDetails](
	[Error_Id] [int] IDENTITY(1,1) NOT NULL,
	[Error_Desc] [nvarchar](2000) NULL,
	[Error_File] [nvarchar](100) NULL,
	[Error_Time] [nvarchar](50) NULL,
	[Validationtype] [nvarchar](50) NULL,
	[DataDomain] [nvarchar](50) NULL
) ON [PRIMARY]
GO


