using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace vaarthahub_api.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryAndConditionToSwapRequest : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_SwapRequests_Reader_ReceiverReaderId",
                table: "SwapRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_SwapRequests_Reader_RequestReaderId",
                table: "SwapRequests");

            migrationBuilder.DropIndex(
                name: "IX_SwapRequests_ReceiverReaderId",
                table: "SwapRequests");

            migrationBuilder.DropIndex(
                name: "IX_SwapRequests_RequestReaderId",
                table: "SwapRequests");

            migrationBuilder.AlterColumn<int>(
                name: "ReceiverReaderId",
                table: "SwapRequests",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "SwapRequests",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Condition",
                table: "SwapRequests",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Category",
                table: "SwapRequests");

            migrationBuilder.DropColumn(
                name: "Condition",
                table: "SwapRequests");

            migrationBuilder.AlterColumn<int>(
                name: "ReceiverReaderId",
                table: "SwapRequests",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.CreateIndex(
                name: "IX_SwapRequests_ReceiverReaderId",
                table: "SwapRequests",
                column: "ReceiverReaderId");

            migrationBuilder.CreateIndex(
                name: "IX_SwapRequests_RequestReaderId",
                table: "SwapRequests",
                column: "RequestReaderId");

            migrationBuilder.AddForeignKey(
                name: "FK_SwapRequests_Reader_ReceiverReaderId",
                table: "SwapRequests",
                column: "ReceiverReaderId",
                principalTable: "Reader",
                principalColumn: "ReaderId",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_SwapRequests_Reader_RequestReaderId",
                table: "SwapRequests",
                column: "RequestReaderId",
                principalTable: "Reader",
                principalColumn: "ReaderId",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
