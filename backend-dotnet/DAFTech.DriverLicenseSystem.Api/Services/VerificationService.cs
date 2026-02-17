using DAFTech.DriverLicenseSystem.Api.Models.Entities;
using DAFTech.DriverLicenseSystem.Api.Models.DTOs;
using DAFTech.DriverLicenseSystem.Api.Repositories;
using DAFTech.DriverLicenseSystem.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace DAFTech.DriverLicenseSystem.Api.Services;

public class VerificationService
{
    private readonly DriverRepository _driverRepository;
    private readonly ApplicationDbContext _context;

    public VerificationService(
        DriverRepository driverRepository,
        ApplicationDbContext context)
    {
        _driverRepository = driverRepository;
        _context = context;
    }

    public async Task<VerificationResponseDto> VerifyLicense(string licenseId, string qrRawData, int checkedByUserId)
    {
        Console.WriteLine($"[DEBUG] VerifyLicense called with licenseId: '{licenseId}', qrRawData length: {qrRawData?.Length ?? 0}");
        
        // Step 1: Search for driver by license ID
        var driver = await _driverRepository.GetByLicenseId(licenseId);

        // Step 2: If no driver found, it's a fake license
        if (driver == null)
        {
            Console.WriteLine($"[DEBUG] Driver NOT FOUND in database for licenseId: '{licenseId}' - FAKE LICENSE");
            await LogVerification(licenseId, "fake", checkedByUserId);
            
            return new VerificationResponseDto
            {
                LicenseId = licenseId,
                VerificationStatus = "fake",
                DriverName = null,
                ExpiryDate = null,
                CheckedDate = DateTime.Now
            };
        }

        Console.WriteLine($"[DEBUG] Driver FOUND: {driver.FullName}, Status: {driver.Status}");

        // Step 3: Driver exists, check the Status column
        string verificationStatus;
        
        if (driver.Status.Equals("active", StringComparison.OrdinalIgnoreCase))
        {
            verificationStatus = "active";
            Console.WriteLine($"[DEBUG] License is REAL and ACTIVE");
        }
        else if (driver.Status.Equals("expired", StringComparison.OrdinalIgnoreCase))
        {
            verificationStatus = "expired";
            Console.WriteLine($"[DEBUG] License is REAL but EXPIRED");
        }
        else
        {
            // Handle other statuses (suspended, revoked, etc.) as expired
            verificationStatus = "expired";
            Console.WriteLine($"[DEBUG] License is REAL but status is: {driver.Status}");
        }

        await LogVerification(licenseId, verificationStatus, checkedByUserId);

        return new VerificationResponseDto
        {
            LicenseId = licenseId,
            VerificationStatus = verificationStatus,
            DriverName = driver.FullName,
            ExpiryDate = driver.ExpiryDate,
            CheckedDate = DateTime.Now
        };
    }

    private bool CompareQRData(string scannedQR, string storedQR)
    {
        if (string.IsNullOrWhiteSpace(scannedQR) || string.IsNullOrWhiteSpace(storedQR))
            return false;

        return scannedQR.Trim().Equals(storedQR.Trim(), StringComparison.OrdinalIgnoreCase);
    }

    private async Task LogVerification(string licenseId, string verificationStatus, int checkedByUserId)
    {
        var log = new VerificationLog
        {
            LicenseId = licenseId,
            VerificationStatus = verificationStatus,
            CheckedBy = checkedByUserId,
            CheckedDate = DateTime.Now
        };

        _context.VerificationLogs.Add(log);
        await _context.SaveChangesAsync();
    }
}
