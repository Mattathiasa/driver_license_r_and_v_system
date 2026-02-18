-- =====================================================
-- Table Definitions Script
-- Driver License Registration & Verification System
-- =====================================================

USE DriverLicenseDB;
GO

-- =====================================================
-- DROP EXISTING TABLES (for clean setup)
-- =====================================================
PRINT 'Dropping existing tables if they exist...';

IF OBJECT_ID('VerificationLogs', 'U') IS NOT NULL 
BEGIN
    DROP TABLE VerificationLogs;
    PRINT '  - Dropped VerificationLogs table';
END

IF OBJECT_ID('Drivers', 'U') IS NOT NULL 
BEGIN
    DROP TABLE Drivers;
    PRINT '  - Dropped Drivers table';
END

IF OBJECT_ID('Users', 'U') IS NOT NULL 
BEGIN
    DROP TABLE Users;
    PRINT '  - Dropped Users table';
END
GO

-- =====================================================
-- CREATE TABLES
-- =====================================================
PRINT '';
PRINT 'Creating tables...';

-- Users Table
-- Stores system users who can register drivers and verify licenses
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'active'
);
PRINT '  - Created Users table';
GO

-- Drivers Table
-- Stores driver license information
CREATE TABLE Drivers (
    DriverID INT PRIMARY KEY IDENTITY(1,1),
    LicenseID NVARCHAR(50) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    LicenseType NVARCHAR(10) NOT NULL,
    ExpiryDate DATE NOT NULL,
    QRRawData NVARCHAR(MAX) NULL,
    OCRRawText NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    RegisteredBy INT NOT NULL
);
PRINT '  - Created Drivers table';
GO

-- VerificationLogs Table
-- Audit trail for all license verification attempts
CREATE TABLE VerificationLogs (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    LicenseID NVARCHAR(50) NOT NULL,
    VerificationStatus NVARCHAR(20) NOT NULL,
    CheckedBy INT NOT NULL,
    CheckedDate DATETIME2 NOT NULL DEFAULT GETDATE()
);
PRINT '  - Created VerificationLogs table';
GO

PRINT '';
PRINT 'All tables created successfully!';
GO
