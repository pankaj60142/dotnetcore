using Microsoft.EntityFrameworkCore.Migrations;
using System;
using System.Collections.Generic;

namespace SmartAdmin.Seed.Data.Migrations
{
    public partial class User_CompanyId_CompanyName : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CountryId",
                table: "AspNetUsers");
            migrationBuilder.DropColumn(
               name: "CountryName",
               table: "AspNetUsers");

            migrationBuilder.AddColumn<string>(
               name: "ComapnyId",
               table: "AspNetUsers",
               nullable: true);


            migrationBuilder.AddColumn<string>(
              name: "ComapnyName",
               table: "AspNetUsers",
               nullable: true);

        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            

            migrationBuilder.AddColumn<string>(
                name: "ComapnyId",
                table: "AspNetUsers",
                nullable: true);
       

        migrationBuilder.AddColumn<string>(
               name: "ComapnyName",
                table: "AspNetUsers",
                nullable: true);
        }
}
}
