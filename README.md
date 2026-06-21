# VaarthaHub

VaarthaHub is a smart, localized newspaper & magazine subscription management, billing, and recycling platform. It bridges the gap between local newspaper agencies, delivery partners, and readers by digitizing subscription lifecycles, optimizing delivery routes, automating bill generation, and facilitating recycling through scrap paper collection.

---

## 🎨 UI / UX Design (Figma)

The complete UI/UX design of **VaarthaHub** was created using **Figma**.

🔗 **Figma Design Link:**  
https://www.figma.com/design/70nlqQnjfdPzm1MouBweH3/VaarthaHub?node-id=0-1&t=3XMMzYvEKTs0bv4z-1

> This design includes dashboard layouts, admin panels, staff views, and overall application flow.

---

## 🧰 Technologies Used

| Component                          | Technology                                                               |
|------------------------------------|--------------------------------------------------------------------------|
| **Front-End (Mobile Application)** | Dart (Flutter SDK)                                                       |
| **Back-End (Web API)**             | C# (ASP.NET Core 10.0 Web API)                                           |
| **Database**                       | MS SQL Server (via Entity Framework Core 10)                             |
| **Machine Learning / AI Module**   | ML.NET TimeSeries (SSA) for Newspaper Demand Forecasting                 |
| **Routing / GIS Module**           | TomTom Routing API / OSRM (Open Source Routing Machine)                  |
| **Payment Integration**            | Razorpay Flutter SDK & Razorpay .NET Gateway                             |
| **Communications API**             | Twilio SMS API (OTP Verification) & MailKit (SMTP Mail Service)          |
| **Development Tools**              | Visual Studio, Visual Studio Code, SQL Server Management Studio          |
| **Operating System**               | Windows 10/11 (Development/Backend Hosting), Android/iOS (App Execution) |
| **Supported Platforms**            | Android (API Level 21+), iOS (11.0+)                                     |

---

## 🚀 Features & Modules

#### 1. Admin
* **Agency Management**: Authorize and onboard local newspaper agencies.
* **Category Configuration**: Configure publications (newspapers, magazines, calendars, diary) and set up global parameters.
* **Design Frames**: Manage layout templates and rate charts for local anniversary/birthday advertisements.
* **Scrap Overview**: Monitor green recycling metrics and scrap volume across all agencies.

#### 2. Agent (Local News Agency)
* **Inventory Control**: Manage local newspaper lists, pricing, and active magazines.
* **Delivery Operations**: Onboard delivery partners, assign delivery wards, and configure optimal route sequencing.
* **Vacation Suspension**: Auto-pause delivery for readers who request temporary vacation holds.
* **Billing & Commission**: Track auto-generated monthly invoices and compute commissions for delivery partners.
* **Community Approvals**: Review and approve articles written by readers and ads booked for local publication.
* **Scrap Management**: Oversee scrap paper bookings and manage payment settlements with partners.

#### 3. Delivery Partner
* **Route Navigation**: Interactive map view of the daily delivery path with optimized sequence order.
* **Reader Management**: Directly register local subscribers in their assigned areas.
* **Earnings & Feedback**: Monitor monthly commission payouts, track performance scores, and read customer reviews.
* **Scrap Operations**: Track pending scrap pickups, preview collection routes, record actual weights on collection, and settle payments.

#### 4. Reader (Subscriber)
* **Subscriptions**: Browse and subscribe to newspapers and magazines with flexible digital payments.
* **Vacation Mode**: Pause deliveries during travel to prevent newspaper accumulation.
* **Recycling (Scrap Pickups)**: Book scrap paper collections. The system uses a decision model to estimate scrap weight and calculate your environmental contribution (Trees & Water saved).
* **Community Corner**:
  * **Reader's Corner**: Publish stories, poems, or essays (requires agency approval).
  * **Magazine Swap**: Settle exchange requests for magazines with other readers in the same locality.
  * **Kids' Corner**: Dedicated space for children's drawings, poetry uploads, with likes and comments.
* **Ad Bookings**: Custom template picker for birthday wishes, remembrance notes, and anniversaries.
* **VaarthaBot**: Multi-lingual AI chatbot (Malayalam & English) to query bills, vacation status, and subscriptions.
* **Billing & Payments**: Direct invoice downloads and secure checkouts integrated with Razorpay.

---

## 🔒 Source Code Availability

This repository contains only the project documentation, screenshots, and related resources.

The complete source code is maintained in a private repository to protect the intellectual property of the project and prevent unauthorized distribution.

Access to the source code may be granted upon request for academic evaluation or authorized collaboration purposes.

---

### 📌 Note
This project was developed as part of the **MCA Final Year Project** and is intended purely for learning and academic purposes.

### 📚 Academic Information

- **Course**: Master of Computer Applications (MCA)  
- **Semester**: 4th Semester   
- **Institution**: *CCSIT Dr. John Matthai Centre Aranattukara, Thrissur* 
