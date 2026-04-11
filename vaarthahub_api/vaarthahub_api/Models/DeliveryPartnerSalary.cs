using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class DeliveryPartnerSalary
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int SalaryId { get; set; }

    [ForeignKey("DeliveryPartner")]
    public int DeliveryPartnerId { get; set; }

    [Column(TypeName = "decimal(10, 2)")]
    public decimal BasicSalary { get; set; }

    [Column(TypeName = "decimal(10, 2)")]
    public decimal TotalCommission { get; set; } = 0;

    [Column(TypeName = "decimal(10, 2)")]
    public decimal Incentive { get; set; } = 0;

    public string MonthYear { get; set; } = string.Empty;

    [Column(TypeName = "decimal(10, 2)")]
    public decimal TotalMonthlyEarnings { get; set; }

    public DateTime BasicSalaryLastUpdate { get; set; } = DateTime.Now;
    public DateTime IncentiveLastUpdate { get; set; } = DateTime.Now;
}