using DAFTech.DriverLicenseSystem.Api.Services;
using DAFTech.DriverLicenseSystem.Api.Repositories;
using DAFTech.DriverLicenseSystem.Api.Models.DTOs;
using DAFTech.DriverLicenseSystem.Api.Helpers;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Text;

namespace DAFTech.DriverLicenseSystem.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VerificationController : ControllerBase
{
    private readonly VerificationService _verificationService;
    private readonly VerificationLogRepository _logRepository;
    private readonly ILogger<VerificationController> _logger;

    public VerificationController(
        VerificationService verificationService,
        VerificationLogRepository logRepository,
        ILogger<VerificationController> logger)
    {
        _verificationService = verificationService;
        _logRepository = logRepository;
        _logger = logger;
    }

    [HttpPost("verify")]
    public async Task<ActionResult> VerifyLicense([FromBody] VerificationRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return ApiResponseHandler.Unauthorized("Invalid user authentication");
            }

            _logger.LogInformation("License verification attempt for license ID: {LicenseId} by user: {UserId}", 
                request.LicenseId, userId);

            var result = await _verificationService.VerifyLicense(request.LicenseId, request.QRRawData ?? "", userId);

            _logger.LogInformation("Verification completed for license ID: {LicenseId}, Status: {Status}", 
                request.LicenseId, result.VerificationStatus);

            return ApiResponseHandler.Success(result, "Verification completed");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying license ID: {LicenseId}", request.LicenseId);
            return ApiResponseHandler.Error("An error occurred during verification");
        }
    }

    [HttpGet("status/{licenseId}")]
    public async Task<ActionResult> GetLicenseStatus(string licenseId)
    {
        try
        {
            _logger.LogInformation("Status check for license ID: {LicenseId}", licenseId);

            var result = await _verificationService.VerifyLicense(licenseId, "", 0);
            
            if (result.VerificationStatus == "fake")
            {
                return ApiResponseHandler.NotFound($"No license found with ID: {licenseId}");
            }

            return ApiResponseHandler.Success(result, "Status retrieved successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking status for license ID: {LicenseId}", licenseId);
            return ApiResponseHandler.Error("An error occurred while checking status");
        }
    }

    [HttpGet("logs")]
    public async Task<ActionResult> GetVerificationLogs(
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] int? userId,
        [FromQuery] string? licenseId)
    {
        try
        {
            _logger.LogInformation("Fetching verification logs with filters");

            var logs = await _logRepository.GetAllLogs(startDate, endDate, userId, licenseId);

            var logDtos = logs.Select(l => new VerificationLogDto
            {
                LogId = l.LogId,
                LicenseId = l.LicenseId,
                VerificationStatus = l.VerificationStatus,
                CheckedBy = l.CheckedBy,
                CheckedByUsername = l.CheckedByUser?.Username ?? "Unknown",
                CheckedDate = l.CheckedDate
            }).ToList();

            return ApiResponseHandler.Success(logDtos, $"Retrieved {logDtos.Count} verification logs");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching verification logs");
            return ApiResponseHandler.Error("An error occurred while fetching logs");
        }
    }

    [HttpGet("export")]
    public async Task<IActionResult> ExportLogs()
    {
        try
        {
            var logs = await _logRepository.GetAllLogs(null, null, null, null);
            var csv = new StringBuilder();
            csv.AppendLine("LogId,LicenseId,Status,CheckedBy,CheckedDate");

            foreach (var log in logs)
            {
                var username = log.CheckedByUser?.Username ?? "Unknown";
                csv.AppendLine($"{log.LogId},{log.LicenseId},{log.VerificationStatus},{username},{log.CheckedDate:yyyy-MM-dd HH:mm:ss}");
            }

            var bytes = Encoding.UTF8.GetBytes(csv.ToString());
            return File(bytes, "text/csv", $"VerificationLogs_{DateTime.Now:yyyyMMdd}.csv");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting logs");
            return StatusCode(500, "Error exporting logs");
        }
    }
}
