#region Using

using JetBrains.Annotations;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using SmartAdmin.Seed.Configuration;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Services;
using System;
using System.IO;
using System.Threading.Tasks;

// ReSharper disable UnusedMember.Global
// ReSharper disable once ClassNeverInstantiated.Global

#endregion

namespace SmartAdmin.Seed
{
    /// <summary>
    /// Defines the startup instance used by the web host.
    /// </summary>
    [UsedImplicitly]
    public class Startup
    {
        private IConfiguration _configuration { get; }

        public Startup(IConfiguration configuration)
        {
            // Expose the injected instance locally so we populate our settings instance
            _configuration = configuration;
        }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            // Bind the settings instance as a singleton and expose it as an options type (IOptions<AppSettings>)
            // Note: This ensures that injecting both IOptions<T> and T is made possible and will resolve
            services.Configure<AppSettings>(_configuration);

            // Bind the settings instance as a singleton and expose it as an options type (IOptions<SmartSettings>)
            services.Configure<SmartSettings>(_configuration.GetSection("SmartAdmin"));

            // We retrieve the current bound AppSettings instance in order to access the connection string
            // Note: While this does performs a model binding to the type, it does not modify the service collection
            var settings = _configuration.Get<AppSettings>();

            // We need essential Mvc services and DI support to host the template pages
            services.AddMvc(x => x.EnableEndpointRouting = false).AddControllersAsServices()
                  .AddJsonOptions(options =>
                  {
                      options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
                      options.JsonSerializerOptions.PropertyNamingPolicy = null;
                  });
               

            // We allow our routes to be in lowercase
            services.AddRouting(options => options.LowercaseUrls = true);

            // We will setup this simple seeding helper to ensure default data is present
            services.AddTransient<ApplicationDbSeeder>();

            // Enable the use of SQL Server utilizing DI
           //// services.AddEntityFrameworkSqlServer();
           

            // Add the default identity classes and schema for use with EntityFramework
            services.AddIdentity<ApplicationUser, IdentityRole>().AddEntityFrameworkStores<ApplicationDbContext>().AddDefaultTokenProviders();

            services.Configure<IdentityOptions>(options =>
            {
                // Default SignIn settings.
                // Default User settings.
                options.User.AllowedUserNameCharacters =
                        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+";


                // Default Lockout settings.
              ////  options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
              ////  options.Lockout.MaxFailedAccessAttempts = 5;
              ////  options.Lockout.AllowedForNewUsers = true;



                // Default Password settings.
                ////options.Password.RequireDigit = true;
                ////options.Password.RequireLowercase = true;
                ////options.Password.RequireNonAlphanumeric = true;
                ////options.Password.RequireUppercase = true;
                ////options.Password.RequiredLength = 6;
                ////options.Password.RequiredUniqueChars = 1;


                options.SignIn.RequireConfirmedEmail = false;
                options.User.RequireUniqueEmail = true;
                options.SignIn.RequireConfirmedPhoneNumber = false;
            });
            

            //Configure the app's cookie in Startup.ConfigureServices. ConfigureApplicationCookie must be called after calling AddIdentity or AddDefaultIdentity.
            ////services.ConfigureApplicationCookie(options =>
            ////{
            ////    options.AccessDeniedPath = "/Identity/Account/AccessDenied";
            ////    options.Cookie.Name = "YourAppCookieName";
            ////    options.Cookie.HttpOnly = true;
            ////    options.ExpireTimeSpan = TimeSpan.FromMinutes(60);
            ////    options.LoginPath = "/Identity/Account/Login";
            ////    // ReturnUrlParameter requires 
            ////    //using Microsoft.AspNetCore.Authentication.Cookies;
            ////    options.ReturnUrlParameter = CookieAuthenticationDefaults.ReturnUrlParameter;
            ////    options.SlidingExpiration = true;
            ////});

            //password hash options
            ////services.Configure<PasswordHasherOptions>(option =>
            ////{
            ////    option.IterationCount = 12000;
            ////});

           // var secretKey = "FF00F0F0FF00F0F0FF00F0F0FF00F0F0";
            var configConnection = settings.ConnectionString;


            //var decryptedtext = StringCipher.DecryptString(secretKey, "hVmZ+fNFLsw6iUok4lPXjw==", configConnection);
            var decryptedtext = configConnection;
            // Enable the Context pool to manage the connections in an optimized manner
            services.AddDbContext<ApplicationDbContext>(options => options.UseSqlServer(decryptedtext));
            
            services.AddAntiforgery(options =>options.HeaderName = "MY-XSRF-TOKEN");
            //var options1 = services.BuildServiceProvider()
            //          .GetRequiredService<DbContextOptions<ApplicationDbContext>>();
            //Task.Run(() =>
            //{
            //    using (var dbContext = new ApplicationDbContext(options1))
            //    {
            //        var model = dbContext.Model; //force the model creation
            //    }
            //});


          

            // Add application services.
            services.AddTransient<IEmailSender, EmailSender>();
            services.Configure<AuthMessageSenderOptions>((options => { options.SendGridKey = settings.SendGridKey; options.SendGridUser = settings.SendGridUser; options.SendGridEmail = settings.SendGridEmail; }));

            services.Configure<AppSettingsOptions>((options => { options.HostURL = settings.HostURL; }));
            
            // Cache 200 (OK) server responses; any other responses, including error pages, are ignored.
            services.AddResponseCaching();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
      
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ApplicationDbSeeder dbSeeder)
        {
            // We detect if we are doing local development
            if (env.IsDevelopment())
            {
                // If this is the case then enable more detailed error output
                app.UseDeveloperExceptionPage();

                // Optionally enable browser link integration
               // app.UseBrowserLink();

                // Display a more specific error page when an exception occurs connecting to the database
                //app.UseDatabaseErrorPage();
            }
            else
            {
                // If this is not the case then forward the error to our generic view
                app.UseExceptionHandler("/Home/Error");
            }

            // Warning: Do not trigger this seed in your production environment, this is a security risk!
            if (!env.IsProduction())
                // Ensure we have the default user added to the store
               //// dbSeeder.EnsureSeed().GetAwaiter().GetResult();

            // Ensures we can serve static-files that should not be processed by ASP.NET
           // app.UseStaticFiles();

            app.UseStaticFiles();

            // Enable the authentication middleware so we can protect access to controllers and/or actions
            app.UseAuthentication();

            // We rely on the MVC pipeline to handle our routes
           app.UseMvcWithDefaultRoute();

          

            // Enable the reponse caching middleware to serve 200 OK responses directly from cache on sub-sequent requests
            app.UseResponseCaching();
        }
    }
}
