using System;

namespace vaarthahub_api.DTOs
{
    public class DeliveryPartnerSalaryDto
    {
        public int DeliveryPartnerId { get; set; }
        public decimal BasicSalary { get; set; }
        public decimal TotalCommission { get; set; }
        public decimal Incentive { get; set; }
        public string MonthYear { get; set; } = string.Empty;
        public decimal TotalMonthlyEarnings { get; set; }
        public DateTime BasicSalaryLastUpdate { get; set; }
        public DateTime IncentiveLastUpdate { get; set; }
        public double AverageRating { get; set; }
        public int RatingCount { get; set; }
    }
}