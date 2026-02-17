# QR Code Verification Flow

## Overview
This document describes the updated QR code verification flow that checks driver licenses based on the Status column in the Drivers table.

## Verification Flow

### Step 1: Extract License ID from QR Code
When a QR code is scanned:
1. The QR scanner extracts the raw QR data
2. The `OCRService.parseQRData()` method extracts the license ID from the QR data
3. The license ID is passed to the verification screen

### Step 2: Search Driver Table
The backend searches for a driver with the scanned license ID:
```csharp
var driver = await _driverRepository.GetByLicenseId(licenseId);
```

### Step 3: Determine Verification Result

#### Case 1: No Driver Found (Fake License)
- **Condition:** `driver == null`
- **Result:** "Fake License"
- **Display:** 
  - Title: "Fake License"
  - Message: "This license is fake and not found in our central registry"
  - Color: Red
  - Icon: Cancel/Error icon

#### Case 2: Driver Found with Active Status (Real & Active)
- **Condition:** `driver.Status == "active"`
- **Result:** "Real License - Active"
- **Display:**
  - Title: "Real License"
  - Subtitle Badge: "Active" (green badge)
  - Message: "This license is genuine and currently active in the system"
  - Color: Green
  - Icon: Check circle icon
  - Shows driver details: License ID, Full Name, Grade, Expiry Date, Status

#### Case 3: Driver Found with Expired Status (Real & Expired)
- **Condition:** `driver.Status == "expired"`
- **Result:** "Real License - Expired"
- **Display:**
  - Title: "Real License"
  - Subtitle Badge: "Expired" (orange badge)
  - Message: "This license is real but has expired and needs renewal"
  - Color: Orange
  - Icon: Warning icon
  - Shows driver details: License ID, Full Name, Grade, Expiry Date, Status

## Backend Implementation

### VerificationService.cs
```csharp
public async Task<VerificationResponseDto> VerifyLicense(string licenseId, string qrRawData, int checkedByUserId)
{
    // Step 1: Search for driver by license ID
    var driver = await _driverRepository.GetByLicenseId(licenseId);

    // Step 2: If no driver found, it's a fake license
    if (driver == null)
    {
        return new VerificationResponseDto
        {
            LicenseId = licenseId,
            VerificationStatus = "fake",
            DriverName = null,
            ExpiryDate = null,
            CheckedDate = DateTime.UtcNow
        };
    }

    // Step 3: Driver exists, check the Status column
    string verificationStatus;
    
    if (driver.Status.Equals("active", StringComparison.OrdinalIgnoreCase))
    {
        verificationStatus = "active";
    }
    else if (driver.Status.Equals("expired", StringComparison.OrdinalIgnoreCase))
    {
        verificationStatus = "expired";
    }
    else
    {
        // Handle other statuses (suspended, revoked, etc.) as expired
        verificationStatus = "expired";
    }

    return new VerificationResponseDto
    {
        LicenseId = licenseId,
        VerificationStatus = verificationStatus,
        DriverName = driver.FullName,
        ExpiryDate = driver.ExpiryDate,
        CheckedDate = DateTime.UtcNow
    };
}
```

### VerificationResponseDto.cs
```csharp
public class VerificationResponseDto
{
    public string LicenseId { get; set; } = string.Empty;
    public string VerificationStatus { get; set; } = string.Empty;
    public string? DriverName { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public DateTime CheckedDate { get; set; }
    
    // Computed properties for Flutter compatibility
    public bool IsReal => VerificationStatus == "active" || VerificationStatus == "expired";
    public bool IsActive => VerificationStatus == "active";
    public string Message => VerificationStatus switch
    {
        "fake" => "This license is fake and not found in our central registry",
        "expired" => "This license is real but has expired",
        "active" => "This license is real and active",
        _ => "Unknown verification status"
    };
}
```

## Flutter Implementation

### verify_license_screen.dart

#### Result Determination
```dart
setState(() {
  _verifiedDriver = driver;
  // Determine status: fake, active, or expired
  if (!result.isReal) {
    _verificationResult = 'fake';
  } else if (result.isActive) {
    _verificationResult = 'active';
  } else {
    _verificationResult = 'expired';
  }
  _verificationMessage = result.message;
  _isVerifying = false;
});
```

#### Display Methods
```dart
String _getResultTitle() {
  switch (_verificationResult) {
    case 'active':
      return 'Real License';
    case 'expired':
      return 'Real License';
    case 'fake':
      return 'Fake License';
    default:
      return 'Unknown';
  }
}

String _getResultSubtitle() {
  switch (_verificationResult) {
    case 'active':
      return 'Active';
    case 'expired':
      return 'Expired';
    default:
      return '';
  }
}
```

## UI Display

### Fake License
```
┌─────────────────────────────┐
│     [Red Error Icon]        │
│                             │
│      Fake License           │
│                             │
│  This license is fake and   │
│  not found in our central   │
│  registry                   │
└─────────────────────────────┘
```

### Real License - Active
```
┌─────────────────────────────┐
│   [Green Check Icon]        │
│                             │
│     Real License            │
│   ┌─────────────┐          │
│   │   Active    │          │
│   └─────────────┘          │
│                             │
│  This license is genuine    │
│  and currently active       │
│                             │
│  License ID: A123456        │
│  Full Name: John Doe        │
│  Grade: Class B             │
│  Expiry Date: 2025-12-31    │
│  Status: ACTIVE             │
└─────────────────────────────┘
```

### Real License - Expired
```
┌─────────────────────────────┐
│  [Orange Warning Icon]      │
│                             │
│     Real License            │
│   ┌─────────────┐          │
│   │   Expired   │          │
│   └─────────────┘          │
│                             │
│  This license is real but   │
│  has expired                │
│                             │
│  License ID: A123456        │
│  Full Name: John Doe        │
│  Grade: Class B             │
│  Expiry Date: 2023-12-31    │
│  Status: EXPIRED            │
└─────────────────────────────┘
```

## Verification Logs
All verifications are logged with the status:
- `fake` - License not found in database
- `active` - Real license with active status
- `expired` - Real license with expired status

## Status Column Values
The Driver table Status column can have these values:
- `active` - License is valid and active
- `expired` - License has expired
- `suspended` - License is suspended (treated as expired in verification)
- `revoked` - License is revoked (treated as expired in verification)

## Testing Scenarios

### Test 1: Scan Non-existent License
1. Scan QR code with license ID that doesn't exist in database
2. Expected: "Fake License" displayed

### Test 2: Scan Active License
1. Scan QR code with valid license ID
2. Driver has Status = "active"
3. Expected: "Real License" with "Active" badge

### Test 3: Scan Expired License
1. Scan QR code with valid license ID
2. Driver has Status = "expired"
3. Expected: "Real License" with "Expired" badge

## Security Features
- Push notifications for fake licenses
- Push notifications for expired licenses
- All verifications logged with timestamp and user
- No QR data comparison (simplified verification based on license ID only)
