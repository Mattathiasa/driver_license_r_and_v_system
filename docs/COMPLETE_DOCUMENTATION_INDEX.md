# DAFTech Driver License System - Complete Documentation

## Table of Contents

### 🚀 Getting Started
1. [System Overview](#system-overview)
2. [Quick Setup Guide](#quick-setup-guide)
3. [System Architecture](#system-architecture)

### 📱 Mobile Application
4. [Flutter App Setup](#flutter-app-setup)
5. [OCR & Document Scanning](#ocr--document-scanning)
6. [QR Code Verification](#qr-code-verification)

### 🖥️ Backend API
7. [.NET API Setup](#net-api-setup)
8. [API Endpoints](#api-endpoints)
9. [Authentication & Security](#authentication--security)

### 💾 Database
10. [Database Schema](#database-schema)
11. [Database Setup](#database-setup)
12. [Data Management](#data-management)

### 🔧 Configuration
13. [Network Configuration](#network-configuration)
14. [Ngrok Setup](#ngrok-setup)
15. [Environment Variables](#environment-variables)

### 📚 Feature Documentation
16. [License Registration](#license-registration)
17. [License Verification](#license-verification)
18. [Verification Logs](#verification-logs)
19. [User Management](#user-management)

### 🛠️ Technical Details
20. [OCR Extraction Rules](#ocr-extraction-rules)
21. [Date Extraction Logic](#date-extraction-logic)
22. [License Types](#license-types)
23. [Local Time Implementation](#local-time-implementation)

### 🐛 Troubleshooting
24. [Common Issues](#common-issues)
25. [Error Messages](#error-messages)
26. [Debugging Guide](#debugging-guide)

---

## System Overview

### What is DAFTech Driver License System?

A comprehensive digital driver license management system for Ethiopia that includes:
- **Mobile App**: Flutter-based Android app for license registration and verification
- **Backend API**: .NET Core REST API for data management
- **Database**: SQL Server database for secure data storage
- **OCR Technology**: Google ML Kit for automatic license data extraction
- **QR Verification**: Real-time license verification via QR code scanning

### Key Features

✅ **License Registration**
- Scan physical license with camera
- Automatic edge detection and perspective correction
- OCR extraction of license data
- Manual data verification and editing
- QR code generation

✅ **License Verification**
- QR code scanning
- Real-time verification (Active/Expired/Fake)
- Verification history logging
- Offline capability

✅ **User Management**
- Secure authentication with JWT
- Role-based access control
- User activity tracking

✅ **Audit & Reporting**
- Complete verification logs
- CSV export functionality
- Real-time statistics

---

## Quick Setup Guide

### Prerequisites

**Backend:**
- Windows 10/11
- .NET 9.0 SDK
- SQL Server 2019 or later
- Visual Studio 2022 (optional)

**Mobile:**
- Flutter SDK 3.0+
- Android Studio
- Android device or emulator (API 21+)

**Network:**
- Ngrok account (for remote access)
- Internet connection

### Setup Steps

1. **Database Setup** (5 minutes)
   ```cmd
   cd database
   run-setup.bat
   ```

2. **Backend API** (2 minutes)
   ```cmd
   cd backend-dotnet
   dotnet restore
   dotnet run
   ```

3. **Ngrok Setup** (3 minutes)
   ```cmd
   setup-ngrok-auth.bat
   run-with-ngrok.bat
   ```

4. **Mobile App** (5 minutes)
   ```cmd
   cd mobile-flutter
   flutter pub get
   flutter run
   ```

**Total Setup Time: ~15 minutes**

---

## System Architecture

### High-Level Architecture

```
┌─────────────────┐
│  Mobile App     │
│  (Flutter)      │
└────────┬────────┘
         │ HTTPS
         ↓
┌─────────────────┐
│  Ngrok Tunnel   │
│  (Public URL)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  .NET API       │
│  (Port 5182)    │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  SQL Server     │
│  (Database)     │
└─────────────────┘
```

### Technology Stack

**Frontend:**
- Flutter 3.0+
- Dart 3.0+
- Google ML Kit (OCR)
- Mobile Scanner (QR)
- Cunning Document Scanner (Edge Detection)

**Backend:**
- .NET 9.0
- ASP.NET Core Web API
- Entity Framework Core
- JWT Authentication

**Database:**
- SQL Server 2019+
- T-SQL Stored Procedures
- Indexed Tables

**Infrastructure:**
- Ngrok (Tunneling)
- Windows Server
- HTTPS/TLS

---

## Flutter App Setup

### Installation

1. **Install Flutter SDK**
   - Download from: https://flutter.dev
   - Add to PATH

2. **Install Dependencies**
   ```cmd
   cd mobile-flutter
   flutter pub get
   ```

3. **Configure API URL**
   - Edit `lib/config/api_config.dart`
   - Set ngrok URL

4. **Run App**
   ```cmd
   flutter run
   ```

### Project Structure

```
mobile-flutter/
├── lib/
│   ├── config/          # API configuration
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   ├── services/        # Business logic
│   └── main.dart        # Entry point
├── android/             # Android config
├── assets/              # Images, fonts
└── pubspec.yaml         # Dependencies
```

### Key Dependencies

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.6.1  # OCR
  mobile_scanner: ^3.5.2                  # QR scanning
  cunning_document_scanner: ^1.2.2        # Document scanning
  http: ^1.1.0                            # API calls
  shared_preferences: ^2.2.2              # Local storage
```

---

## OCR & Document Scanning

### Document Scanning Flow

```
1. Camera Capture
   ↓
2. Edge Detection (Automatic)
   ↓
3. Corner Adjustment (Manual)
   ↓
4. Perspective Correction
   ↓
5. Image Enhancement
   ↓
6. OCR Text Extraction
   ↓
7. Data Parsing & Validation
   ↓
8. Registration Form
```

### OCR Extraction

**What Gets Extracted:**
- License ID (6 digits)
- Full Name (All caps)
- Date of Birth (DD/MM/YYYY)
- Expiry Date (DD/MM/YYYY)
- Grade/Type (Auto, Public 1, etc.)

**See detailed documentation:**
- [OCR Extraction Rules](OCR_EXTRACTION_RULES.md)
- [Date Extraction Logic](DATE_EXTRACTION_LOGIC.md)
- [License Types](LICENSE_TYPES.md)

---

## QR Code Verification

### Verification Flow

```
1. Scan QR Code
   ↓
2. Extract License ID
   ↓
3. API Call to Backend
   ↓
4. Database Lookup
   ↓
5. Status Check (Active/Expired/Fake)
   ↓
6. Log Verification
   ↓
7. Display Result
```

### Verification Statuses

| Status | Meaning | Display |
|--------|---------|---------|
| **active** | Valid license, not expired | ✅ VERIFIED REAL |
| **expired** | Real license, past expiry | ⚠️ REAL BUT EXPIRED |
| **fake** | Not in database | ❌ FAKE LICENSE |

**See:** [QR Verification Flow](QR_VERIFICATION_FLOW.md)

---

## .NET API Setup

### Installation

1. **Install .NET SDK**
   ```cmd
   winget install Microsoft.DotNet.SDK.9
   ```

2. **Restore Packages**
   ```cmd
   cd backend-dotnet/DAFTech.DriverLicenseSystem.Api
   dotnet restore
   ```

3. **Update Connection String**
   - Edit `appsettings.json`
   - Set SQL Server connection

4. **Run API**
   ```cmd
   dotnet run
   ```

### Project Structure

```
backend-dotnet/
└── DAFTech.DriverLicenseSystem.Api/
    ├── Controllers/      # API endpoints
    ├── Services/         # Business logic
    ├── Repositories/     # Data access
    ├── Models/
    │   ├── Entities/     # Database models
    │   └── DTOs/         # Data transfer objects
    ├── Data/             # DbContext
    ├── Helpers/          # Utilities
    └── Middleware/       # Error handling
```

---

## API Endpoints

### Authentication

**POST** `/api/Auth/login`
```json
Request:
{
  "username": "admin",
  "password": "Admin@123"
}

Response:
{
  "token": "eyJhbGc...",
  "expiresAt": "2024-02-18T10:00:00",
  "userId": 1,
  "username": "admin"
}
```

### Driver Registration

**POST** `/api/Driver/register`
```json
Request:
{
  "licenseId": "654321",
  "fullName": "ABEBE KEBEDE",
  "dateOfBirth": "1990-05-15",
  "licenseType": "Auto",
  "expiryDate": "2030-05-15",
  "qrRawData": "654321|ABEBE KEBEDE|...",
  "ocrRawText": "License ID: 654321..."
}

Response:
{
  "success": true,
  "message": "Driver registered successfully",
  "data": { ... }
}
```

### License Verification

**POST** `/api/Verification/verify`
```json
Request:
{
  "licenseId": "654321",
  "qrRawData": "654321|ABEBE KEBEDE|..."
}

Response:
{
  "licenseId": "654321",
  "verificationStatus": "active",
  "driverName": "ABEBE KEBEDE",
  "expiryDate": "2030-05-15",
  "checkedDate": "2024-02-17T13:30:00"
}
```

### Get All Drivers

**GET** `/api/Driver/all`

### Get Verification Logs

**GET** `/api/Verification/logs`

**GET** `/api/Verification/logs/export` (CSV)

---

## Database Schema

### Tables

**Users**
- UserID (PK)
- Username (Unique)
- PasswordHash
- CreatedDate
- Status

**Drivers**
- DriverID (PK)
- LicenseID (Unique)
- FullName
- DateOfBirth
- LicenseType
- ExpiryDate
- QRRawData
- OCRRawText
- CreatedDate
- RegisteredBy (FK → Users)
- Status

**VerificationLogs**
- LogID (PK)
- LicenseID
- VerificationStatus
- CheckedBy (FK → Users)
- CheckedDate

### Relationships

```
Users (1) ──→ (N) Drivers (RegisteredBy)
Users (1) ──→ (N) VerificationLogs (CheckedBy)
```

**See:** [Database README](../database/README.md)

---

## Database Setup

### Automated Setup

```cmd
cd database
run-setup.bat
```

This runs:
1. `01-create-database.sql` - Creates database
2. `02-create-tables.sql` - Creates tables
3. `03-create-constraints.sql` - Adds constraints
4. `04-create-indexes.sql` - Creates indexes
5. `05-seed-data.sql` - Inserts sample data

### Manual Setup

```cmd
sqlcmd -S localhost -E -i 01-create-database.sql
sqlcmd -S localhost -E -i 02-create-tables.sql
sqlcmd -S localhost -E -i 03-create-constraints.sql
sqlcmd -S localhost -E -i 04-create-indexes.sql
sqlcmd -S localhost -E -i 05-seed-data.sql
```

### Default Users

| Username | Password | Role |
|----------|----------|------|
| admin | Admin@123 | Administrator |
| officer1 | Officer@123 | Officer |

---

## Network Configuration

### Ngrok Setup

1. **Create Account**
   - Visit: https://ngrok.com
   - Sign up for free account

2. **Get Auth Token**
   - Dashboard → Your Authtoken
   - Copy token

3. **Configure**
   ```cmd
   setup-ngrok-auth.bat
   ```
   - Paste your token when prompted

4. **Start Tunnel**
   ```cmd
   run-with-ngrok.bat
   ```

5. **Get Public URL**
   - Look for: `https://xxxxx.ngrok-free.app`
   - Update Flutter app config

**See:** [Ngrok Setup Guide](NGROK_SETUP.md)

---

## License Registration

### Registration Process

1. **Scan License**
   - Open app → "Register Driver"
   - Tap "Scan License"
   - Camera opens with document scanner

2. **Edge Detection**
   - Automatic edge detection
   - Adjust corners if needed
   - Confirm capture

3. **OCR Processing**
   - Image enhancement
   - Text extraction
   - Data parsing

4. **Review & Edit**
   - Verify extracted data
   - Edit if needed
   - Check all fields

5. **Submit**
   - Tap "Register Driver"
   - Confirmation message
   - QR code generated

### Required Fields

- ✅ License ID (6 digits)
- ✅ Full Name
- ✅ Date of Birth
- ✅ License Type/Grade
- ✅ Expiry Date

### Validation Rules

**License ID:**
- Exactly 6 digits
- Unique in database
- Example: `654321`

**Full Name:**
- Minimum 3 characters
- Letters and spaces only

**Date of Birth:**
- Format: YYYY-MM-DD
- Must be in the past
- Reasonable age (18-100)

**License Type:**
- Must be one of: Auto, Public 1, Public 2, 02, Taxi 1, Taxi 2

**Expiry Date:**
- Format: YYYY-MM-DD
- Must be in the future

---

## License Verification

### Verification Process

1. **Scan QR Code**
   - Open app → "Verify License"
   - Point camera at QR code
   - Automatic scanning

2. **Extract Data**
   - Parse QR code data
   - Extract license ID

3. **API Verification**
   - Send to backend
   - Database lookup
   - Status check

4. **Display Result**
   - Show verification status
   - Display driver details
   - Log verification

### Verification Results

**✅ VERIFIED REAL (Active)**
- License exists in database
- Status is "active"
- Not expired
- Green indicator

**⚠️ REAL BUT EXPIRED**
- License exists in database
- Status is "expired"
- Past expiry date
- Orange indicator

**❌ FAKE LICENSE**
- License NOT in database
- Invalid license ID
- Red indicator

---

## Verification Logs

### Log Information

Each verification is logged with:
- License ID
- Verification Status
- Checked By (Username)
- Checked Date (Local time)

### Viewing Logs

**Mobile App:**
- Menu → "Verification History"
- Shows all verifications
- Filter by status
- Search by license ID

**Export:**
- Tap export icon
- Generates CSV file
- Includes all log data

### CSV Export Format

```csv
LogID,LicenseID,Status,CheckedBy,CheckedDate
1,654321,active,admin,2024-02-17 13:30:00
2,123456,fake,officer1,2024-02-17 14:15:00
```

---

## OCR Extraction Rules

### License ID
- **Format**: 6 digits only
- **Example**: `654321`
- **Location**: Left column
- **Extraction**: First 6 consecutive digits

### Full Name
- **Format**: All uppercase, 10+ characters
- **Example**: `ABEBE KEBEDE TESFAYE`
- **Location**: Anywhere in text
- **Extraction**: First all-caps line ≥10 chars

### Date of Birth
- **Format**: DD/MM/YYYY
- **Example**: `15/05/1990`
- **Location**: Right column
- **Extraction**: First date found (year 1900-2099)

### Expiry Date
- **Format**: DD/MM/YYYY
- **Example**: `15/05/2030`
- **Location**: Right column
- **Extraction**: Last date found (year 2000-2099)

### License Type
- **Valid Types**: Auto, Public 1, Public 2, 02, Taxi 1, Taxi 2
- **Location**: After "Grade" keyword
- **Extraction**: Fuzzy matching with valid types

**See detailed documentation:**
- [OCR Extraction Rules](OCR_EXTRACTION_RULES.md)
- [Date Extraction Logic](DATE_EXTRACTION_LOGIC.md)
- [License Types](LICENSE_TYPES.md)

---

## Date Extraction Logic

### Column Detection
1. Calculate image midpoint
2. Split text into left/right columns
3. Extract dates from right column only

### DOB Extraction
- Take **FIRST** date in right column
- Year range: 1900-2099
- Formats: DD/MM/YYYY, DD-MM-YYYY, DD MM YYYY

### Expiry Extraction
- Find **ALL** dates in right column
- Take the **LAST** date
- Year range: 2000-2099 (future dates)

### Why This Works
Ethiopian licenses show dates in order:
1. DOB (first, year 19XX or 20XX)
2. Issue Date (middle, year 20XX)
3. Expiry Date (last, year 20XX)

**See:** [Date Extraction Logic](DATE_EXTRACTION_LOGIC.md)

---

## License Types

### Valid Types

1. **Auto** - Automatic transmission
2. **Public 1** - Public transport category 1
3. **Public 2** - Public transport category 2
4. **02** - Special category
5. **Taxi 1** - Taxi category 1
6. **Taxi 2** - Taxi category 2

### OCR Matching

The system uses fuzzy matching to handle OCR errors:

- `Aut0` → `Auto`
- `Pub1ic 1` → `Public 1`
- `O2` → `02`
- `Tax1 1` → `Taxi 1`

**See:** [License Types](LICENSE_TYPES.md)

---

## Local Time Implementation

### Overview
All dates and times are stored in **local time** (UTC+3 for Ethiopia).

### Changes Made
- Backend: `DateTime.UtcNow` → `DateTime.Now`
- Flutter: Removed `.toLocal()` conversion
- Database: Stores local time directly

### Benefits
- Times match user's timezone
- No conversion needed
- Accurate timestamps

**See:** [Local Time Update](LOCAL_TIME_UPDATE.md)

---

## Common Issues

### Issue: Registration Failed
**Cause**: Invalid data format or duplicate license ID

**Solution**:
1. Check license ID is exactly 6 digits
2. Verify dates are in YYYY-MM-DD format
3. Ensure license ID is unique

### Issue: Verification Not Working
**Cause**: Network connection or API down

**Solution**:
1. Check internet connection
2. Verify ngrok tunnel is running
3. Check API is running on port 5182

### Issue: OCR Not Extracting Data
**Cause**: Poor image quality or wrong license format

**Solution**:
1. Ensure good lighting
2. Hold camera steady
3. Adjust corners in document scanner
4. Manually edit extracted data

### Issue: Time Showing Wrong
**Cause**: Timezone mismatch

**Solution**:
1. Restart API after local time update
2. Check Windows timezone is UTC+3
3. Clear app cache and restart

---

## Error Messages

### "License ID already registered"
- License exists in database
- Shows current status (Active/Expired)
- Cannot register again

### "Invalid date format"
- Date not in YYYY-MM-DD format
- Check DOB and Expiry Date

### "Connection failed"
- Network issue
- Check ngrok tunnel
- Verify API is running

### "Authentication failed"
- Invalid username/password
- Token expired
- Login again

---

## Debugging Guide

### Enable Debug Logging

**Flutter:**
```dart
debugPrint('OCR Data: $data');
```

**Backend:**
```csharp
Console.WriteLine($"[DEBUG] {message}");
```

### Check API Logs
```cmd
cd backend-dotnet/DAFTech.DriverLicenseSystem.Api
dotnet run
```
Watch console for errors

### Check Database
```sql
-- View all drivers
SELECT * FROM Drivers;

-- View verification logs
SELECT * FROM VerificationLogs;

-- Check user
SELECT * FROM Users WHERE Username = 'admin';
```

### Network Debugging
```cmd
# Check ngrok status
curl https://your-ngrok-url.ngrok-free.app/api/health

# Test API locally
curl http://localhost:5182/api/health
```

---

## Additional Resources

### Documentation Files
- [System Architecture](SYSTEM_ARCHITECTURE_AND_FLOWS.md)
- [OCR Implementation](OCR_IMPLEMENTATION.md)
- [QR Verification Flow](QR_VERIFICATION_FLOW.md)
- [Database Schema](../database/README.md)
- [Ngrok Setup](NGROK_SETUP.md)

### External Links
- [Flutter Documentation](https://flutter.dev/docs)
- [.NET Documentation](https://docs.microsoft.com/dotnet)
- [SQL Server Documentation](https://docs.microsoft.com/sql)
- [Ngrok Documentation](https://ngrok.com/docs)

---

## Support

For issues or questions:
1. Check this documentation
2. Review error messages
3. Check logs (API and Flutter)
4. Verify configuration

---

**Last Updated**: February 17, 2024
**Version**: 1.0.0
