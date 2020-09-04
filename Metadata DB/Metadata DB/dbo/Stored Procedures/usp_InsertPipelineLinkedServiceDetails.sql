CREATE PROCEDURE [dbo].[usp_InsertPipelineLinkedServiceDetails]
(@PipelineId INT,@LinkedServiceName VARCHAR(100),@AuthenticationType VARCHAR(200))
AS
BEGIN
INSERT INTO [dbo].[T_Pipeline_LinkedServices] (PipelineId, LinkedServiceId) 
SELECT @PipelineId,Id   FROM [dbo].[T_List_LinkedServices] 
WHERE LinkedService_Name = @LinkedServiceName AND AuthenticationType = @AuthenticationType

END
GO