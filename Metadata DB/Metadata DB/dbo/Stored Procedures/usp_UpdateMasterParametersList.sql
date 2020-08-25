
CREATE PROCEDURE usp_UpdateMasterParametersList
(@ParameterName nvarchar(300),@ParameterValue nvarchar(300))
AS
BEGIN
UPDATE T_Master_Parameters_List SET ParameterValue = @ParameterValue WHERE ParameterName = @ParameterName
END

