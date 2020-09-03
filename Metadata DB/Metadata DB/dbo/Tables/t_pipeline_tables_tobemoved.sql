CREATE TABLE [dbo].[t_pipeline_tables_tobemoved] (
    [id]              INT            IDENTITY (1, 1) NOT NULL,
    [pipelineid]      INT            NULL Foreign Key References [dbo].[T_Pipelines] ([Id]),
    [Table_Name]      NVARCHAR (200) NULL,
    [Schema_Name]     NVARCHAR (200) NULL,
    [linkedserviceid] INT            NULL
);

