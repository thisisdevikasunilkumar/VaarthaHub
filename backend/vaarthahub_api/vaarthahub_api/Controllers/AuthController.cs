using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;
using vaarthahub_api.Services; // ISmsService
using Microsoft.Extensions.Caching.Memory; // IMemoryCache
using BCrypt.Net;

namespace vaarthahub_api.Controllers
{
    // api url: /api/auth/registration/ - base route for this controller
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ISmsService _smsService;
        private readonly IMemoryCache _cache;

        public AuthController(ApplicationDbContext context, ISmsService smsService, IMemoryCache cache)
        {
            _context = context;
            _smsService = smsService;
            _cache = cache;
        }

        // 1. Add a new user registration (POST method)
        [HttpPost("registration")]
        public async Task<IActionResult> Register(RegistrationDto registrationDto)
        {
            // 1. Email check
            if (await _context.Registration.AnyAsync(u => u.Email == registrationDto.Email))
            {
                return BadRequest(new { message = "Email already registered." });
            }

            string detectedRole = "";
            string detectedUserCode = "";

            // 2. Database checks using your logic
            var partner = await _context.DeliveryPartner
                .FirstOrDefaultAsync(p => p.PhoneNumber == registrationDto.PhoneNumber);

            var reader = await _context.Reader
                .FirstOrDefaultAsync(r => r.PhoneNumber == registrationDto.PhoneNumber);

            if (partner != null)
            {
                // Case 1: Delivery Partner aanu - No more reader checks!
                detectedRole = "DeliveryPartner";
                detectedUserCode = partner.PartnerCode;
            }
            else if (reader != null)
            {
                // Case 2: Existing Reader aanu
                detectedRole = "Reader";
                detectedUserCode = reader.ReaderCode;
            }
            else
            {
                // Case 3: Puthiya alu aanu - Create Reader first, then register
                detectedRole = "Reader";

                var newReader = new Reader
                {
                    FullName = registrationDto.FullName,
                    PhoneNumber = registrationDto.PhoneNumber,
                    Role = "Reader",
                    AddedByPartnerCode = "Direct Registration",
                    CreatedAt = DateTime.Now
                };

                _context.Reader.Add(newReader);
                await _context.SaveChangesAsync(); // SQL generates ReaderId & ReaderCode (R-001)

                detectedUserCode = newReader.ReaderCode;
            }

            // 3. Final Registration (Main Login Table)
            string hashedPassword = BCrypt.Net.BCrypt.HashPassword(registrationDto.Password);

            var newUser = new Registration
            {
                UserCode = detectedUserCode, // DP-xxx OR R-xxx
                Role = detectedRole,
                FullName = registrationDto.FullName,
                PhoneNumber = registrationDto.PhoneNumber,
                Email = registrationDto.Email,
                PasswordHash = hashedPassword,
                JoinDate = DateTime.Now,
                IsActive = true
            };

            // Image handling
            if (!string.IsNullOrEmpty(registrationDto.ProfileImage))
            {
                try
                {
                    string base64Data = registrationDto.ProfileImage;
                    if (base64Data.Contains(",")) base64Data = base64Data.Split(',')[1];
                    newUser.ProfileImage = Convert.FromBase64String(base64Data);
                }
                catch { newUser.ProfileImage = null; }
            }

            _context.Registration.Add(newUser);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Registration successful!",
                role = detectedRole,
                userCode = detectedUserCode
            });
        }

        // 2. User login (POST method)
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
        {
            // 1. ADMIN LOGIN CHECK
            if (loginDto.EmailOrPhone == "vaarthahub@gmail.com" && loginDto.Password == "vaarthahub")
            {
                return Ok(new { message = "Admin Login Successful!", role = "Admin" });
            }

            // 2. USER LOGIN CHECK (Email or Phone)
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.Email == loginDto.EmailOrPhone || u.PhoneNumber == loginDto.EmailOrPhone);

            if (user == null)
            {
                return Unauthorized(new { message = "Invalid Email/Phone or Password" });
            }

            // 3. PASSWORD VERIFICATION (Using BCrypt)
            bool isValidPassword = BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash);

            if (!isValidPassword)
            {
                return Unauthorized(new { message = "Invalid Email/Phone or Password" });
            }

            return Ok(new
            {
                message = "Login successful!",
                role = user.Role,
                fullName = user.FullName,
                userId = user.UserId,
                code = user.UserCode
            });
        }

        // 3. Forgot Password (POST method)
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
        {
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.Email == dto.EmailOrPhone || u.PhoneNumber == dto.EmailOrPhone);

            if (user == null) return NotFound(new { message = "User not found" });

            string otp = new Random().Next(1000, 9999).ToString();
            _cache.Set(dto.EmailOrPhone, otp, TimeSpan.FromMinutes(5));

            if (dto.Method == "SMS")
            {
                await _smsService.SendOtpSmsAsync(user.PhoneNumber, otp);
            }

            return Ok(new { message = "OTP sent successfully" });
        }

        // 4. Verify OTP (POST method)
        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            if (_cache.TryGetValue(dto.EmailOrPhone, out string? cachedOtp))
            {
                if (cachedOtp == dto.Otp)
                {
                    return Ok(new { message = "OTP verified successfully" });
                }
            }
            return BadRequest(new { message = "Invalid or expired OTP" });
        }

        // 5. Reset Password (POST method)
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.Email == dto.EmailOrPhone || u.PhoneNumber == dto.EmailOrPhone);

            if (user == null) return NotFound(new { message = "User not found" });

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            _context.Registration.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Password reset successfully!" });
        }

        // 6. Change Password (POST method)
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
        {
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.UserCode == dto.UserCode);

            if (user == null) return NotFound(new { message = "User not found" });

            // Verify old password
            if (!BCrypt.Net.BCrypt.Verify(dto.OldPassword, user.PasswordHash))
            {
                return BadRequest(new { message = "Old password is incorrect" });
            }

            // Hash new password
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            user.PasswordUpdatedAt = DateTime.Now;

            _context.Registration.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Password changed successfully!" });
        }
    }
}
