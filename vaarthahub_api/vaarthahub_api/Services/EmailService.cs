using MailKit.Net.Smtp;
using MimeKit;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;

namespace vaarthahub_api.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string body);
        // Password Recovery OTP Email
        Task SendOtpEmailAsync(string toEmail, string otp);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;

        public EmailService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // 1. Password Recovery OTP Email
        public async Task SendOtpEmailAsync(string toEmail, string otp)
        {
            string subject = "VaarthaHub - Password Reset OTP";
            string body = $@"
                <div style='font-family: Poppins, sans-serif; border: 1px solid #eee; padding: 20px; border-radius: 12px; max-width: 500px;'>
                    <h2 style='color: #F9C55E;'>VaarthaHub Verification</h2>
                    <p>Hi,</p>
                    <p>Your verification code for password reset is:</p>
                    <div style='background: #f9f9f9; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 8px; color: #333; border: 1px dashed #F9C55E;'>
                        {otp}
                    </div>
                    <p style='color: #666; font-size: 13px; margin-top: 15px;'>This code is valid for 5 minutes. Please do not share it with anyone.</p>
                    <hr style='border: 0; border-top: 1px solid #eee; margin: 20px 0;'>
                    <p style='font-size: 12px; color: #F9C55E;'>Team VaarthaHub 📰</p>
                </div>";

            await SendEmailAsync(toEmail, subject, body);
        }

        // Base Email Sending Method
        public async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            var email = new MimeMessage();
            email.From.Add(MailboxAddress.Parse(_configuration["EmailSettings:FromEmail"]));
            email.To.Add(MailboxAddress.Parse(toEmail));
            email.Subject = subject;

            var builder = new BodyBuilder { HtmlBody = body };
            email.Body = builder.ToMessageBody();

            using var smtp = new MailKit.Net.Smtp.SmtpClient();

            await smtp.ConnectAsync(
                _configuration["EmailSettings:SmtpServer"],
                int.Parse(_configuration["EmailSettings:Port"]),
                MailKit.Security.SecureSocketOptions.StartTls
            );

            await smtp.AuthenticateAsync(
                _configuration["EmailSettings:Username"],
                _configuration["EmailSettings:Password"]
            );

            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);
        }
    }
}