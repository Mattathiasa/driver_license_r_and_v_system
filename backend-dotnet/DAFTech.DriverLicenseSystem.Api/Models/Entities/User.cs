namespace DAFTech.DriverLicenseSystem.Api.Models.Entities;

public class User
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    public string Status { get; set; } = "active";


    public ICollection<Driver> RegisteredDrivers { get; set; } = new List<Driver>();
    public ICollection<VerificationLog> VerificationLogs { get; set; } = new List<VerificationLog>();
}
