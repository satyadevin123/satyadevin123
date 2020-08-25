
CREATE PROCEDURE usp_InsertPipelineLinkedServiceDetails
(@PipelineId INT,@LinkedServiceName NVARCHAR(100))
AS
BEGIN
INSERT INTO [dbo].[T_Pipeline_LinkedServices] (PipelineId, LinkedServiceId) 
SELECT @PipelineId,Id   FROM [dbo].[T_List_LinkedServices] 
WHERE LinkedService_Name = @LinkedServiceName

END
