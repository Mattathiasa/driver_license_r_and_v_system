# Authentication and Authorization

## Current Implementation

### Authentication System

The project currently implements **JWT-based authentication** but does **NOT have role-based access control (RBAC)** implemented.

### What's Implemented ✅

#### 1. JWT Authentication
- Token-based authentication using JSON Web Tokens
- Secure password hashing with BCrypt
- Token expiration (24 hours)
- User identification via claims

#### 2. User Management
- User registration and login
- Password hashing (BCrypt)
- User status (active/inactive)
- User tracking for actions

#### 3. Protected Endpoints
All API endpoints (except login) require authentication:
```csharp
[Authorize]
public class DriverController : ControllerBase
{
    // All endpoints require valid JWT token
}
```

### What's NOT Implemented ❌

#### 1. Role-Based Access Control (RBAC)
- No role field in User table
- No role claims in JWT tokens
- No role-based endpoint restrictions
- All authenticated users have same permissions

#### 2. Permission System
- No granular permissions
- No action-level authorization
- No resource-based access control

#### 3. User Roles
- No admin vs officer distinction
- No role hierarchy
- No role assignment

---

## Current User Model

### Database Schema

```sql
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'active'
);
```

**Missing**: `Role` or `RoleID` field

### Entity Model

```csharp
public class User
{
    public int UserId { get; set; }
    public string Username { get; set; }
    public string PasswordHash { get; set; }
    public DateTime CreatedDate { get; set; }
    public string Status { get; set; } // active/inactive
    
    // No Role property
}
```

---

## Current Authentication Flow

### 1. Login Process

```
User enters credentials
    ↓
POST /api/Auth/login
    ↓
Verify username/password
    ↓
Generate JWT token with claims:
  - NameIdentifier (UserID)
  - Name (Username)
  - Sub (UserID)
  - Jti (Token ID)
    ↓
Return token + expiration
```

### 2. JWT Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "nameid": "1",              // User ID
    "unique_name": "admin",     // Username
    "sub": "1",                 // Subject (User ID)
    "jti": "guid-here",         // Token ID
    "exp": 1708257600,          // Expiration
    "iss": "DAFTechAPI",        // Issuer
    "aud": "DAFTechApp"         // Audience
  }
}
```

**Missing**: Role claim (e.g., `"role": "admin"`)

### 3. Authorization Check

```csharp
[Authorize] // Only checks if token is valid
public async Task<ActionResult> RegisterDriver(...)
{
    // Get user ID from token
    var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    
    // No role check - all authenticated users can register
    // ...
}
```

---

## Current Users

### Default Users (from seed data)

| Username | Password | Status | Intended Role |
|----------|----------|--------|---------------|
| admin | Admin@123 | active | Administrator |
| officer1 | Officer@123 | active | Officer |
| officer2 | Officer@123 | active | Officer |

**Note**: All users have identical permissions despite different usernames.

---

## What All Authenticated Users Can Do

Currently, ANY authenticated user can:

✅ Register new drivers
✅ View all drivers
✅ Verify licenses
✅ View verification logs
✅ Export verification logs to CSV
✅ Access all API endpoints

There are NO restrictions based on user type.

---

## How to Implement Role-Based Access Control

If you want to add RBAC, here's what needs to be done:

### Step 1: Add Role to Database

```sql
-- Add Role column to Users table
ALTER TABLE Users
ADD Role NVARCHAR(20) NOT NULL DEFAULT 'officer';

-- Update existing users
UPDATE Users SET Role = 'admin' WHERE Username = 'admin';
UPDATE Users SET Role = 'officer' WHERE Username LIKE 'officer%';

-- Add constraint
ALTER TABLE Users
ADD CONSTRAINT CK_Users_Role 
CHECK (Role IN ('admin', 'officer', 'viewer'));
```

### Step 2: Update User Entity

```csharp
public class User
{
    public int UserId { get; set; }
    public string Username { get; set; }
    public string PasswordHash { get; set; }
    public DateTime CreatedDate { get; set; }
    public string Status { get; set; }
    public string Role { get; set; } = "officer"; // NEW
}
```

### Step 3: Add Role to JWT Token

```csharp
// In JwtHelper.cs
Subject = new ClaimsIdentity(new[]
{
    new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
    new Claim(ClaimTypes.Name, username),
    new Claim(ClaimTypes.Role, role), // NEW
    new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
    new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
})
```

### Step 4: Protect Endpoints with Roles

```csharp
// Admin only
[Authorize(Roles = "admin")]
[HttpGet("all")]
public async Task<ActionResult> GetAllDrivers()
{
    // Only admins can view all drivers
}

// Admin and Officer
[Authorize(Roles = "admin,officer")]
[HttpPost("register")]
public async Task<ActionResult> RegisterDriver(...)
{
    // Admins and officers can register
}

// All authenticated users
[Authorize]
[HttpPost("verify")]
public async Task<ActionResult> VerifyLicense(...)
{
    // Any authenticated user can verify
}
```

### Step 5: Update Login Response

```csharp
return new LoginResponseDto
{
    Token = token,
    ExpiresAt = DateTime.Now.AddHours(24),
    UserId = user.UserId,
    Username = user.Username,
    Role = user.Role // NEW
};
```

---

## Proposed Role Hierarchy

### Admin Role
**Permissions**:
- ✅ Register drivers
- ✅ View all drivers
- ✅ Edit driver information
- ✅ Delete drivers
- ✅ Verify licenses
- ✅ View all verification logs
- ✅ Export logs
- ✅ Manage users (create/edit/delete)
- ✅ View system statistics

### Officer Role
**Permissions**:
- ✅ Register drivers
- ✅ View all drivers
- ✅ Verify licenses
- ✅ View verification logs (own only)
- ✅ Export logs (own only)
- ❌ Edit/delete drivers
- ❌ Manage users

### Viewer Role (Optional)
**Permissions**:
- ✅ Verify licenses
- ✅ View verification logs (own only)
- ❌ Register drivers
- ❌ Edit/delete drivers
- ❌ Manage users

---

## Security Considerations

### Current Security ✅

1. **Password Hashing**: BCrypt with salt
2. **JWT Tokens**: Signed with secret key
3. **HTTPS**: Ngrok provides SSL/TLS
4. **Token Expiration**: 24-hour validity
5. **Authentication Required**: All endpoints protected

### Security Gaps ❌

1. **No Role-Based Access**: All users have same permissions
2. **No Audit Trail**: Can't track who did what
3. **No Rate Limiting**: No protection against brute force
4. **No Token Refresh**: Users must re-login after 24 hours
5. **No Password Policy**: No complexity requirements

---

## Mobile App Authentication

### Current Flow

```dart
// Login
final response = await http.post(
  Uri.parse('$baseUrl/api/Auth/login'),
  body: json.encode({
    'username': username,
    'password': password,
  }),
);

// Store token
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);

// Use token in requests
final response = await http.post(
  Uri.parse('$baseUrl/api/Driver/register'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

### No Role Checking in Mobile App

The mobile app doesn't check user roles because:
1. No role information in login response
2. All authenticated users have same UI
3. No conditional feature display

---

## Recommendations

### For Production Use

If deploying to production, you should implement:

1. **Role-Based Access Control**
   - Add roles to database
   - Implement role checks in API
   - Update mobile app to show/hide features based on role

2. **Enhanced Security**
   - Add rate limiting
   - Implement token refresh
   - Add password complexity requirements
   - Add account lockout after failed attempts

3. **Audit Logging**
   - Log all user actions
   - Track who registered/edited drivers
   - Monitor verification activities

4. **Permission Management**
   - Granular permissions beyond roles
   - Resource-based access control
   - Dynamic permission assignment

---

## Summary

### Current State

✅ **Authentication**: Implemented with JWT
✅ **User Management**: Basic user CRUD
✅ **Password Security**: BCrypt hashing
✅ **Token-Based Access**: All endpoints protected

❌ **Authorization**: NOT implemented
❌ **Role-Based Access**: NOT implemented
❌ **Permission System**: NOT implemented
❌ **Granular Control**: NOT implemented

### Impact

**All authenticated users have identical permissions**. There is no distinction between admin and officer users beyond their usernames.

### Next Steps

To implement RBAC:
1. Add `Role` column to Users table
2. Update User entity model
3. Add role claim to JWT tokens
4. Protect endpoints with `[Authorize(Roles = "...")]`
5. Update mobile app to handle roles
6. Test role-based restrictions

---

**Last Updated**: February 17, 2024
**Status**: Authentication ✅ | Authorization ❌
