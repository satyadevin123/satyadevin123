CREATE PROCEDURE [dbo].[usp_InsertPipelineLinkedServiceDetails]
(@LinkedServiceType VARCHAR(100),@AuthenticationType VARCHAR(200),@LinkedServiceDesc VARCHAR(200))
AS
BEGIN
DECLARE @AlreadyExists BIT
DECLARE @ListLinkedServiceId INT

SELECT @AlreadyExists = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
FROM [T_Pipeline_LinkedServices] WHERE LinkedServiceName = @LinkedServiceDesc

SELECT @ListLinkedServiceId = LinkedServiceId  FROM
[dbo].[T_List_LinkedServices] 
WHERE LinkedServiceName = @LinkedServiceType AND AuthenticationType = @AuthenticationType


IF (@AlreadyExists = 0)
BEGIN
INSERT INTO [dbo].[T_Pipeline_LinkedServices] ( LinkedServiceId,LinkedServiceName) 
SELECT [LinkedServiceId],@LinkedServiceDesc   FROM [dbo].[T_List_LinkedServices] 
WHERE [LinkedServiceName] = @LinkedServiceType AND AuthenticationType = @AuthenticationType
END
ELSE
BEGIN

UPDATE [dbo].[T_Pipeline_LinkedServices] 
SET LinkedServiceId = @ListLinkedServiceId
WHERE LinkedServiceName = @LinkedServiceDesc


END


END
GO