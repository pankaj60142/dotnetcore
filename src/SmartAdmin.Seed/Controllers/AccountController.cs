#region Using

using System;
using System.Linq;
using System.Security.Claims;
using System.Text.Encodings.Web;
using System.Threading.Tasks;
using JetBrains.Annotations;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Extensions;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.AccountViewModels;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Services;
using static SmartAdmin.Seed.Controllers.ConfirmationController;

#endregion

namespace SmartAdmin.Seed.Controllers
{
    [Authorize]
    [Route("[controller]/[action]")]
    [Layout("_AuthLayout")]
    public class AccountController : Controller
    {
        private readonly IEmailSender _emailSender;
        private readonly ILogger _logger;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly ApplicationDbContext _context;
        Tbl_ErrorLog errorLog = new Tbl_ErrorLog();

        [TempData]
        [UsedImplicitly]
        public string ErrorMessage { get; set; }

        public AccountController(UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager, RoleManager<IdentityRole> roleManager, IEmailSender emailSender, ILogger<AccountController> logger, ApplicationDbContext context)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _roleManager = roleManager;
            _emailSender = emailSender;
            _logger = logger;
            _context = context;


        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> Login(string returnUrl = null)
        {
            // Clear the existing external cookie to ensure a clean login process
            await HttpContext.SignOutAsync(IdentityConstants.ExternalScheme);

            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model, string returnUrl = null)
        {
            try {
                ViewData["ReturnUrl"] = returnUrl;
                if (ModelState.IsValid)
                {
                    //var companyfound = (from c in _context.AspNetCompany where c.CompanyName.ToLower() == model.CompanyName.ToLower() select c).FirstOrDefault();
                    //if (companyfound == null)
                    //{
                    //    ModelState.AddModelError(string.Empty, "Company does not exist.");
                    //    return View(model);
                    //}
                    //else if (companyfound.IsActive == false)
                    //{
                    //    ModelState.AddModelError(string.Empty, "Company exists,but is InActive .. Please contact system administrator");
                    //    return View(model);
                    //}
                    //if (companyfound == null)
                    //{
                    //    ModelState.AddModelError(string.Empty, "Company does not exist.");
                    //    return View(model);
                    //}
                    Task<ApplicationUser> userAwaiter = _userManager.FindByEmailAsync(model.Email);
                    ApplicationUser tUser = await userAwaiter;
                    if (tUser == null)
                    {
                        ModelState.AddModelError(string.Empty, "User does not exist..");
                        return View(model);
                    }


                    if (tUser.EmailConfirmed==false)
                    {
                        ModelState.AddModelError(string.Empty, "User exists,but account is not verified, Please check your email and verify account");
                        return View(model);
                    }


                    //if (tUser.CompanyName.ToLower() != companyfound.CompanyName.ToLower())
                    //{
                    //    ModelState.AddModelError(string.Empty, "User does not exist against " + model.CompanyName);
                    //    return View(model);
                    //}

                    //////// This doesn't count login failures towards account lockout
                    //////// To enable password failures to trigger account lockout, set lockoutOnFailure: true
                    var result = await _signInManager.PasswordSignInAsync(model.Email, model.Password, model.RememberMe, lockoutOnFailure: false);



                    if (result.Succeeded)
                    {




                        _logger.LogInformation("User logged in.");
                        return RedirectToLocal(returnUrl);
                    }
                    if (result.RequiresTwoFactor)
                    {
                        return RedirectToAction(nameof(LoginWith2fa), new
                        {
                            returnUrl,
                            model.RememberMe
                        });
                    }
                    if (result.IsLockedOut)
                    {
                        _logger.LogWarning("User account locked out.");
                        return RedirectToAction(nameof(Lockout));
                    }

                    if (result.IsNotAllowed)
                    {

                        ModelState.AddModelError(string.Empty, "Please contact with site administrator to confirm your account.");
                        return View(model);
                    }


                    ModelState.AddModelError(string.Empty, "Invalid login attempt.");
                    return View(model);
                }
                else if (ModelState.ErrorCount > 0)
                {
                    foreach (var modelState in ViewData.ModelState.Values)
                    {
                        foreach (var error in modelState.Errors)
                        {
                            ModelState.AddModelError(string.Empty, error.ErrorMessage);
                        }
                    }
                    return View(model);
                }


                // If we got this far, something failed, redisplay form
                return View(model);
            }
            catch(Exception ex)
            {
                //-----Save to log--------------------------

                errorLog.Logdescription = ex.Message;
                errorLog.ProcedureName = "Login";
                errorLog.FormName = "Login";
                errorLog.TransactionTime = DateTime.Now;

                _context.Tbl_ErrorLog.Add(errorLog);
                _context.SaveChanges();

                return View(model);
                //-----Save to log--------------------------
                //var json = JsonConvert.SerializeObject(ex.Message);
                //return new JsonStringResult(json);
            }

        }

        [HttpPost]
        [AllowAnonymous]
        public JsonStringResult GetCompanyId(string CompanyName)
        {
           
            try
            {

                if (CompanyName == null)
                {
                    var result = (from s in _context.AspNetCompany
                                  where s.CompanyId == 18
                                  select s
                                         ).ToList();

                    //var result = (from s in _context.AspNetCompany
                    //              where s.CompanyId == 19
                    //              select s
                    //                   ).ToList();

                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);


                }
                else
                {
                    var result = (from s in _context.AspNetCompany
                                  where s.CompanyName == CompanyName
                                  select s
                                             ).ToList();
                    if (result.Count == 0)
                    {
                        errorLog.Logdescription = "Company Doesn't Exists(" + CompanyName + ")";
                        errorLog.ProcedureName = "GetCompanyId";
                        errorLog.TransactionTime = DateTime.Now;
                        errorLog.FormName = "Login";
                        _context.Tbl_ErrorLog.Add(errorLog);
                        _context.SaveChanges();
                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);

                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);
                    }
                }
            }
            catch (Exception ex)
            {
                string message = "Fail.." + ex.Message;

                //-----Save to log--------------------------
                
                 errorLog.Logdescription=ex.Message;
                errorLog.ProcedureName = "GetCompanyId";
                errorLog.FormName = "Login";
                errorLog.TransactionTime = DateTime.Now;

                _context.Tbl_ErrorLog.Add(errorLog);
                _context.SaveChanges();
                //-----Save to log--------------------------

                JsonError je = new JsonError();
                je.CompanyId = -1;
                var json = JsonConvert.SerializeObject(je);
                return new JsonStringResult(json);

            }
           
        }

      

        [HttpGet]
        [AllowAnonymous]
        async Task<int> DummyLogin()
        {
            await Task.Delay(500); // 1 second delay
            return 1;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> LoginWith2fa(bool rememberMe, string returnUrl = null)
        {
            // Ensure the user has gone through the username & password screen first
            var user = await _signInManager.GetTwoFactorAuthenticationUserAsync();

            if (user == null)
            {
                throw new ApplicationException("Unable to load two-factor authentication user.");
            }

            var model = new LoginWith2faViewModel
            {
                RememberMe = rememberMe
            };
            ViewData["ReturnUrl"] = returnUrl;

            return View(model);
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> LoginWith2fa(LoginWith2faViewModel model, bool rememberMe, string returnUrl = null)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = await _signInManager.GetTwoFactorAuthenticationUserAsync();
            if (user == null)
            {
                throw new ApplicationException($"Unable to load user with ID '{_userManager.GetUserId(User)}'.");
            }

            var authenticatorCode = model.TwoFactorCode.Replace(" ", string.Empty).Replace("-", string.Empty);

            var result = await _signInManager.TwoFactorAuthenticatorSignInAsync(authenticatorCode, rememberMe, model.RememberMachine);

            if (result.Succeeded)
            {
                _logger.LogInformation("User with ID {UserId} logged in with 2fa.", user.Id);
                return RedirectToLocal(returnUrl);
            }
            if (result.IsLockedOut)
            {
                _logger.LogWarning("User with ID {UserId} account locked out.", user.Id);
                return RedirectToAction(nameof(Lockout));
            }
            _logger.LogWarning("Invalid authenticator code entered for user with ID {UserId}.", user.Id);
            ModelState.AddModelError(string.Empty, "Invalid authenticator code.");
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> LoginWithRecoveryCode(string returnUrl = null)
        {
            // Ensure the user has gone through the username & password screen first
            var user = await _signInManager.GetTwoFactorAuthenticationUserAsync();
            if (user == null)
            {
                throw new ApplicationException("Unable to load two-factor authentication user.");
            }

            ViewData["ReturnUrl"] = returnUrl;

            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> LoginWithRecoveryCode(LoginWithRecoveryCodeViewModel model, string returnUrl = null)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = await _signInManager.GetTwoFactorAuthenticationUserAsync();
            if (user == null)
            {
                throw new ApplicationException("Unable to load two-factor authentication user.");
            }

            var recoveryCode = model.RecoveryCode.Replace(" ", string.Empty);

            var result = await _signInManager.TwoFactorRecoveryCodeSignInAsync(recoveryCode);

            if (result.Succeeded)
            {
                _logger.LogInformation("User with ID {UserId} logged in with a recovery code.", user.Id);
                return RedirectToLocal(returnUrl);
            }
            if (result.IsLockedOut)
            {
                _logger.LogWarning("User with ID {UserId} account locked out.", user.Id);
                return RedirectToAction(nameof(Lockout));
            }
            _logger.LogWarning("Invalid recovery code entered for user with ID {UserId}", user.Id);
            ModelState.AddModelError(string.Empty, "Invalid recovery code entered.");
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Lockout()
        {
            return View();
        }



        [HttpGet]
        [AllowAnonymous]
        public IActionResult Register(string returnUrl = null)
        {


            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(RegisterViewModel model, string returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Select(x => x.Value.Errors)
                        .Where(y => y.Count > 0)
                        .ToList();

                return View(model);
            }


            //var alreadyfound = (from u in _context.Users where u.CompanyName == model.CompanyName || u.Email == model.Email select u).FirstOrDefault();
            //if (alreadyfound != null)
            //{
            //    ModelState.AddModelError(string.Empty, "Company or user email already exists");
            //    return View(model);

            //}

            var alreadyfound = (from u in _context.Users where  u.Email == model.Email select u).FirstOrDefault();
            if (alreadyfound != null)
            {

           

                var code = await _userManager.GenerateEmailConfirmationTokenAsync(alreadyfound);
                var callbackUrl = Url.EmailConfirmationLink(alreadyfound.Id, code, Request.Scheme);

                var res = await _emailSender.SendEmailAsync(model.Email, "Hello New User,",
                $" <b>Hi,</b> <br/> <br/> <br/> Thank you for registering to your path to creation. <br/><br/><br/> <a class='btn btn-info' href='{HtmlEncoder.Default.Encode(callbackUrl)}'>Click here</a><br/><br/>Thank you,<br/>Sales Team <br/><br/><img src='cid:imgLogo' width='100' height='80' style='width:100px;height80px;'/>");




                ModelState.AddModelError(string.Empty, "User email already exists");
                return View(model);

            }

            AspNetCompany company = new AspNetCompany();
            company.CompanyName = model.CompanyName;
            company.AllowedModules = string.Join(",", model.AllowedModules);
            company.IsActive = true;
            _context.AspNetCompany.Add(company);

            try
            {
                _context.SaveChanges();

                var user = new ApplicationUser
                {
                    UserName = model.Email,
                    Email = model.Email,

                    FirstName = model.FirstName,
                    LastName = model.LastName,
                    // CompanyName = model.CompanyName,
                    //CompanyId = company.CompanyId

                    CompanyName = "Public Consulting Group",
                    CompanyId = 18

                    //CompanyName = "softpro",
                    //CompanyId = 19
                };

                var result = await _userManager.CreateAsync(user, model.Password);

                if (result.Succeeded)
                {
                    _logger.LogInformation("User created a new account with password.");
                 
                    var code = await _userManager.GenerateEmailConfirmationTokenAsync(user);
                    var callbackUrl = Url.EmailConfirmationLink(user.Id, code, Request.Scheme);

                var res=   await _emailSender.SendEmailAsync(model.Email, "Confirm your email",
                $" <b>Hi,</b> <br/> <br/> <br/> Thank you for registering to your path to build atlas for your enterprise <br/><br/><br/> <a class='btn btn-info' href='{HtmlEncoder.Default.Encode(callbackUrl)}'><b>Confirm your account</b></a>");

                    if (res == true)
                    {
                        ModelState.AddModelError(string.Empty, "Almost done... Please check your email to activate your account.");
                    }
                    else
                    {
                        ModelState.AddModelError(string.Empty, "Error... Account created successfully,but could not send email");
                    }
                    // await _signInManager.SignInAsync(user, isPersistent: false);
                    // _logger.LogInformation("User created a new account with password.");
                    // return RedirectToLocal(returnUrl);
                }

                AddErrors(result);
            }
            catch (Exception)
            {
                ModelState.AddModelError(string.Empty, "Could not create account , Unkown Error occured");

            }




            // If we got this far, something failed, redisplay form
            return View(model);
        }

      


        [HttpGet]
        public IActionResult CreateDefaultRoles()
        {



            return View();
        }

        [HttpPost]
        public async Task<ActionResult> SaveRoles(int RoleId)
        {

            try
            {
                _context.Roles.RemoveRange(_context.Roles);
                _context.SaveChanges();


                var roleAdmin = new IdentityRole();
                roleAdmin.Name = "Admin";
                await _roleManager.CreateAsync(roleAdmin);

                var roleCountry = new IdentityRole();
                roleCountry.Name = "Country";
                await _roleManager.CreateAsync(roleCountry);



                var roleDataCenter = new IdentityRole();
                roleDataCenter.Name = "DataCenter";
                await _roleManager.CreateAsync(roleDataCenter);

                var roleDepartment = new IdentityRole();
                roleDepartment.Name = "Department";
                await _roleManager.CreateAsync(roleDepartment);


                var roleApplication = new IdentityRole();
                roleApplication.Name = "Application";
                await _roleManager.CreateAsync(roleApplication);



                return new JsonStringResult("SUCCESS");

            }
            catch (Exception)
            {
                return new JsonStringResult("Errors occured while saving roles");

            }




        }



        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            try
            {
                await _signInManager.SignOutAsync();
                _logger.LogInformation("User logged out.");
                return RedirectToAction(nameof(HomeController.Index), "Home");
            }
            catch(Exception ex)
            {
                //-----Save to log--------------------------
                
                errorLog.Logdescription = ex.Message;
                errorLog.ProcedureName = "Logout";
                errorLog.FormName = "Login";
                errorLog.TransactionTime = DateTime.Now;

                _context.Tbl_ErrorLog.Add(errorLog);
                _context.SaveChanges();
                //-----Save to log--------------------------

                var json = JsonConvert.SerializeObject(ex.Message);
                return new JsonStringResult(json);
            }
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public IActionResult ExternalLogin(string provider, string returnUrl = null)
        {
            // Request a redirect to the external login provider.
            var redirectUrl = Url.Action(nameof(ExternalLoginCallback), "Account", new
            {
                returnUrl
            });
            var properties = _signInManager.ConfigureExternalAuthenticationProperties(provider, redirectUrl);
            return Challenge(properties, provider);
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> ExternalLoginCallback(string returnUrl = null, string remoteError = null)
        {
            if (remoteError != null)
            {
                ErrorMessage = $"Error from external provider: {remoteError}";
                //return RedirectToAction(nameof(Login));
            }
            var info = await _signInManager.GetExternalLoginInfoAsync();
            if (info == null)
            {
                //  return RedirectToAction(nameof(Login));
            }

            // Sign in the user with this external login provider if the user already has a login.
            var result = await _signInManager.ExternalLoginSignInAsync(info.LoginProvider, info.ProviderKey, isPersistent: false, bypassTwoFactor: true);
            if (result.Succeeded)
            {
                _logger.LogInformation("User logged in with {Name} provider.", info.LoginProvider);
                return RedirectToLocal(returnUrl);
            }
            if (result.IsLockedOut)
            {
                return RedirectToAction(nameof(Lockout));
            }
            // If the user does not have an account, then ask the user to create an account.
            ViewData["ReturnUrl"] = returnUrl;
            ViewData["LoginProvider"] = info.LoginProvider;
            var email = info.Principal.FindFirstValue(ClaimTypes.Email);
            return View("ExternalLogin", new ExternalLoginViewModel
            {
                Email = email
            });
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ExternalLoginConfirmation(ExternalLoginViewModel model, string returnUrl = null)
        {
            if (ModelState.IsValid)
            {
                // Get the information about the user from the external login provider
                var info = await _signInManager.GetExternalLoginInfoAsync();
                if (info == null)
                {
                    throw new ApplicationException("Error loading external login information during confirmation.");
                }
                var user = new ApplicationUser
                {
                    UserName = model.Email,
                    Email = model.Email
                };
                var result = await _userManager.CreateAsync(user);
                if (result.Succeeded)
                {
                    result = await _userManager.AddLoginAsync(user, info);
                    if (result.Succeeded)
                    {
                        await _signInManager.SignInAsync(user, isPersistent: false);
                        _logger.LogInformation("User created an account using {Name} provider.", info.LoginProvider);
                        return RedirectToLocal(returnUrl);
                    }
                }
                AddErrors(result);
            }

            ViewData["ReturnUrl"] = returnUrl;
            return View(nameof(ExternalLogin), model);
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> ConfirmEmail(string userId, string code)
        {
            if (userId == null || code == null)
            {
                return RedirectToAction(nameof(HomeController.Index), "Home");
            }



            var user = await _userManager.FindByIdAsync(userId);

           
            if (user == null)
            {
                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to confirm user verification..Please contact administrator" });
                return new JsonStringResult(json);
            }
            else
            {
                try
                {
                    var res = await _userManager.ConfirmEmailAsync(user, code);
                    if (res.Succeeded)
                    {
                        return RedirectToAction("LogIn", "Account", new { id = -999999});
                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to confirm user verification..Please contact administrator" });
                        return new JsonStringResult(json);
                    }
                }
                catch (Exception)
                {

                    var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to confirm user verification..Please contact administrator" });
                    return new JsonStringResult(json);
                }

               
            }
         

           
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult ForgotPassword()
        {
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model)
        {
            // Something failed, redisplay form
            if (!ModelState.IsValid)
                return View(model);

            // Check if the user exists in the data store
            var user = await _userManager.FindByEmailAsync(model.Email);

            // If no user is found, or the user has not confirmed their email address yet
            if (user == null || !await _userManager.IsEmailConfirmedAsync(user))
            {
                // Show the confirmation page either way
                return RedirectToAction(nameof(ForgotPasswordConfirmation));
            }

            // For more information on how to enable account confirmation and password reset please 
            // visit https://go.microsoft.com/fwlink/?LinkID=532713
            var code = await _userManager.GeneratePasswordResetTokenAsync(user);
            var callbackUrl = Url.ResetPasswordCallbackLink(user.Id, code, Request.Scheme);

            // Note: This should usually send out the email address but the default implementation for the EmailSender is empty
            await _emailSender.SendEmailAsync(model.Email, "Reset Password", $"Please reset your password by clicking here: <a href='{callbackUrl}'>link</a>");

            // Show the confirmation page
            return RedirectToAction(nameof(ForgotPasswordConfirmation));
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult ForgotPasswordConfirmation()
        {
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult ResetPassword(string code = null)
        {
            if (code == null)
            {
                throw new ApplicationException("A code must be supplied for password reset.");
            }
            var model = new ResetPasswordViewModel
            {
                Code = code
            };
            return View(model);
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ResetPassword(ResetPasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
            {
                // Don't reveal that the user does not exist
                return RedirectToAction(nameof(ResetPasswordConfirmation));
            }
            var result = await _userManager.ResetPasswordAsync(user, model.Code, model.Password);
            if (result.Succeeded)
            {
                return RedirectToAction(nameof(ResetPasswordConfirmation));
            }
            AddErrors(result);
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult ResetPasswordConfirmation()
        {
            return View();
        }

        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }

        private void AddErrors(IdentityResult result)
        {
            foreach (var error in result.Errors)
            {
                ModelState.AddModelError(string.Empty, error.Description);
            }
        }

        private IActionResult RedirectToLocal(string returnUrl)
        {
            if (Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }
            return RedirectToAction(nameof(HomeController.Index), "Home");
        }
    }

    public class JsonError
    {
        public int CompanyId { get; set; }
    }


}
