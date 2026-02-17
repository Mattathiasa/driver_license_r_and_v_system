# System Architecture and Data Flows

Complete guide to the Ethiopian Driver License System architecture and all data flows from Flutter to Database.

## Table of Contents
1. [System Architecture Overview](#system-architecture-overview)
2. [Authentication Flow](#authentication-flow)
3. [Driver Registration Flow](#driver-registration-flow)
4. [License Verification Flow](#license-verification-flow)
5. [Driver Display Flow](#driver-display-flow)
6. [Verification Logs Flow](#verification-logs-flow)
7. [Technology Stack](#technology-stack)
8. [API Endpoints](#api-endpoints)
9. [Database Schema](#database-schema)

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER MOBILE APP                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │   Services   │  │    Models    │      │
│  │  (UI Layer)  │→ │ (API Calls)  │→ │  (Data DTOs) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS (ngrok)
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                    .NET WEB API (Backend)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Controllers  │→ │   Services   │→ │ Repositories │      │
│  │ (Endpoints)  │  │  (Business)  │  │ (Data Access)│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────────┬────────────────────────────────┘
                             │ Entity Framework Core
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                   SQL SERVER DATABASE                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Users     │  │   Drivers    │  │Verification  │      │
│  │    Table     │  │    Table     │  │  Logs Table  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Communication Flow
1. **Flutter** → HTTP Request → **ngrok** → **.NET API**
2. **.NET API** → Entity Framework → **SQL Server**
3. **SQL Server** → Data → **.NET API** → JSON → **Flutter**

---


## Authentication Flow

### Overview
User logs in with username/password → Backend validates → Returns JWT token → Token used for all subsequent requests.

### Detailed Flow

```
┌─────────────┐                                    ┌─────────────┐
│   Flutter   │                                    │  .NET API   │
│  LoginScreen│                                    │AuthController│
└──────┬──────┘                                    └──────┬──────┘
       │                                                  │
       │ 1. User enters credentials                      │
       │    (username, password)                         │
       │                                                  │
       │ 2. POST /api/Auth/login                         │
       │    Body: {username, password}                   │
       ├─────────────────────────────────────────────────>│
       │                                                  │
       │                              3. Validate credentials
       │                                 AuthService.Login()
       │                                                  │
       │                              4. Query Users table
       │                                 Check username exists
       │                                 Verify password hash
       │                                                  │
       │                              5. Generate JWT token
       │                                 JwtHelper.GenerateToken()
       │                                 Token expires in 24h
       │                                                  │
       │ 6. Response: 200 OK                             │
       │    {token, expiresAt, userId, username}         │
       │<─────────────────────────────────────────────────┤
       │                                                  │
       │ 7. Store token in memory                        │
       │    AuthService.setToken(token)                  │
       │                                                  │
       │ 8. Navigate to HomeScreen                       │
       │                                                  │
```

### Flutter Components

**File**: `mobile-flutter/lib/screens/login_screen.dart`
```dart
// User submits login form
await _authService.login(username, password);
```

**File**: `mobile-flutter/lib/services/auth_service.dart`
```dart
Future<void> login(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/Auth/login'),
    body: json.encode({
      'username': username,
      'password': password,
    }),
  );
  
  final data = json.decode(response.body);
  _token = data['data']['token'];
  _userId = data['data']['userId'];
}
```

### Backend Components

**File**: `backend-dotnet/.../Controllers/AuthController.cs`
```csharp
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
{
    var user = await _authService.Login(request.Username, request.Password);
    var token = _authService.GenerateJwtToken(user.UserId, user.Username);
    
    return Ok(new LoginResponseDto {
        Token = token,
        ExpiresAt = DateTime.UtcNow.AddHours(24),
        UserId = user.UserId,
        Username = user.Username
    });
}
```

**File**: `backend-dotnet/.../Services/AuthService.cs`
```csharp
public async Task<User> Login(string username, string password)
{
    var user = await _context.Users
        .FirstOrDefaultAsync(u => u.Username == username);
    
    if (user == null || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
        throw new UnauthorizedAccessException("Invalid credentials");
    
    return user;
}
```

### Database Query
```sql
SELECT UserID, Username, PasswordHash, Status
FROM Users
WHERE Username = @username
```

### Token Usage
All subsequent API calls include the token:
```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

---


## Driver Registration Flow

### Overview
Scan license → OCR extracts data → User reviews → Submit to backend → Save to database.

### Detailed Flow

```
┌──────────────┐                                   ┌─────────────┐
│   Flutter    │                                   │  .NET API   │
│ScanLicense   │                                   │Driver       │
│Screen        │                                   │Controller   │
└──────┬───────┘                                   └──────┬──────┘
       │                                                  │
       │ 1. User taps "Scan License"                     │
       │    CunningDocumentScanner.getPictures()         │
       │                                                  │
       │ 2. Camera opens with edge detection             │
       │    User adjusts corners                         │
       │    Perspective correction applied               │
       │                                                  │
       │ 3. Image captured and enhanced                  │
       │    DocumentScannerService.scanDocument()        │
       │                                                  │
       │ 4. OCR processing                               │
       │    OCRService.extractDataFromImage()            │
       │    - Column detection (left/right)              │
       │    - Extract License ID (6 digits)              │
       │    - Extract Grade (Auto, Public 1, etc.)       │
       │    - Extract DOB (first date, right column)     │
       │    - Extract Expiry (last date, right column)   │
       │    - Extract Full Name (all caps, 10+ chars)    │
       │                                                  │
       │ 5. Display extracted data                       │
       │    User reviews and can edit                    │
       │                                                  │
       │ 6. User taps "Register Driver"                  │
       │                                                  │
       │ 7. POST /api/Driver/register                    │
       │    Headers: {Authorization: Bearer token}       │
       │    Body: {                                      │
       │      licenseId, fullName, dateOfBirth,          │
       │      licenseType, expiryDate,                   │
       │      qrRawData, ocrRawText                      │
       │    }                                            │
       ├─────────────────────────────────────────────────>│
       │                                                  │
       │                              8. Validate JWT token
       │                                 Extract userId from token
       │                                                  │
       │                              9. Check if license exists
       │                                 DriverRepository.ExistsByLicenseId()
       │                                                  │
       │                              10. If exists, return 409 Conflict
       │                                  "License already registered"
       │                                  Include current status
       │                                                  │
       │                              11. Parse and validate dates
       │                                  DateTime.TryParse()
       │                                  Check DOB not in future
       │                                  Check expiry not passed
       │                                                  │
       │                              12. Create Driver entity
       │                                  Status = "active" or "expired"
       │                                  CreatedDate = DateTime.Now
       │                                  RegisteredBy = userId
       │                                                  │
       │                              13. INSERT INTO Drivers
       │                                  Save to database
       │                                                  │
       │ 14. Response: 201 Created                       │
       │     {driverId, licenseId, status, ...}          │
       │<─────────────────────────────────────────────────┤
       │                                                  │
       │ 15. Show success notification                   │
       │     NotificationService.showSuccessNotification()│
       │                                                  │
       │ 16. Navigate back to home                       │
       │                                                  │
```

### Flutter Components

**File**: `mobile-flutter/lib/screens/scan_license_screen.dart`
```dart
// Scan document
List<String> pictures = await CunningDocumentScanner.getPictures(noOfPages: 1);

// Process with OCR
final data = await OCRService.extractDataFromImage(imagePath);

// Navigate to registration
Navigator.push(context, RegisterDriverScreen(prefilledData: data));
```

**File**: `mobile-flutter/lib/services/ocr_service.dart`
```dart
static Future<Map<String, String>> extractDataFromImage(String imagePath) {
  // Column detection
  // Extract license ID (6 digits)
  // Extract grade (Auto, Public 1, etc.)
  // Extract DOB (first date in right column)
  // Extract expiry (last date in right column)
  // Extract name (all caps, 10+ chars)
}
```

**File**: `mobile-flutter/lib/services/driver_api_service.dart`
```dart
Future<void> registerDriver({
  required String licenseId,
  required String fullName,
  required String dateOfBirth,
  required String licenseType,
  required String expiryDate,
  required String qrRawData,
  required String ocrRawText,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/Driver/register'),
    headers: {'Authorization': 'Bearer $token'},
    body: json.encode({...}),
  );
}
```

### Backend Components

**File**: `backend-dotnet/.../Controllers/DriverController.cs`
```csharp
[HttpPost("register")]
[Authorize]
public async Task<IActionResult> RegisterDriver([FromBody] DriverRegistrationDto dto)
{
    var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
    
    // Check if license already exists
    if (await _driverService.LicenseExists(dto.LicenseId))
    {
        var existing = await _driverService.GetDriverByLicenseId(dto.LicenseId);
        return Conflict($"License {dto.LicenseId} already registered. Status: {existing.Status}");
    }
    
    var driver = await _driverService.RegisterDriver(dto, userId);
    return CreatedAtAction(nameof(GetDriver), new { id = driver.DriverId }, driver);
}
```

**File**: `backend-dotnet/.../Services/DriverService.cs`
```csharp
public async Task<Driver> RegisterDriver(DriverRegistrationDto dto, int registeredByUserId)
{
    // Parse dates
    DateTime.TryParse(dto.DateOfBirth, out DateTime dateOfBirth);
    DateTime.TryParse(dto.ExpiryDate, out DateTime expiryDate);
    
    // Determine status
    string status = expiryDate >= DateTime.Now ? "active" : "expired";
    
    var driver = new Driver {
        LicenseId = dto.LicenseId,
        FullName = dto.FullName,
        DateOfBirth = dateOfBirth,
        LicenseType = dto.LicenseType,
        ExpiryDate = expiryDate,
        QRRawData = dto.QRRawData,
        OCRRawText = dto.OCRRawText,
        RegisteredBy = registeredByUserId,
        CreatedDate = DateTime.Now,
        Status = status
    };
    
    return await _driverRepository.Create(driver);
}
```

### Database Query
```sql
-- Check if exists
SELECT COUNT(*) FROM Drivers WHERE LicenseID = @licenseId

-- Insert new driver
INSERT INTO Drivers (
    LicenseID, FullName, DateOfBirth, LicenseType, ExpiryDate,
    QRRawData, OCRRawText, RegisteredBy, CreatedDate, Status
)
VALUES (
    @licenseId, @fullName, @dateOfBirth, @licenseType, @expiryDate,
    @qrRawData, @ocrRawText, @registeredBy, @createdDate, @status
)
```

---


## License Verification Flow

### Overview
Scan QR code → Extract license ID → Check database → Return verification status → Log verification.

### Detailed Flow

```
┌──────────────┐                                   ┌─────────────┐
│   Flutter    │                                   │  .NET API   │
│Verification  │                                   │Verification │
│Screen        │                                   │Controller   │
└──────┬───────┘                                   └──────┬──────┘
       │                                                  │
       │ 1. User taps "Verify License"                   │
       │    MobileScanner opens                          │
       │                                                  │
       │ 2. User scans QR code                           │
       │    Barcode detected                             │
       │    Extract: rawValue, displayValue              │
       │                                                  │
       │ 3. Parse QR data                                │
       │    OCRService.parseQRData()                     │
       │    Extract license ID from QR                   │
       │                                                  │
       │ 4. POST /api/Verification/verify                │
       │    Headers: {Authorization: Bearer token}       │
       │    Body: {                                      │
       │      licenseId: "654321",                       │
       │      qrRawData: "full QR content"               │
       │    }                                            │
       ├─────────────────────────────────────────────────>│
       │                                                  │
       │                              5. Validate JWT token
       │                                 Extract userId from token
       │                                                  │
       │                              6. Search for driver
       │                                 DriverRepository.GetByLicenseId()
       │                                 Query: SELECT * FROM Drivers
       │                                        WHERE LicenseID = @licenseId
       │                                                  │
       │                              7. Determine status
       │                                 If NOT found → "fake"
       │                                 If found:
       │                                   - Status = "active" → "active"
       │                                   - Status = "expired" → "expired"
       │                                                  │
       │                              8. Log verification
       │                                 INSERT INTO VerificationLogs
       │                                 (LicenseID, VerificationStatus,
       │                                  CheckedBy, CheckedDate)
       │                                                  │
       │ 9. Response: 200 OK                             │
       │    {                                            │
       │      licenseId: "654321",                       │
       │      verificationStatus: "active",              │
       │      driverName: "ABEBE KEBEDE",                │
       │      expiryDate: "2030-05-15",                  │
       │      checkedDate: "2024-02-17T13:30:00"         │
       │    }                                            │
       │<─────────────────────────────────────────────────┤
       │                                                  │
       │ 10. Display result                              │
       │     If "active" → Green "VERIFIED REAL"         │
       │     If "expired" → Orange "REAL BUT EXPIRED"    │
       │     If "fake" → Red "FAKE LICENSE"              │
       │                                                  │
       │ 11. Show notification                           │
       │     NotificationService.showVerificationResult()│
       │                                                  │
       │ 12. Play sound/vibration                        │
       │     Based on verification result                │
       │                                                  │
```

### Flutter Components

**File**: `mobile-flutter/lib/screens/verification_screen.dart`
```dart
// Scan QR code
MobileScanner(
  onDetect: (capture) {
    final barcode = capture.barcodes.first;
    final qrData = barcode.rawValue;
    
    // Parse QR data
    final parsed = OCRService.parseQRData(qrData);
    final licenseId = parsed['licenseId'];
    
    // Verify license
    _verifyLicense(licenseId, qrData);
  },
);
```

**File**: `mobile-flutter/lib/services/verification_api_service.dart`
```dart
Future<VerificationResult> verifyLicense(
  String licenseId,
  String qrRawData,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/Verification/verify'),
    headers: {'Authorization': 'Bearer $token'},
    body: json.encode({
      'licenseId': licenseId,
      'qrRawData': qrRawData,
    }),
  );
  
  return VerificationResult.fromJson(json.decode(response.body));
}
```

### Backend Components

**File**: `backend-dotnet/.../Controllers/VerificationController.cs`
```csharp
[HttpPost("verify")]
[Authorize]
public async Task<IActionResult> VerifyLicense([FromBody] VerificationRequestDto request)
{
    var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
    
    var result = await _verificationService.VerifyLicense(
        request.LicenseId,
        request.QrRawData,
        userId
    );
    
    return Ok(result);
}
```

**File**: `backend-dotnet/.../Services/VerificationService.cs`
```csharp
public async Task<VerificationResponseDto> VerifyLicense(
    string licenseId,
    string qrRawData,
    int checkedByUserId)
{
    // Search for driver
    var driver = await _driverRepository.GetByLicenseId(licenseId);
    
    string verificationStatus;
    
    if (driver == null)
    {
        verificationStatus = "fake";
    }
    else if (driver.Status == "active")
    {
        verificationStatus = "active";
    }
    else
    {
        verificationStatus = "expired";
    }
    
    // Log verification
    await LogVerification(licenseId, verificationStatus, checkedByUserId);
    
    return new VerificationResponseDto {
        LicenseId = licenseId,
        VerificationStatus = verificationStatus,
        DriverName = driver?.FullName,
        ExpiryDate = driver?.ExpiryDate,
        CheckedDate = DateTime.Now
    };
}

private async Task LogVerification(string licenseId, string status, int userId)
{
    var log = new VerificationLog {
        LicenseId = licenseId,
        VerificationStatus = status,
        CheckedBy = userId,
        CheckedDate = DateTime.Now
    };
    
    _context.VerificationLogs.Add(log);
    await _context.SaveChangesAsync();
}
```

### Database Queries

```sql
-- Search for driver
SELECT DriverID, LicenseID, FullName, Status, ExpiryDate
FROM Drivers
WHERE LicenseID = @licenseId

-- Log verification
INSERT INTO VerificationLogs (
    LicenseID, VerificationStatus, CheckedBy, CheckedDate
)
VALUES (
    @licenseId, @verificationStatus, @checkedBy, GETDATE()
)
```

### Verification Status Logic

```
┌─────────────────────────────────────────────────┐
│         Verification Status Decision            │
├─────────────────────────────────────────────────┤
│                                                 │
│  License NOT found in database                  │
│  ────────────────────────────────────────>      │
│                    Status = "fake"              │
│                                                 │
│  License found + Status = "active"              │
│  ────────────────────────────────────────>      │
│                    Status = "active"            │
│                                                 │
│  License found + Status = "expired"             │
│  ────────────────────────────────────────>      │
│                    Status = "expired"           │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

