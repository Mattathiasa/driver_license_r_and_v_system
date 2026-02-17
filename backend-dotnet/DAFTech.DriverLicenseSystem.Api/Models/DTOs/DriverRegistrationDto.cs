using System.ComponentModel.DataAnnotations;

namespace DAFTech.DriverLicenseSystem.Api.Models.DTOs;

public class DriverRegistrationDto
{
    [Required(ErrorMessage = "License ID is required")]
    [StringLength(50, ErrorMessage = "License ID cannot exceed 50 characters")]
    public string LicenseId { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "Full name is required")]
    [StringLength(200, ErrorMessage = "Full name cannot exceed 200 characters")]
    public string FullName { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "Date of birth is required")]
    public string DateOfBirth { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "License type is required")]
    [StringLength(50, ErrorMessage = "License type cannot exceed 50 characters")]
    public string LicenseType { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "Expiry date is required")]
    public string ExpiryDate { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "QR raw data is required")]
    public string QRRawData { get; set; } = string.Empty;
    
    [Required(ErrorMessage = "OCR raw text is required")]
    public string OCRRawText { get; set; } = string.Empty;
}
