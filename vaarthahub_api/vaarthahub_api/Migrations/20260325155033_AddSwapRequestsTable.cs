using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace vaarthahub_api.Migrations
{
    /// <inheritdoc />
    public partial class AddSwapRequestsTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SwapRequests",
                columns: table => new
                {
                    SwapId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RequestReaderId = table.Column<int>(type: "int", nullable: false),
                    ReceiverReaderId = table.Column<int>(type: "int", nullable: true),
                    OfferedMagazine = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    RequestedMagazine = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    MagazinePrice = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    RequestedMagazinePrice = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    ServiceFee_Requestor = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    ServiceFee_Receiver = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    TotalServiceFee = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    AcceptedByPartnerCode = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SwapRequests", x => x.SwapId);
                    table.ForeignKey(
                        name: "FK_SwapRequests_Reader_ReceiverReaderId",
                        column: x => x.ReceiverReaderId,
                        principalTable: "Reader",
                        principalColumn: "ReaderId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SwapRequests_Reader_RequestReaderId",
                        column: x => x.RequestReaderId,
                        principalTable: "Reader",
                        principalColumn: "ReaderId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SwapRequests_ReceiverReaderId",
                table: "SwapRequests",
                column: "ReceiverReaderId");

            migrationBuilder.CreateIndex(
                name: "IX_SwapRequests_RequestReaderId",
                table: "SwapRequests",
                column: "RequestReaderId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SwapRequests");
        }
    }
}
