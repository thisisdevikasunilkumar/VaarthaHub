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
        private readonly IEmailService _emailService;
        private readonly IMemoryCache _cache;

        public AuthController(ApplicationDbContext context, ISmsService smsService, IMemoryCache cache, IEmailService emailService)
        {
            _context = context;
            _smsService = smsService;
            _emailService = emailService;
            _cache = cache;
        }

        // 1. User registration with role detection logic (POST method)
        [HttpPost("registration")]
        public async Task<IActionResult> Register(RegistrationDto registrationDto)
        {
            // 1. Check if email already exists in the system
            if (await _context.Registration.AnyAsync(u => u.Email == registrationDto.Email))
            {
                return BadRequest(new { message = "Email already registered." });
            }

            string detectedRole = "";
            string detectedUserCode = "";

            // 2. Identify user type based on phone number
            var partner = await _context.DeliveryPartner
                .FirstOrDefaultAsync(p => p.PhoneNumber == registrationDto.PhoneNumber);

            var reader = await _context.Reader
                .FirstOrDefaultAsync(r => r.PhoneNumber == registrationDto.PhoneNumber);

            if (partner != null)
            {
                // Case 1: User is an existing DeliveryPartner
                detectedRole = "DeliveryPartner";
                detectedUserCode = partner.PartnerCode;
            }
            else if (reader != null)
            {
                // Case 2: User is an existing Reader
                detectedRole = "Reader";
                detectedUserCode = reader.ReaderCode;
            }
            else
            {
                // Case 3: New user - Create Reader profile first, then proceed with registration
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

            // 3. Securely hash the user password
            string hashedPassword = BCrypt.Net.BCrypt.HashPassword(registrationDto.Password);

            // Save final registration data to the main login table
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

            // Process and store profile image if provided
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

        // 2. User/Admin login authentication (POST method)
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
        {
            // 1. Verify hardcoded Admin credentials
            if (loginDto.EmailOrPhone == "vaarthahub@gmail.com" && loginDto.Password == "vaarthahub")
            {
                return Ok(new { message = "Admin Login Successful!", role = "Admin" });
            }

            // 2. Fetch user by email or phone number
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.Email == loginDto.EmailOrPhone || u.PhoneNumber == loginDto.EmailOrPhone);

            if (user == null)
            {
                return Unauthorized(new { message = "Invalid Email/Phone or Password" });
            }

            // 3. Verify the provided password against the stored hash (Using BCrypt)
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

        // 3. Request OTP for password recovery (POST method)
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
        {
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.Email == dto.EmailOrPhone || u.PhoneNumber == dto.EmailOrPhone);

            if (user == null) return NotFound(new { message = "User not found" });

            // Generate a 4-digit OTP and store it in cache for 5 minutes
            string otp = new Random().Next(1000, 9999).ToString();
            _cache.Set(dto.EmailOrPhone, otp, TimeSpan.FromMinutes(5));

            // Send OTP via preferred communication method
            if (dto.Method == "SMS")
            {
                await _smsService.SendOtpSmsAsync(user.PhoneNumber, otp);
            }
            else if (dto.Method == "Email")
            {
                await _emailService.SendOtpEmailAsync(user.Email, otp);
            }

            return Ok(new { message = "OTP sent successfully" });
        }

        // 4. Validate OTP from user input (POST method)
        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            // // Check if OTP exists in cache and matches user input
            if (_cache.TryGetValue(dto.EmailOrPhone, out string? cachedOtp))
            {
                if (cachedOtp == dto.Otp)
                {
                    return Ok(new { message = "OTP verified successfully" });
                }
            }
            return BadRequest(new { message = "Invalid or expired OTP" });
        }

        // 5. Reset user password after OTP verification (POST method)
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.Email == dto.EmailOrPhone || u.PhoneNumber == dto.EmailOrPhone);

            if (user == null) return NotFound(new { message = "User not found" });

            // Hash the new password and update record
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            _context.Registration.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Password reset successfully!" });
        }

        // 6. Update password for authenticated users (POST method)
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
        {
            var user = await _context.Registration
                .FirstOrDefaultAsync(u => u.UserCode == dto.UserCode);

            if (user == null) return NotFound(new { message = "User not found" });

            // Validate current password before allowing change
            if (!BCrypt.Net.BCrypt.Verify(dto.OldPassword, user.PasswordHash))
            {
                return BadRequest(new { message = "Old password is incorrect" });
            }

            // Hash new password and update timestamp
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            user.PasswordUpdatedAt = DateTime.Now;

            _context.Registration.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Password changed successfully!" });
        }
    }
}
