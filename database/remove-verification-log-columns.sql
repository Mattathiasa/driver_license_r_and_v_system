-- =====================================================
-- Remove DriverName, ExpiryDate, and Notes columns
-- from VerificationLogs table
-- =====================================================

USE DriverLicenseDB;
GO

-- Check if columns exist before dropping them
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'VerificationLogs' 
    AND COLUMN_NAME = 'DriverName'
)
BEGIN
    ALTER TABLE VerificationLogs
    DROP COLUMN DriverName;
    PRINT 'Column DriverName dropped successfully';
END
ELSE
BEGIN
    PRINT 'Column DriverName does not exist';
END
GO

IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'VerificationLogs' 
    AND COLUMN_NAME = 'ExpiryDate'
)
BEGIN
    ALTER TABLE VerificationLogs
    DROP COLUMN ExpiryDate;
    PRINT 'Column ExpiryDate dropped successfully';
END
ELSE
BEGIN
    PRINT 'Column ExpiryDate does not exist';
END
GO

IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'VerificationLogs' 
    AND COLUMN_NAME = 'Notes'
)
BEGIN
    ALTER TABLE VerificationLogs
    DROP COLUMN Notes;
    PRINT 'Column Notes dropped successfully';
END
ELSE
BEGIN
    PRINT 'Column Notes does not exist';
END
GO

-- Verify the changes
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'VerificationLogs'
ORDER BY ORDINAL_POSITION;
GO

PRINT 'VerificationLogs table columns updated successfully!';
GO
