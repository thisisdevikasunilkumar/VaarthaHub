using System;
using System.Collections.Generic;

namespace vaarthahub_api.DTOs
{
    public class SetVacationDto
    {
        public int ReaderId { get; set; }
        public List<int> SubscriptionIds { get; set; } = new List<int>();
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
