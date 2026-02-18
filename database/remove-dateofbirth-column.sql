-- Migration Script: Remove DateOfBirth Column from Drivers Table
-- This script removes the DateOfBirth column as it's no longer needed
-- Only the ExpiryDate is required for license validation

USE DriverLicenseDB;
GO

-- Check if the column exists before attempting to drop it
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Drivers' 
    AND COLUMN_NAME = 'DateOfBirth'
)
BEGIN
    PRINT 'Removing DateOfBirth column from Drivers table...';
    
    ALTER TABLE Drivers
    DROP COLUMN DateOfBirth;
    
    PRINT 'DateOfBirth column removed successfully.';
END
ELSE
BEGIN
    PRINT 'DateOfBirth column does not exist. No action needed.';
END
GO

-- Verify the change
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Drivers'
ORDER BY ORDINAL_POSITION;
GO

PRINT 'Migration completed successfully!';
