using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace vaarthahub_api.Migrations
{
    /// <inheritdoc />
    public partial class UpdateDeliveryRatingModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DeliveryPartner",
                columns: table => new
                {
                    DeliveryPartnerId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PartnerCode = table.Column<string>(type: "nvarchar(max)", nullable: false, computedColumnSql: "'DP-' + RIGHT('000' + CAST(DeliveryPartnerId AS VARCHAR(10)), 3)"),
                    Role = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    VehicleType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    VehicleNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    LicenseNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PanchayatName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    BasicSalary = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryPartner", x => x.DeliveryPartnerId);
                });

            migrationBuilder.CreateTable(
                name: "DeliveryPartnerSalary",
                columns: table => new
                {
                    SalaryId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DeliveryPartnerId = table.Column<int>(type: "int", nullable: false),
                    BasicSalary = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    TotalCommission = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    Incentive = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    MonthYear = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TotalMonthlyEarnings = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    BasicSalaryLastUpdate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()"),
                    IncentiveLastUpdate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryPartnerSalary", x => x.SalaryId);
                });

            migrationBuilder.CreateTable(
                name: "Reader",
                columns: table => new
                {
                    ReaderId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReaderCode = table.Column<string>(type: "nvarchar(max)", nullable: false, computedColumnSql: "'R-' + RIGHT('000' + CAST(ReaderId AS VARCHAR(10)), 3)"),
                    Role = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Gender = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DateOfBirth = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PanchayatName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    WardNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AddedByPartnerCode = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reader", x => x.ReaderId);
                });

            migrationBuilder.CreateTable(
                name: "Registration",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserCode = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Role = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ProfileImage = table.Column<byte[]>(type: "varbinary(max)", nullable: true),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PasswordUpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    JoinDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Registration", x => x.UserId);
                });

            migrationBuilder.CreateTable(
                name: "DeliveryRating",
                columns: table => new
                {
                    RatingId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DeliveryPartnerId = table.Column<int>(type: "int", nullable: false),
                    ReaderId = table.Column<int>(type: "int", nullable: false),
                    RatingValue = table.Column<byte>(type: "tinyint", nullable: false),
                    FeedbackTags = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Comments = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryRating", x => x.RatingId);
                    table.ForeignKey(
                        name: "FK_DeliveryRating_DeliveryPartner_DeliveryPartnerId",
                        column: x => x.DeliveryPartnerId,
                        principalTable: "DeliveryPartner",
                        principalColumn: "DeliveryPartnerId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DeliveryRating_Reader_ReaderId",
                        column: x => x.ReaderId,
                        principalTable: "Reader",
                        principalColumn: "ReaderId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryRating_DeliveryPartnerId",
                table: "DeliveryRating",
                column: "DeliveryPartnerId");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryRating_ReaderId",
                table: "DeliveryRating",
                column: "ReaderId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeliveryPartnerSalary");

            migrationBuilder.DropTable(
                name: "DeliveryRating");

            migrationBuilder.DropTable(
                name: "Registration");

            migrationBuilder.DropTable(
                name: "DeliveryPartner");

            migrationBuilder.DropTable(
                name: "Reader");
        }
    }
}
