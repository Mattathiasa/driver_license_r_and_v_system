-- =====================================================
-- Driver License Registration & Verification System
-- Database Schema for SQL Server
-- =====================================================

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DriverLicenseDB')
BEGIN
    CREATE DATABASE DriverLicenseDB;
END
GO

USE DriverLicenseDB;
GO

-- =====================================================
-- DROP EXISTING TABLES (for clean setup)
-- =====================================================
IF OBJECT_ID('VerificationLogs', 'U') IS NOT NULL DROP TABLE VerificationLogs;
IF OBJECT_ID('Drivers', 'U') IS NOT NULL DROP TABLE Drivers;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
GO

-- =====================================================
-- CREATE TABLES
-- =====================================================

-- Users Table
-- Required Attributes: User ID, Username, Password hash, Created date, Status
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'active',
    CONSTRAINT CK_Users_Status CHECK (Status IN ('active', 'inactive'))
);
GO

-- Drivers Table
-- Required Attributes: Driver ID, License ID (unique), Full name,
-- License Type (Grade), Expiry date, QR raw data, OCR raw text, Created date, Registered by
CREATE TABLE Drivers (
    DriverID INT PRIMARY KEY IDENTITY(1,1),
    LicenseID NVARCHAR(50) NOT NULL UNIQUE,
    FullName NVARCHAR(100) NOT NULL,
    LicenseType NVARCHAR(10) NOT NULL, -- License Type (Grade)
    ExpiryDate DATE NOT NULL,
    QRRawData NVARCHAR(MAX) NULL,
    OCRRawText NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    RegisteredBy INT NOT NULL,
    CONSTRAINT FK_Drivers_RegisteredBy FOREIGN KEY (RegisteredBy) REFERENCES Users(UserID)
);
GO

-- Verification Logs Table
-- Required Attributes: Log ID, License ID, Verification status, Checked by, Checked date
CREATE TABLE VerificationLogs (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    LicenseID NVARCHAR(50) NOT NULL,
    VerificationStatus NVARCHAR(20) NOT NULL,
    CheckedBy INT NOT NULL,
    CheckedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_VerificationLogs_CheckedBy FOREIGN KEY (CheckedBy) REFERENCES Users(UserID)
);
GO

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Drivers table indexes
CREATE INDEX IX_Drivers_LicenseID ON Drivers(LicenseID);
CREATE INDEX IX_Drivers_Status ON Drivers(Status);
CREATE INDEX IX_Drivers_CreatedDate ON Drivers(CreatedDate);
CREATE INDEX IX_Drivers_RegisteredBy ON Drivers(RegisteredBy);

-- VerificationLogs table indexes
CREATE INDEX IX_VerificationLogs_LicenseID ON VerificationLogs(LicenseID);
CREATE INDEX IX_VerificationLogs_CheckedDate ON VerificationLogs(CheckedDate);
CREATE INDEX IX_VerificationLogs_CheckedBy ON VerificationLogs(CheckedBy);
CREATE INDEX IX_VerificationLogs_Status ON VerificationLogs(VerificationStatus);

-- Users table indexes
CREATE INDEX IX_Users_Username ON Users(Username);
CREATE INDEX IX_Users_Status ON Users(Status);
GO

-- =====================================================
-- CREATE TRIGGER FOR AUTO-UPDATE TIMESTAMPS
-- =====================================================

CREATE TRIGGER TR_Drivers_UpdateTimestamp
ON Drivers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Drivers
    SET UpdatedDate = GETDATE()
    FROM Drivers d
    INNER JOIN inserted i ON d.DriverID = i.DriverID;
END
GO

-- =====================================================
-- CREATE STORED PROCEDURES
-- =====================================================

-- Get Dashboard Statistics
CREATE PROCEDURE SP_GetDashboardStats
AS
BEGIN
    SELECT 
        COUNT(*) AS TotalDrivers,
        SUM(CASE WHEN Status = 'active' THEN 1 ELSE 0 END) AS ActiveDrivers,
        SUM(CASE WHEN Status = 'expired' THEN 1 ELSE 0 END) AS ExpiredDrivers,
        SUM(CASE WHEN Status = 'suspended' THEN 1 ELSE 0 END) AS SuspendedDrivers
    FROM Drivers;
    
    SELECT 
        COUNT(*) AS TotalVerifications,
        SUM(CASE WHEN VerificationStatus = 'real' THEN 1 ELSE 0 END) AS RealVerifications,
        SUM(CASE WHEN VerificationStatus = 'fake' THEN 1 ELSE 0 END) AS FakeVerifications,
        SUM(CASE WHEN VerificationStatus = 'expired' THEN 1 ELSE 0 END) AS ExpiredVerifications
    FROM VerificationLogs;
END
GO

-- Check if License ID exists
CREATE PROCEDURE SP_CheckLicenseExists
    @LicenseID NVARCHAR(50)
AS
BEGIN
    SELECT 
        DriverID,
        LicenseID,
        FullName,
        Status,
        ExpiryDate,
        CreatedDate
    FROM Drivers
    WHERE LicenseID = @LicenseID;
END
GO

-- Verify License
CREATE PROCEDURE SP_VerifyLicense
    @LicenseID NVARCHAR(50),
    @CheckedBy INT
AS
BEGIN
    DECLARE @VerificationStatus NVARCHAR(20);
    
    -- Check if license exists and get status
    SELECT 
        @VerificationStatus = Status
    FROM Drivers
    WHERE LicenseID = @LicenseID;
    
    -- Determine verification status
    IF @VerificationStatus IS NULL
    BEGIN
        SET @VerificationStatus = 'fake';
    END
    
    -- Log the verification
    INSERT INTO VerificationLogs (LicenseID, VerificationStatus, CheckedBy)
    VALUES (@LicenseID, @VerificationStatus, @CheckedBy);
    
    -- Return verification result
    SELECT 
        @VerificationStatus AS VerificationStatus,
        d.*
    FROM Drivers d
    WHERE LicenseID = @LicenseID;
END
GO

-- =====================================================
-- SEED DATA
-- =====================================================

-- IMPORTANT: The password hashes below are placeholders!
-- After running this script, you MUST generate real BCrypt hashes.
-- 
-- To fix passwords:
-- 1. Run: cd backend\GeneratePasswordHash && dotnet run
-- 2. Copy the generated hash
-- 3. Run: UPDATE Users SET PasswordHash = 'YOUR_HASH' WHERE Username = 'admin';
--
-- Or run the automated fix script: .\fix-login-issue.ps1
--
-- See FIX_LOGIN_INSTRUCTIONS.md for detailed steps.

-- Insert admin user
-- Password: Admin@123 (PLACEHOLDER - MUST BE UPDATED!)
INSERT INTO Users (Username, PasswordHash, FullName, Role, Status)
VALUES 
    ('admin', 'PLACEHOLDER_HASH_UPDATE_REQUIRED', 'System Administrator', 'admin', 'active'),
    ('officer1', 'PLACEHOLDER_HASH_UPDATE_REQUIRED', 'John Officer', 'officer', 'active'),
    ('user1', 'PLACEHOLDER_HASH_UPDATE_REQUIRED', 'Regular User', 'user', 'active');
GO

-- Insert sample drivers
INSERT INTO Drivers (LicenseID, FullName, ExpiryDate, LicenseType, Status, RegisteredBy, QRRawData, OCRRawText)
VALUES 
    ('DL123456', 'Abebe Kebede', '2026-05-15', 'B', 'active', 1, 
     'DL123456|Abebe Kebede|2026-05-15|B', 
     'DRIVER LICENSE\nDL123456\nAbebe Kebede\nEXP: 15/05/2026\nTYPE: B'),
    
    ('DL789012', 'Almaz Tesfaye', '2024-08-20', 'A', 'expired', 1,
     'DL789012|Almaz Tesfaye|2024-08-20|A',
     'DRIVER LICENSE\nDL789012\nAlmaz Tesfaye\nEXP: 20/08/2024\nTYPE: A'),
    
    ('DL345678', 'Dawit Assefa', '2027-03-10', 'C', 'active', 1,
     'DL345678|Dawit Assefa|2027-03-10|C',
     'DRIVER LICENSE\nDL345678\nDawit Assefa\nEXP: 10/03/2027\nTYPE: C'),
    
    ('DL901234', 'Sara Mohammed', '2025-11-25', 'B', 'active', 2,
     'DL901234|Sara Mohammed|2025-11-25|B',
     'DRIVER LICENSE\nDL901234\nSara Mohammed\nEXP: 25/11/2025\nTYPE: B'),
    
    ('DL567890', 'Yohannes Bekele', '2023-07-18', 'A', 'expired', 2,
     'DL567890|Yohannes Bekele|2023-07-18|A',
     'DRIVER LICENSE\nDL567890\nYohannes Bekele\nEXP: 18/07/2023\nTYPE: A');
GO

-- Insert sample verification logs
INSERT INTO VerificationLogs (LicenseID, VerificationStatus, DriverName, ExpiryDate, CheckedBy, Notes)
VALUES 
    ('DL123456', 'real', 'Abebe Kebede', '2026-05-15', 1, 'Routine verification'),
    ('DL789012', 'expired', 'Almaz Tesfaye', '2024-08-20', 1, 'License has expired'),
    ('DL999999', 'fake', NULL, NULL, 2, 'License not found in database'),
    ('DL345678', 'real', 'Dawit Assefa', '2027-03-10', 2, 'Verification successful'),
    ('DL123456', 'real', 'Abebe Kebede', '2026-05-15', 1, 'Second verification');
GO

-- =====================================================
-- CREATE VIEWS FOR REPORTING
-- =====================================================

-- View: Active Drivers
CREATE VIEW VW_ActiveDrivers AS
SELECT 
    d.DriverID,
    d.LicenseID,
    d.FullName,
    d.ExpiryDate,
    d.LicenseType,
    d.Status,
    u.FullName AS RegisteredByName,
    d.CreatedDate
FROM Drivers d
INNER JOIN Users u ON d.RegisteredBy = u.UserID
WHERE d.Status = 'active';
GO

-- View: Recent Verifications
CREATE VIEW VW_RecentVerifications AS
SELECT TOP 100
    v.LogID,
    v.LicenseID,
    v.VerificationStatus,
    v.DriverName,
    v.ExpiryDate,
    u.FullName AS CheckedByName,
    v.CheckedDate,
    v.Notes
FROM VerificationLogs v
INNER JOIN Users u ON v.CheckedBy = u.UserID
ORDER BY v.CheckedDate DESC;
GO

-- =====================================================
-- VERIFY DATABASE SETUP
-- =====================================================

PRINT '========================================';
PRINT 'Database setup completed successfully!';
PRINT '========================================';
PRINT '';
PRINT 'Tables created:';
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
PRINT '';
PRINT 'Sample data inserted:';
SELECT 'Users' AS TableName, COUNT(*) AS RecordCount FROM Users
UNION ALL
SELECT 'Drivers', COUNT(*) FROM Drivers
UNION ALL
SELECT 'VerificationLogs', COUNT(*) FROM VerificationLogs;
PRINT '';
PRINT '========================================';
PRINT 'Login Credentials:';
PRINT '  Username: admin';
PRINT '  Password: Admin@123';
PRINT '========================================';
GO
