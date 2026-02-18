using Microsoft.EntityFrameworkCore;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;

namespace DAFTech.DriverLicenseSystem.Api.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Driver> Drivers { get; set; } = null!;
    public DbSet<VerificationLog> VerificationLogs { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User entity
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(e => e.UserId);
            entity.Property(e => e.UserId).HasColumnName("UserID");
            
            entity.Property(e => e.Username)
                .IsRequired()
                .HasMaxLength(50);
            
            entity.HasIndex(e => e.Username)
                .IsUnique();
            
            entity.Property(e => e.PasswordHash)
                .IsRequired()
                .HasMaxLength(255);
            
            entity.Property(e => e.CreatedDate)
                .IsRequired()
                .HasDefaultValueSql("GETDATE()");
            
            entity.Property(e => e.Status)
                .IsRequired()
                .HasMaxLength(20)
                .HasDefaultValue("active");

            // Configure relationships
            entity.HasMany(e => e.RegisteredDrivers)
                .WithOne(d => d.RegisteredByUser)
                .HasForeignKey(d => d.RegisteredBy)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(e => e.VerificationLogs)
                .WithOne(v => v.CheckedByUser)
                .HasForeignKey(v => v.CheckedBy)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure Driver entity
        modelBuilder.Entity<Driver>(entity =>
        {
            entity.ToTable("Drivers");
            entity.HasKey(e => e.DriverId);
            entity.Property(e => e.DriverId).HasColumnName("DriverID");
            
            entity.Property(e => e.LicenseId)
                .IsRequired()
                .HasMaxLength(50)
                .HasColumnName("LicenseID");
            
            entity.HasIndex(e => e.LicenseId)
                .IsUnique();
            
            entity.Property(e => e.FullName)
                .IsRequired()
                .HasMaxLength(100);
            
            entity.Property(e => e.LicenseType)
                .IsRequired()
                .HasMaxLength(10);
            
            entity.Property(e => e.ExpiryDate)
                .IsRequired()
                .HasColumnType("date");
            
            entity.Property(e => e.QRRawData)
                .HasColumnType("nvarchar(max)");
            
            entity.Property(e => e.OCRRawText)
                .HasColumnType("nvarchar(max)");
            
            entity.Property(e => e.CreatedDate)
                .IsRequired()
                .HasDefaultValueSql("GETDATE()");
            
            entity.Property(e => e.RegisteredBy)
                .IsRequired();

            entity.HasIndex(e => e.RegisteredBy);
        });

        // Configure VerificationLog entity
        modelBuilder.Entity<VerificationLog>(entity =>
        {
            entity.ToTable("VerificationLogs");
            entity.HasKey(e => e.LogId);
            entity.Property(e => e.LogId).HasColumnName("LogID");
            
            entity.Property(e => e.LicenseId)
                .IsRequired()
                .HasMaxLength(50)
                .HasColumnName("LicenseID");
            
            entity.Property(e => e.VerificationStatus)
                .IsRequired()
                .HasMaxLength(20);
            
            entity.Property(e => e.CheckedBy)
                .IsRequired();
            
            entity.Property(e => e.CheckedDate)
                .IsRequired()
                .HasDefaultValueSql("GETDATE()");

            entity.HasIndex(e => e.LicenseId);
            entity.HasIndex(e => e.CheckedBy);
            entity.HasIndex(e => e.CheckedDate);
        });
    }
}
