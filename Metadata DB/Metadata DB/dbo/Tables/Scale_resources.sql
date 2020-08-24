CREATE TABLE [dbo].[Scale_resources] (
    [Id]            INT NULL,
    [DataSource_Id] INT NULL,
    [Scaleup_DTU]   INT NULL,
    [ScaleDown_DTU] INT NULL,
    FOREIGN KEY ([DataSource_Id]) REFERENCES [dbo].[T_List_DataSources] ([id])
);

