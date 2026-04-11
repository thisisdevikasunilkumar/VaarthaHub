using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. CORS Policy
builder.Services.AddCors(options => {
    options.AddPolicy("AllowAll", b =>
        b.AllowAnyMethod()
         .AllowAnyHeader()
         .AllowAnyOrigin());
});

// 2. Database Connection
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 3. Register Services
builder.Services.AddScoped<ISmsService, SmsService>();

// 4. Memory Cache for OTP
builder.Services.AddMemoryCache();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 5. Swagger/API Testing Tools
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();