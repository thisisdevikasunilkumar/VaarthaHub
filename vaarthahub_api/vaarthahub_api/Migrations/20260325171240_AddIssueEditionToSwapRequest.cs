using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace vaarthahub_api.Migrations
{
    /// <inheritdoc />
    public partial class AddIssueEditionToSwapRequest : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "IssueEdition",
                table: "SwapRequests",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IssueEdition",
                table: "SwapRequests");
        }
    }
}
