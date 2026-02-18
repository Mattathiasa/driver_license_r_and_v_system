namespace DAFTech.DriverLicenseSystem.Api.Models.Entities;

public class Driver
{
    public int DriverId { get; set; }
    public string LicenseId { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string LicenseType { get; set; } = string.Empty;
    public DateTime ExpiryDate { get; set; }
    public string? QRRawData { get; set; }
    public string? OCRRawText { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    public int RegisteredBy { get; set; }
    public string Status { get; set; } = "active";

    // Navigation property
    public User RegisteredByUser { get; set; } = null!;
}
