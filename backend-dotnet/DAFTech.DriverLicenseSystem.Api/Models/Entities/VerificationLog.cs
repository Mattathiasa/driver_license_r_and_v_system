namespace DAFTech.DriverLicenseSystem.Api.Models.Entities;

public class VerificationLog
{
    public int LogId { get; set; }
    public string LicenseId { get; set; } = string.Empty;
    public string VerificationStatus { get; set; } = string.Empty;
    public int CheckedBy { get; set; }
    public DateTime CheckedDate { get; set; } = DateTime.Now;

    // Navigation property
    public User CheckedByUser { get; set; } = null!;
}
