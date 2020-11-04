/****** Object:  Table [dbo].[Conf_SAPtoSPARKDataTypeMapping]    Script Date: 11/4/2020 12:16:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Conf_SAPtoSPARKDataTypeMapping](
	[Mapping_ID] [int] IDENTITY(1,1) NOT NULL,
	[SAP_DataType] [varchar](50) NULL,
	[SPARK_DataType] [varchar](50) NULL,
	[ValidationFunction] [varchar](1000) NULL,
	[Source_Type] [varchar](50) NULL
) ON [PRIMARY]
GO


