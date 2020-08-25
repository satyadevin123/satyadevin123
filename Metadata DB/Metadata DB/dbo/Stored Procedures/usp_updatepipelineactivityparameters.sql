
CREATE PROCEDURE usp_updatepipelineactivityparameters
(@ParameterName NVARCHAR(200),@ParameterValue NVARCHAR(200),@PipelineId INT)
As
begin
UPDATE dbo.T_Pipeline_Activity_Parameters SET ParameterValue = @ParameterValue WHERE ParameterName = @ParameterName 
and pipelineid = @PipelineId 
end
