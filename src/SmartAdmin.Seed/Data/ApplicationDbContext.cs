#region Using

using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.Entities;

#endregion

namespace SmartAdmin.Seed.Data
{
    /// <summary>
    ///     Defines the Entity Framework database context instance used by the application.
    /// </summary>
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {

        public DbSet<AspNetCompany> AspNetCompany { get; set; }



        public DbSet<lkpCountry> lkpCountry { get; set; }
        public DbSet<lkpState> lkpState { get; set; }
        public DbSet<lkpAllCountries> lkpAllCountries { get; set; }
        public DbSet<lkpAllStates> lkpAllStates { get; set; }
        public DbSet<lkpAllCities> lkpAllCities { get; set; }
        public DbSet<lkpCity> lkpCity { get; set; }
        public DbSet<lkpDataCenter> lkpDataCenter { get; set; }
        public DbSet<lkpDepartment> lkpDepartment { get; set; }
        public DbSet<lkpApplication> lkpApplication { get; set; }
        public DbSet<Authorization_AllowedCountries> Authorization_AllowedCountries { get; set; }
        public DbSet<Authorization_AllowedStates> Authorization_AllowedStates { get; set; }
        public DbSet<Authorization_AllowedCities> Authorization_AllowedCities { get; set; }
        public DbSet<Authorization_AllowedApplications> Authorization_AllowedApplications { get; set; }

        public DbSet<Authorization_AllowedDatacenters> Authorization_AllowedDatacenters { get; set; }
        public DbSet<Authorization_AllowedDepartments> Authorization_AllowedDepartments { get; set; }
        public DbSet<Databases> Databases { get; set; }
        public DbSet<DatabaseDocument> databaseDocument { get; set; }
        public DbSet<DatabaseDocument> databaseDocuments { get; set; }
        public DbSet<Document> Document { get; set; }
        public DbSet<Server> Server { get; set; }
        public DbSet<lkpDBA> lkpDBA { get; set; }
        public DbSet<lkpSAN> lkpSAN { get; set; }
        public DbSet<lkpSANSwitchName> lkpSANSwitchName { get; set; }
        public DbSet<lkpSANSwitchPort> lkpSANSwitchPort { get; set; }
        public DbSet<lkpFibreBackup> lkpFibreBackup { get; set; }
        public DbSet<lkpFibreSwitchName> lkpFibreSwitchName { get; set; }
        public DbSet<lkpFibreSwitchPort> lkpFibreSwitchPort { get; set; }
        public DbSet<lkpClusterType> lkpClusterType { get; set; }
        public DbSet<lkpLocation> lkpLocation { get; set; }
        public DbSet<lkpITGroup> lkpITGroup { get; set; }
        public DbSet<lkpNetworkType> lkpNetworkType { get; set; }
        public DbSet<lkpServerType> lkpServerType { get; set; }
        public DbSet<lkpVHost> lkpVHost { get; set; }
        public DbSet<Application> Application { get; set; }
        public DbSet<ApplicationDatabase> ApplicationDatabase { get; set; }

        public DbSet<serverdocument> serverdocument { get; set; }
        public DbSet<serverdatabase> serverdatabase { get; set; }
        public DbSet<Framework_Server_Location> framework_Server_Location { get; set; }
        public DbSet<GGPDeveloper> ggpDeveloper { get; set; }
        public DbSet<lkpInstaller> lkpInstaller { get; set; }
        public DbSet<ADGroup> ADGroup { get; set; }
        public DbSet<Contact> Contact { get; set; }
        public DbSet<ApplicationDocument> applicationDocument { get; set; }
        public DbSet<ApplicationDatabase> applicationDatabases { get; set; }
        public DbSet<framework_applicationlocation> framework_Applicationlocation { get; set; }
        public DbSet<ApplicationADGroup> ApplicationADGroup { get; set; }
        public DbSet<Framework_Databases_Location> Framework_Databases_Location { get; set; }

        public DbSet<Tbl_ErrorLog> Tbl_ErrorLog { get; set; }

        public DbSet<ApplicationDiagram> ApplicationDiagram { get; set; }
        public DbSet<ApplicationDiagramDetail> ApplicationDiagramDetail { get; set; }

        public DbSet<Report_TableInfo> Report_TableInfo { get; set; }
        public DbSet<Report_ColumnInfo> Report_ColumnInfo { get; set; }


        public DbSet<tblDesignerTree> tblDesignerTree { get; set; }
        public DbSet<tblSharedFolderWithUser> tblSharedFolderWithUser { get; set; }

        public DbSet<tblSharedApplicationWithUser> tblSharedApplicationWithUser { get; set; }
        

        public DbSet<tblApplicationDesignerDiagram> tblApplicationDesignerDiagram { get; set; }

        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        /// <summary>
        ///     Configures the schema needed for the application identity framework.
        /// </summary>
        /// <param name="builder">The builder being used to construct the model for this application context.</param>
        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Customize the ASP.NET Identity model and override the defaults if needed.
            // For example, you can rename the ASP.NET Identity table names and more.
            // Add your customizations after calling base.OnModelCreating(builder);
        }
    }
}
