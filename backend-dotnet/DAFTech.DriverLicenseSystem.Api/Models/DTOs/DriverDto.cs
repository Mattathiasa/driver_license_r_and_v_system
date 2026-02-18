namespace DAFTech.DriverLicenseSystem.Api.Models.DTOs;

public class DriverDto
{
    public int DriverId { get; set; }
    public string LicenseId { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string LicenseType { get; set; } = string.Empty;
    public DateTime ExpiryDate { get; set; }
    public string? QRRawData { get; set; }
    public string? OCRRawText { get; set; }
    public DateTime CreatedDate { get; set; }
    public int RegisteredBy { get; set; }
    public string Status { get; set; }
    public string RegisteredByUsername { get; set; }  // just a string, not User object
}
