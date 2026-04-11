import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  final Color primaryYellow = const Color(0xFFF9C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          _mainTitle("Privacy Policy"),
          _lastUpdated("Last updated: February 27, 2026"),

          _bodyText(
              "This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You."),
          _bodyText(
              "We use Your Personal Data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy."),

          const Divider(height: 40),

          _sectionTitle("Interpretation and Definitions"),

          _subSectionTitle("Interpretation"),
          _bodyText(
              "The words whose initial letters are capitalized have meanings defined under the following conditions."),

          _subSectionTitle("Definitions"),

          _bulletPoint("Account",
              "means a unique account created for You to access our Service."),
          _bulletPoint("Application",
              "refers to VaarthaHub, the software program provided by the Company."),
          _bulletPoint("Company",
              "refers to VaarthaHub, Kerala."),
          _bulletPoint("Country",
              "refers to Kerala, India."),
          _bulletPoint("Device",
              "means any device such as a mobile phone, computer or tablet."),
          _bulletPoint("Personal Data",
              "means any information that relates to an identified or identifiable individual."),
          _bulletPoint("Service",
              "refers to the Application."),
          _bulletPoint("Usage Data",
              "refers to data collected automatically when using the Service."),
          _bulletPoint("You",
              "means the individual accessing or using the Service."),

          const SizedBox(height: 20),

          _sectionTitle("Collecting and Using Your Personal Data"),

          _subSectionTitle("Types of Data Collected"),

          _boldTitle("Personal Data"),

          _bulletPoint("", "Email address"),
          _bulletPoint("", "First name and last name"),
          _bulletPoint("", "Phone number"),
          _bulletPoint("", "Address, City, State"),

          const SizedBox(height: 10),

          _boldTitle("Usage Data"),
          _bodyText(
              "Usage Data is collected automatically when using the Service. This may include device IP address, browser type, pages visited, time spent, and diagnostic data."),

          const SizedBox(height: 10),

          _boldTitle("Information Collected while Using the Application"),

          _bulletPoint("", "Location information"),

          _bodyText(
              "You can enable or disable access to this information anytime from device settings."),

          const SizedBox(height: 20),

          _sectionTitle("Use of Your Personal Data"),

          _bulletPoint("Service Maintenance",
              "To provide and maintain our Service."),
          _bulletPoint("Account Management",
              "To manage Your registration as a user."),
          _bulletPoint("Contract Performance",
              "To fulfill services or subscriptions."),
          _bulletPoint("Communication",
              "To contact You via email, phone or notifications."),
          _bulletPoint("Promotions",
              "To provide news and special offers."),
          _bulletPoint("Business Transfers",
              "To evaluate mergers or acquisitions."),
          _bulletPoint("Analytics",
              "To analyze usage and improve the Service."),

          const SizedBox(height: 20),

          _sectionTitle("Sharing Your Personal Data"),

          _bulletPoint("Service Providers",
              "We may share data with third parties who help operate the Service."),
          _bulletPoint("Business Transfers",
              "In case of merger or acquisition."),
          _bulletPoint("Affiliates",
              "Companies under common control with us."),
          _bulletPoint("Business Partners",
              "To offer products or services."),
          _bulletPoint("User Interactions",
              "Information shared publicly may be visible to other users."),
          _bulletPoint("Consent",
              "With your permission."),

          const SizedBox(height: 20),

          _sectionTitle("Retention of Your Personal Data"),

          _bodyText(
              "We retain Personal Data only as long as necessary to fulfill the purposes outlined in this policy."),

          _bulletPoint("User Accounts",
              "Up to 24 months after account closure."),
          _bulletPoint("Support Tickets",
              "Up to 24 months after closure."),
          _bulletPoint("Usage Data",
              "Up to 24 months for analytics and security."),

          const SizedBox(height: 20),

          _sectionTitle("Transfer of Your Personal Data"),

          _bodyText(
              "Your data may be processed on computers located outside your jurisdiction where data protection laws may differ."),

          const SizedBox(height: 20),

          _sectionTitle("Delete Your Personal Data"),

          _bodyText(
              "You may update or delete your information anytime through your account settings or by contacting us."),

          const SizedBox(height: 20),

          _sectionTitle("Disclosure of Your Personal Data"),

          _subSectionTitle("Business Transactions"),
          _bodyText(
              "If the Company is involved in a merger or acquisition, your Personal Data may be transferred."),

          _subSectionTitle("Law Enforcement"),
          _bodyText(
              "We may disclose Personal Data when required by law or government request."),

          _subSectionTitle("Other Legal Requirements"),
          _bulletPoint("", "Comply with legal obligations"),
          _bulletPoint("", "Protect company rights"),
          _bulletPoint("", "Prevent wrongdoing"),
          _bulletPoint("", "Protect public safety"),

          const SizedBox(height: 20),

          _sectionTitle("Security of Your Personal Data"),

          _bodyText(
              "We use commercially reasonable methods to protect your data but cannot guarantee absolute security."),

          const SizedBox(height: 20),

          _sectionTitle("Third-Party Services"),

          _bodyText(
              "Third-party providers may access Personal Data to maintain and improve the Service."),

          _subSectionTitle("Google Places"),

          _bodyText(
              "Google Places is a service used to retrieve location information. Data collected is subject to Google's Privacy Policy."),

          const SizedBox(height: 20),

          _sectionTitle("Children's Privacy"),

          _bodyText(
              "Our Service does not address anyone under the age of 16 and we do not knowingly collect their Personal Data."),

          const SizedBox(height: 20),

          _sectionTitle("Links to Other Websites"),

          _bodyText(
              "Our Service may contain links to external websites. We are not responsible for their privacy practices."),

          const SizedBox(height: 20),

          _sectionTitle("Changes to this Privacy Policy"),

          _bodyText(
              "We may update this Privacy Policy from time to time. Changes will be posted on this page."),

          const SizedBox(height: 20),

          _sectionTitle("Contact Us"),

          _bulletPoint("Email", "VaarthaHub@gmail.com"),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // AppBar Helper
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Privacy Policy",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _mainTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));

  Widget _lastUpdated(String date) => Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 15),
        child: Text(date,
            style: const TextStyle(
                color: Colors.grey, fontStyle: FontStyle.italic)),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(title,
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primaryYellow)),
      );

  Widget _subSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 8),
        child: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      );

  Widget _boldTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  Widget _bodyText(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
      );

  Widget _bulletPoint(String lead, String desc) => Padding(
        padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryYellow)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4),
                  children: [
                    if (lead.isNotEmpty)
                      TextSpan(
                          text: "$lead: ",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: desc),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}