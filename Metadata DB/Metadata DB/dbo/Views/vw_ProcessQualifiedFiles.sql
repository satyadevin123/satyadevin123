CREATE  VIEW [dbo].[vw_ProcessQualifiedFiles]  
AS  
select stg.[File_Name],stg.[File_Time],stg.[Source],stg.[DataDomain] from   
(select [File_Name],[File_Time],[Status_Flag],[Source],[DataDomain] from [dbo].[Log_DataFeedRepository] where Status_Flag =2)stg  
left join  
(select[File_Name],[File_Time],[Status_Flag],[Source],[DataDomain] from [dbo].[Log_DataFeedRepository] where Status_Flag =4)cur  
on stg.[File_Name] = cur.[File_Name]  
WHERE stg.Status_Flag =2 and cur.Status_Flag IS NULL --AND stg.[DataDomain] = 'Material' 