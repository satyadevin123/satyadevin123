CREATE PROCEDURE [dbo].[usp_InsertPipelineLinkedServiceDetails]
(@LinkedServiceType VARCHAR(100),@AuthenticationType VARCHAR(200),@LinkedServiceDesc VARCHAR(200))
AS
BEGIN
INSERT INTO [dbo].[T_Pipeline_LinkedServices] ( LinkedServiceId,LinkedServiceName) 
SELECT [LinkedServiceId],@LinkedServiceDesc   FROM [dbo].[T_List_LinkedServices] 
WHERE [LinkedServiceName] = @LinkedServiceType AND AuthenticationType = @AuthenticationType

END
GO