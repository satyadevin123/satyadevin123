CREATE procedure [dbo].[usp_Insert_Pipeline_LinkedServiceParameters]
(@LinkedServiceId INT,@PipelineId INT)
as
begin
insert into [dbo].[T_Pipeline_LinkedService_Parameters]

select  REPLACE(tllp.ParameterName,'$','$'+CAST(tpl.id AS nvarchar)+'_') AS parameterName
,  tllp.parametervalue as ParameterValue, TPl.Id, TP.id
FROM [dbo].[T_Pipelines] TP
JOIN dbo.T_Pipeline_LinkedServices tpl
ON tp.id = tpl.PipelineId
INNER JOIN dbo.T_List_LinkedServices tll
ON tpl.LinkedServiceId = tll.Id
INNER JOIN dbo.T_List_LinkedService_Parameters tllp
ON tllp.LinkedServiceId = tll.Id
WHERE TP.Id = @PipelineId AND TPL.Id = @LinkedServiceId
END