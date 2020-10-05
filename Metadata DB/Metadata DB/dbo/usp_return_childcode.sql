
CREATE FUNCTION [dbo].[usp_return_childcode](@ParentActivityId INT, @ChildActivity VARCHAR(100))
RETURNS VARCHAR(MAX)
AS
BEGIN
declare @x varchar(max)
select @x = ' '


select 
@x = @x + REPLACE(TLa.[JsonCode],'$','$'+ISNULL(tpa.ActivityName,TLA.ActivityStandardName)+'_') +','

FROM T_Pipeline_Activities tpa
inner join T_List_Activities tla
on tpa.ActivityID = tla.ActivityId
where tpa.PipelineActivityId in (select value from string_split(@ChildActivity,',') )

if(@ChildActivity <> '0')
begin
set @x = substring(@x,1,len(@x)-1)
end
return @x

END
GO


