namespace DAFTech.DriverLicenseSystem.Api.Models.DTOs;

public class VerificationLogDto
{
    public int LogId { get; set; }
    public string LicenseId { get; set; } = string.Empty;
    public string VerificationStatus { get; set; } = string.Empty;
    public int CheckedBy { get; set; }
    public string CheckedByUsername { get; set; } = string.Empty;
    public DateTime CheckedDate { get; set; }
}
