using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Models;

namespace vaarthahub_api.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        // Table 1: Delivery Partner details
        public DbSet<DeliveryPartner> DeliveryPartner { get; set; }

        // Table 2: Delivery Partner Salary details
        public DbSet<DeliveryPartnerSalary> DeliveryPartnerSalary { get; set; }

        // Table 3: Reader details
        public DbSet<Reader> Reader { get; set; }

        // Table 4: User Registration details
        public DbSet<Registration> Registration { get; set; }

        // Table 5: Delivery Partner Rating details
        public DbSet<DeliveryRating> DeliveryRating { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // 1. DeliveryPartner - DP-001 Auto Generation Logic
            modelBuilder.Entity<DeliveryPartner>(entity =>
            {
                // Salary precision
                entity.Property(p => p.BasicSalary).HasColumnType("decimal(10,2)");

                // Correct Computed Column Logic
                entity.Property(p => p.PartnerCode)
                      .HasComputedColumnSql("'DP-' + RIGHT('000' + CAST(DeliveryPartnerId AS VARCHAR(10)), 3)");

                // Make PartnerCode a principal/alternate key so string FKs (e.g., DeliveryRating.PartnerCode)
                // can reference it (DeliveryPartnerId is an int primary key).
                // entity.HasAlternateKey(p => p.PartnerCode);
            });

            // Reader-nu vendiyulla logic
            modelBuilder.Entity<Reader>(entity =>
            {
                entity.Property(p => p.ReaderCode)
                      .HasComputedColumnSql("'R-' + RIGHT('000' + CAST(ReaderId AS VARCHAR(10)), 3)");
            });

            // DeliveryRating -> DeliveryPartner relationship: use DeliveryPartnerId (int) as FK
            modelBuilder.Entity<DeliveryRating>(entity =>
            {
                entity.HasOne(d => d.DeliveryPartner)
                      .WithMany()
                      .HasForeignKey(d => d.DeliveryPartnerId);

                // DeliveryRating -> Reader relationship: use ReaderId (int) as FK
                entity.HasOne(d => d.Reader)
                      .WithMany()
                      .HasForeignKey(d => d.ReaderId);
            });

            // 2. DeliveryPartnerSalary Table - Decimal precision set
            modelBuilder.Entity<DeliveryPartnerSalary>(entity =>
            {
                entity.Property(e => e.BasicSalary).HasColumnType("decimal(10,2)");
                entity.Property(e => e.TotalCommission).HasColumnType("decimal(10,2)");
                entity.Property(e => e.Incentive).HasColumnType("decimal(10,2)");
                entity.Property(e => e.TotalMonthlyEarnings).HasColumnType("decimal(10,2)");
                entity.Property(e => e.BasicSalaryLastUpdate).HasDefaultValueSql("GETDATE()");
                entity.Property(e => e.IncentiveLastUpdate).HasDefaultValueSql("GETDATE()");
            });

        // --- OPTIONAL: Role check constraint for Registration table ---
        // Assuming the Role column is a string and should only allow specific values (e.g., "Reader" or "DeliveryPartner")

        /*
           modelBuilder.Entity<Registration>()
            .HasCheckConstraint("CK_Registration_Role", "[Role] IN ('Reader', 'DeliveryPartner')");
        */
        }
    }
}