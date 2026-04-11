using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;

namespace vaarthahub_api.Services
{
    public interface ISmsService
    {
        // Add Delivery Partner SMS
        Task SendAddDeliveryPartnerSmsAsync(string phoneNumber, string name);
        // Add Reader SMS
        Task SendAddReaderSmsAsync(string phoneNumber, string name);
        // Password Recovery OTP SMS
        Task SendOtpSmsAsync(string phoneNumber, string otp);
    }

    public class SmsService : ISmsService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<SmsService> _logger;

        public SmsService(IConfiguration configuration, ILogger<SmsService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // 1. Add Delivery Partner SMS
        public async Task SendAddDeliveryPartnerSmsAsync(string phoneNumber, string name)
        {
            var body = $"\n\nHi {name} 👋,\nWelcome to VaarthaHub 📰!\n\nYou have been added as a Delivery Partner 🚚.\nDownload our app and register using your phone number {phoneNumber} to get started.\n\nTeam VaarthaHub 🙏";
            await SendSmsViaTwilio(phoneNumber, body);
        }

        // 2. Add Reader SMS
        public async Task SendAddReaderSmsAsync(string phoneNumber, string name)
        {
            var body = $"\n\nHi {name} 👋,\nWelcome to VaarthaHub 📰!\n\nYou have been added as a Reader by your Delivery Partner.\nPlease download the VaarthaHub app and register using this phone number: {phoneNumber}.\n\nAfter logging in, kindly add your delivery address in the app to start receiving your newspaper 📬.\n\nThank you for choosing VaarthaHub 🙏";
            await SendSmsViaTwilio(phoneNumber, body);
        }

        // 3. Password Recovery OTP SMS
        public async Task SendOtpSmsAsync(string phoneNumber, string otp)
        {
            var body = $"\n\nYour VaarthaHub verification code is: {otp}. Valid for 5 minutes. Please do not share this with anyone.";
            await SendSmsViaTwilio(phoneNumber, body);
        }

        // Private helper method to avoid code duplication
        private async Task SendSmsViaTwilio(string phoneNumber, string messageBody)
        {
            var accountSid = _configuration["Twilio:AccountSid"];
            var authToken = _configuration["Twilio:AuthToken"];
            var fromNumber = _configuration["Twilio:FromNumber"];

            if (string.IsNullOrWhiteSpace(accountSid) || string.IsNullOrWhiteSpace(authToken) || string.IsNullOrWhiteSpace(fromNumber))
            {
                _logger.LogWarning("Twilio credentials not configured in appsettings.json. Skipping SMS to {Phone}", phoneNumber);
                return;
            }

            var url = $"https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json";

            try
            {
                using var client = new HttpClient();
                var auth = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{accountSid}:{authToken}"));
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", auth);

                var content = new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("To", phoneNumber),
                    new KeyValuePair<string, string>("From", fromNumber),
                    new KeyValuePair<string, string>("Body", messageBody),
                });

                var response = await client.PostAsync(url, content);
                var respContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Twilio SMS failed to {Phone}. Status: {Status}. Response: {Response}", phoneNumber, response.StatusCode, respContent);
                }
                else
                {
                    _logger.LogInformation("Twilio SMS sent successfully to {Phone}.", phoneNumber);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception while sending SMS via Twilio to {Phone}", phoneNumber);
            }
        }
    }
}