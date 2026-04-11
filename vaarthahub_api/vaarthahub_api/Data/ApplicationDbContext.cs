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

        // Table 6: Design frame details
        public DbSet<DesignFrame> DesignFrames { get; set; }

        // Table 7: Complaints
        public DbSet<Complaint> Complaints { get; set; }

        // Table 8: Newspapers & Magazines
        public DbSet<Newspaper> Newspapers { get; set; }
        public DbSet<Magazine> Magazines { get; set; }

        // Table 9: Swap Requests
        public DbSet<SwapRequest> SwapRequests { get; set; }
        public DbSet<SwapProposal> SwapProposals { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Subscription> Subscriptions { get; set; }
        public DbSet<VacationRequest> VacationRequests { get; set; }
        
        // Table 10: Other Products (Calendar, Diary, etc.)
        public DbSet<OtherProduct> OtherProducts { get; set; }
        public DbSet<OtherProductBooking> OtherProductBookings { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // 1. DeliveryPartner - Auto Generation Logic
            modelBuilder.Entity<DeliveryPartner>(entity =>
            {
                entity.Property(p => p.BasicSalary).HasColumnType("decimal(10,2)");
                entity.Property(p => p.PartnerCode)
                      .HasComputedColumnSql("'DP-' + RIGHT('000' + CAST(DeliveryPartnerId AS VARCHAR(10)), 3)");
            });

            // 2. Reader - Auto Generation Logic
            modelBuilder.Entity<Reader>(entity =>
            {
                entity.Property(p => p.ReaderCode)
                      .HasComputedColumnSql("'R-' + RIGHT('000' + CAST(ReaderId AS VARCHAR(10)), 3)");
            });

            // 3. DeliveryPartnerSalary - Decimal precision
            modelBuilder.Entity<DeliveryPartnerSalary>(entity =>
            {
                entity.Property(e => e.BasicSalary).HasColumnType("decimal(10,2)");
                entity.Property(e => e.TotalCommission).HasColumnType("decimal(10,2)");
                entity.Property(e => e.Incentive).HasColumnType("decimal(10,2)");
                entity.Property(e => e.TotalMonthlyEarnings).HasColumnType("decimal(10,2)");
                entity.Property(e => e.BasicSalaryLastUpdate).HasDefaultValueSql("GETDATE()");
                entity.Property(e => e.IncentiveLastUpdate).HasDefaultValueSql("GETDATE()");
            });

            // 4. DesignFrame
            modelBuilder.Entity<DesignFrame>(entity =>
            {
                entity.ToTable("DesignFrames");
                entity.Property(e => e.Price).HasColumnType("decimal(10,2)");
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()");
            });

            // 5. OtherProduct - Decimal precision
            modelBuilder.Entity<OtherProduct>(entity =>
            {
                entity.ToTable("OtherProducts");
                entity.Property(e => e.UnitPrice).HasColumnType("decimal(10,2)");
            });

            // 6. OtherProductBooking - Decimal precision
            modelBuilder.Entity<OtherProductBooking>(entity =>
            {
                entity.Property(e => e.TotalAmount).HasColumnType("decimal(10,2)");
            });
            // 7. VacationRequest - Prevent cascade delete cycles
            modelBuilder.Entity<VacationRequest>()
                .HasOne(v => v.Reader)
                .WithMany()
                .HasForeignKey(v => v.ReaderId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<VacationRequest>()
                .HasOne(v => v.Subscription)
                .WithMany()
                .HasForeignKey(v => v.SubscriptionId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}