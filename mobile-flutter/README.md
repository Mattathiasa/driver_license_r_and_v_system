# Driver License Registration & Verification System

A comprehensive mobile and backend system for registering and verifying driver license information using OCR technology, QR code scanning, and real-time database validation.

## Project Description

This system enables administrative officers to register new driver licenses, scan existing licenses using OCR (Optical Character Recognition), and verify license authenticity against a central database in real-time. The application extracts license information from physical documents, generates digital QR codes, and maintains detailed audit trails of all verification activities.

### Key Features

- **Automated License Scanning**: Extract license data using Google ML Kit OCR technology
- **Driver Registration**: Register new drivers with OCR-extracted data and manual verification
- **Duplicate Detection**: Automatic check to prevent duplicate license registrations
- **Real/Fake Verification**: Validate license authenticity by checking against database and QR data
- **QR Code Generation & Scanning**: Generate and scan QR codes for quick verification
- **Real-time Verification**: Validate license authenticity against the backend database
- **Audit Trail**: Comprehensive logging of all verification attempts with timestamps
- **User Authentication**: Secure JWT-based authentication system
- **Dashboard Analytics**: Real-time statistics on drivers and verification activities
- **Multi-language Support**: Handles both English and Amharic (Ethiopian) license formats

## Technology Stack

### Mobile Application (Frontend)
- **Framework**: Flutter 3.11.0
- **Language**: Dart
- **Key Dependencies**:
  - `google_mlkit_text_recognition` (^0.11.0) - OCR text extraction
  - `qr_code_scanner` (^1.0.1) - QR code scanning
  - `qr_flutter` (^4.1.0) - QR code generation
  - `camera` (^0.10.5) - Camera integration
  - `image_picker` (^1.0.4) - Image selection
  - `http` (^1.1.0) - API communication
  - `shared_preferences` (^2.2.2) - Local storage
  - `google_fonts` (^6.1.0) - Typography
  - `animate_do` (^3.3.4) - Animations
  - `flutter_local_notifications` (^20.1.0) - Push notifications

### Backend API
- **Framework**: .NET 8 Web API
- **Language**: C#
- **Architecture**: Clean Architecture with single-project structure
- **Key Technologies**:
  - Entity Framework Core - ORM for database operations
  - JWT (JSON Web Tokens) - Authentication and authorization
  - BCrypt.Net - Password hashing
  - SQL Server - Database provider

### Database
- **DBMS**: Microsoft SQL Server
- **Tables**:
  - `Users` - System users and authentication
  - `Drivers` - Driver license records
  - `VerificationLogs` - Verification audit trail

### Development Tools
- **IDE**: Visual Studio Code
- **Version Control**: Git
- **Database Management**: SQL Server Management Studio (SSMS)
- **API Testing**: Postman / Thunder Client

## Project Structure

```
driver_license_registration_and_verification_system/
├── lib/                          # Flutter application source
│   ├── config/                   # Configuration files
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic services
│   └── main.dart                 # Application entry point
├── backend/                      # .NET backend
│   ├── DAFTech.DriverLicenseSystem.Api/
│   │   ├── Controllers/          # API endpoints
│   │   ├── Models/               # Entity and DTO models
│   │   │   ├── Entities/         # Database entities
│   │   │   └── DTOs/             # Data transfer objects
│   │   ├── Services/             # Business logic
│   │   ├── Repositories/         # Data access layer
│   │   ├── Data/                 # Database context
│   │   ├── Helpers/              # Utility classes
│   │   ├── Middleware/           # Custom middleware
│   │   └── Program.cs            # Application startup
│   ├── GeneratePasswordHash/     # Password hash utility
│   └── DriverLicenseSystem.sln   # Solution file
├── database/                     # Database scripts
│   └── schema.sql                # Database schema
└── README.md                     # This file
```

## Setup Instructions

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.11.0 or higher) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **.NET 8 SDK** - [Install .NET](https://dotnet.microsoft.com/download)
- **SQL Server** (2019 or higher) - [Install SQL Server](https://www.microsoft.com/sql-server/sql-server-downloads)
- **Git** - [Install Git](https://git-scm.com/downloads)
- **Android Studio** or **Xcode** (for mobile development)

### 1. Clone the Repository

```bash
git clone https://github.com/mattathiasa/driver_license_r_and_v_system.git
cd driver_license_r_and_v_system
```

## Database Setup

### Manual Setup

1. Open SQL Server Management Studio (SSMS)
2. Connect to your SQL Server instance
3. Open and execute `database/schema.sql`
4. Verify tables were created:
   ```sql
   USE DriverLicenseDB;
   SELECT * FROM INFORMATION_SCHEMA.TABLES;
   ```

### Database Schema

**Users Table**
- `UserID` (INT, Primary Key)
- `Username` (NVARCHAR(50), Unique)
- `PasswordHash` (NVARCHAR(255))
- `CreatedDate` (DATETIME2)
- `Status` (NVARCHAR(20))

**Drivers Table**
- `DriverID` (INT, Primary Key)
- `LicenseID` (NVARCHAR(50), Unique)
- `FullName` (NVARCHAR(100))
- `DateOfBirth` (DATE)
- `LicenseType` (NVARCHAR(10)) - Grade (A, B, C, etc.)
- `ExpiryDate` (DATE)
- `QRRawData` (NVARCHAR(MAX))
- `OCRRawText` (NVARCHAR(MAX))
- `CreatedDate` (DATETIME2)
- `RegisteredBy` (INT, Foreign Key → Users)

**VerificationLogs Table**
- `LogID` (INT, Primary Key)
- `LicenseID` (NVARCHAR(50))
- `VerificationStatus` (NVARCHAR(20))
- `CheckedBy` (INT, Foreign Key → Users)
- `CheckedDate` (DATETIME2)

### Default Credentials

After database setup, use these credentials to login:

- **Username**: `admin`
- **Password**: `Admin@123`

## How to Run Backend

### Clean Backend Structure

The backend has been consolidated into a single clean project: `DAFTech.DriverLicenseSystem.Api`

**To remove old projects (if they still exist):**
```powershell
cd backend
.\cleanup-old-projects.ps1
```

This will remove:
- Old multi-project structure (DriverLicenseSystem.API, Core, Infrastructure)
- Outdated documentation files
- Old test scripts

### Step 1: Configure Database Connection

Edit `backend/DAFTech.DriverLicenseSystem.Api/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=DriverLicenseDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

Update the connection string based on your SQL Server configuration:
- For Windows Authentication: Use `Trusted_Connection=True`
- For SQL Authentication: Use `User Id=sa;Password=YourPassword`

### Step 2: Restore Dependencies

```bash
cd backend/DAFTech.DriverLicenseSystem.Api
dotnet restore
```

### Step 3: Run the API

**Option 1: Using PowerShell script (Recommended)**
```powershell
cd backend
.\start-api.ps1
```

**Option 2: Using dotnet CLI**
```bash
cd backend/DAFTech.DriverLicenseSystem.Api
dotnet run
```

The API will start on:
- **HTTP**: `http://localhost:5182`

### Step 4: Verify API is Running

Open your browser and navigate to:
```
http://localhost:5182/swagger
```

You should see the Swagger API documentation page with all available endpoints.

### API Endpoints

**Authentication**
- `POST /api/auth/login` - User login (returns JWT token)

**Driver Management**
- `GET /api/driver` - Get all drivers
- `GET /api/driver/{licenseId}` - Get driver by license ID
- `POST /api/driver/register` - Register new driver

**Verification**
- `POST /api/verification/verify` - Verify license by ID or QR data
- `GET /api/verification/status/{licenseId}` - Get license status
- `GET /api/verification/logs` - Get verification logs (with optional filters)
- `GET /api/verification/export` - Export verification logs as CSV

## How to Run Mobile App

### Step 1: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 2: Configure API Endpoint

Edit `lib/config/api_config.dart` and update the base URL:

```dart
class ApiConfig {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5182/api';
  
  // For Physical Device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.1.100:5182/api';
  
  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:5182/api';
}
```

**Finding Your Computer's IP Address:**

Windows:
```powershell
ipconfig
```
Look for "IPv4 Address" under your active network adapter.

macOS/Linux:
```bash
ifconfig
```

### Step 3: Run on Emulator/Simulator

**Android Emulator:**
```bash
flutter run
```

**iOS Simulator (macOS only):**
```bash
flutter run -d ios
```

### Step 4: Run on Physical Device

1. Enable USB Debugging on your Android device
2. Connect device via USB
3. Run:
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

### Step 5: Build APK (Android)

```bash
flutter build apk --release
```

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Usage Guide

### Core Features Implementation

**1. Driver Registration**
- Scan license using camera or upload image
- OCR automatically extracts: License ID, Full Name, Date of Birth, Grade, Expiry Date
- System checks for duplicates before registration
- If license already exists, returns conflict error with existing license details
- Successfully registered drivers are stored with QR and OCR raw data

**2. Duplicate Detection**
- Automatic check during registration process
- Searches database by License ID before creating new record
- Returns HTTP 409 Conflict if license already exists
- Prevents duplicate entries in the system

**3. Real/Fake Verification**
- Scans QR code or enters License ID manually
- System checks if license exists in database
- Compares scanned QR data with stored QR data (if provided)
- Validates expiry date
- Returns one of three statuses:
  - **Real**: License exists and is valid (not expired)
  - **Fake**: License not found in database or QR data mismatch
  - **Expired**: License exists but expiry date has passed
- All verification attempts are logged with timestamp and user ID

### Step-by-Step Usage

### 1. Login
- Open the app
- Enter username: `admin`
- Enter password: `Admin@123`
- Tap "Login"

### 2. Register New Driver
- Tap "Scan License" from home screen
- Capture or upload license image
- OCR will extract: License ID, Full Name, Date of Birth, Grade, Expiry Date
- Review extracted data
- Tap "Register Driver"
- Fill any missing fields
- Tap "Register"

### 3. Verify License
- Tap "Verify License" from home screen
- Scan QR code or enter License ID manually
- View verification result (Real/Fake/Expired)
- Check driver details

### 4. View All Drivers
- Tap "All Drivers" from home screen
- Browse registered drivers
- Search by name or license ID
- View driver details

## Troubleshooting

### Backend Issues

**Database Connection Failed:**
- Verify SQL Server is running
- Check connection string in `appsettings.json`
- Ensure database `DriverLicenseDB` exists

**Login Failed:**
- Verify database has user records
- Check password hash is valid BCrypt format
- Ensure backend is running and accessible

### Mobile App Issues

**Cannot Connect to API:**
- Verify backend is running
- Check `api_config.dart` has correct IP address
- Ensure firewall allows connections on port 5182
- For physical device, ensure device and computer are on same network

**OCR Not Working:**
- Ensure camera permissions are granted
- Check image quality (clear, well-lit)
- Verify Google ML Kit is properly installed

**QR Scanner Not Working:**
- Grant camera permissions
- Ensure QR code is clear and visible
- Check lighting conditions

## Documentation

For more information, see:
- `backend/README.md` - Backend project documentation
- `database/schema.sql` - Complete database schema

## Contributors

- **Mattathias Abraham** - Developer

## License

This project is developed as part of an internship program.

## Support

For issues or questions, please contact the development team or create an issue in the repository.
