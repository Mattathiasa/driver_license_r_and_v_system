using DAFTech.DriverLicenseSystem.Api.Data;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace DAFTech.DriverLicenseSystem.Api.Repositories;

public class VerificationLogRepository
{
    private readonly ApplicationDbContext _context;

    public VerificationLogRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<VerificationLog> CreateAsync(VerificationLog log)
    {
        _context.VerificationLogs.Add(log);
        await _context.SaveChangesAsync();
        return log;
    }

    public async Task<List<VerificationLog>> GetAllLogs(
        DateTime? startDate, 
        DateTime? endDate, 
        int? userId, 
        string? licenseId)
    {
        var query = _context.VerificationLogs
            .Include(l => l.CheckedByUser)
            .AsQueryable();

        if (startDate.HasValue && endDate.HasValue)
        {
            query = query.Where(l => l.CheckedDate >= startDate.Value && l.CheckedDate <= endDate.Value);
        }

        if (userId.HasValue)
        {
            query = query.Where(l => l.CheckedBy == userId.Value);
        }

        if (!string.IsNullOrEmpty(licenseId))
        {
            query = query.Where(l => l.LicenseId == licenseId);
        }

        return await query.OrderByDescending(l => l.CheckedDate).ToListAsync();
    }

    public async Task<List<VerificationLog>> GetByLicenseIdAsync(string licenseId)
    {
        return await _context.VerificationLogs
            .Where(l => l.LicenseId == licenseId)
            .OrderByDescending(l => l.CheckedDate)
            .ToListAsync();
    }
}
