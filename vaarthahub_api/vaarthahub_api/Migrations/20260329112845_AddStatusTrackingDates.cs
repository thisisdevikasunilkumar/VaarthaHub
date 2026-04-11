using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace vaarthahub_api.Migrations
{
    /// <inheritdoc />
    public partial class AddStatusTrackingDates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DeliveredDate",
                table: "OtherProductBookings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ShippedDate",
                table: "OtherProductBookings",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveredDate",
                table: "OtherProductBookings");

            migrationBuilder.DropColumn(
                name: "ShippedDate",
                table: "OtherProductBookings");
        }
    }
}
