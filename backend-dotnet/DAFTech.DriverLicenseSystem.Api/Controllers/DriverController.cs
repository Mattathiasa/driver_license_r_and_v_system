using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DAFTech.DriverLicenseSystem.Api.Models.DTOs;
using DAFTech.DriverLicenseSystem.Api.Services;
using DAFTech.DriverLicenseSystem.Api.Helpers;
using System.Security.Claims;

namespace DAFTech.DriverLicenseSystem.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DriverController : ControllerBase
{
    private readonly DriverService _driverService;
    private readonly ILogger<DriverController> _logger;

    public DriverController(
        DriverService driverService,
        ILogger<DriverController> logger)
    {
        _driverService = driverService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult> GetAllDrivers()
    {
        try
        {
            _logger.LogInformation("Fetching all drivers");

            var drivers = await _driverService.GetAllDrivers();

            return ApiResponseHandler.Success(drivers, $"Retrieved {drivers.Count()} drivers");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching all drivers");
            return ApiResponseHandler.Error("An error occurred while fetching drivers");
        }
    }


    [HttpGet("{licenseId}")]
    public async Task<ActionResult> GetDriver(string licenseId)
    {
        try
        {
            _logger.LogInformation("Fetching driver with license ID: {LicenseId}", licenseId);

            var driver = await _driverService.GetDriverByLicenseId(licenseId);

            if (driver == null)
            {
                return ApiResponseHandler.NotFound($"No driver found with license ID: {licenseId}");
            }

            return ApiResponseHandler.Success(driver, "Driver retrieved successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching driver with license ID: {LicenseId}", licenseId);
            return ApiResponseHandler.Error("An error occurred while fetching driver");
        }
    }

    [HttpPost("register")]
    public async Task<ActionResult> RegisterDriver([FromBody] DriverRegistrationDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return ApiResponseHandler.Unauthorized("Invalid user authentication");
            }

            _logger.LogInformation("Driver registration attempt for license ID: {LicenseId} by user: {UserId}",
                request.LicenseId, userId);

            // Validate the request
            if (string.IsNullOrWhiteSpace(request.LicenseId))
            {
                return ApiResponseHandler.BadRequest("License ID is required");
            }

            if (string.IsNullOrWhiteSpace(request.FullName))
            {
                return ApiResponseHandler.BadRequest("Full name is required");
            }

            if (string.IsNullOrWhiteSpace(request.ExpiryDate))
            {
                return ApiResponseHandler.BadRequest("Expiry date is required");
            }

            // Check for duplicate
            var existingDriver = await _driverService.GetDriverByLicenseId(request.LicenseId);
            if (existingDriver != null)
            {
                _logger.LogWarning("Duplicate license ID registration attempt: {LicenseId}", request.LicenseId);
                
                var status = existingDriver.Status;
                var statusMessage = status.Equals("active", StringComparison.OrdinalIgnoreCase) 
                    ? "ACTIVE" 
                    : "EXPIRED";
                
                return ApiResponseHandler.Conflict(
                    $"License ID {request.LicenseId} is already registered in the system. Status: {statusMessage}"
                );
            }

            // Register driver
            var driver = await _driverService.RegisterDriver(request, userId);

            _logger.LogInformation("Driver registered successfully with ID: {DriverId}", driver.DriverId);

            return ApiResponseHandler.Success(new { DriverId = driver.DriverId }, "Driver registered successfully");
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid data format in registration request");
            return ApiResponseHandler.BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error registering driver with license ID: {LicenseId}", request?.LicenseId ?? "unknown");
            return ApiResponseHandler.Error($"An error occurred during registration: {ex.Message}");
        }
    }

    
    [HttpGet("statistics")]
public async Task<IActionResult> GetDriverStatistics()
{
    try
    {
        _logger.LogInformation("Fetching driver statistics");
        
        // Get all drivers using your existing service
        var drivers = await _driverService.GetAllDrivers();
        
        // Count statistics
        var driversList = drivers.ToList();
        var totalDrivers = driversList.Count;
        var activeDrivers = driversList.Count(d => d.Status?.ToLower() == "active");
        var expiredDrivers = driversList.Count(d => d.Status?.ToLower() == "expired");

        _logger.LogInformation("Statistics: Total={Total}, Active={Active}, Expired={Expired}", 
            totalDrivers, activeDrivers, expiredDrivers);

        return ApiResponseHandler.Success(new
        {
            totalDrivers = totalDrivers,
            activeDrivers = activeDrivers,
            expiredDrivers = expiredDrivers
        }, "Statistics retrieved successfully");
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error fetching driver statistics");
        return ApiResponseHandler.Error("An error occurred while fetching statistics");
    }
}


}
