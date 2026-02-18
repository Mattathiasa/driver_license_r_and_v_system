namespace DAFTech.DriverLicenseSystem.Api.Models.DTOs;

public class DriverResponseDto
{
    public int DriverId { get; set; }
    public string LicenseId { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string LicenseType { get; set; } = string.Empty;
    public DateTime ExpiryDate { get; set; }
    public string? QRRawData { get; set; }
    public string? OCRRawText { get; set; }
    public DateTime CreatedDate { get; set; }
    public string RegisteredBy { get; set; } = string.Empty;
}
