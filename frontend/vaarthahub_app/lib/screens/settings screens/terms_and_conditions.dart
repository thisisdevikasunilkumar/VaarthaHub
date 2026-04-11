import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

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
          _mainTitle("Terms and Conditions"),
          _lastUpdated("Last updated: February 27, 2026"),
          
          _bodyText("Please read these terms and conditions carefully before using Our Service."),
          _bodyText("By accessing or using the Service, You agree to be bound by these Terms and Conditions. If You disagree with any part of these terms, then You may not access the Service."),

          const Divider(height: 40),

          _sectionTitle("1. Acknowledgment"),
          _bodyText("These are the Terms and Conditions governing the use of this Service and the agreement that operates between You and the Company. These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service."),
          
          _sectionTitle("2. User Accounts"),
          _bodyText("When You create an account with Us, You must provide information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account on Our Service."),
          _bulletPoint("Security", "You are responsible for safeguarding the password that You use to access the Service."),
          _bulletPoint("Restrictions", "You may not use as a username the name of another person or entity that is not lawfully available for use."),

          const SizedBox(height: 20),
          _sectionTitle("3. Content Accuracy"),
          _bodyText("VaarthaHub aims to provide accurate and real-time news. However, We do not warrant that the content is error-free, complete, or current. We reserve the right to modify or remove content at any time without prior notice."),

          const SizedBox(height: 20),
          _sectionTitle("4. Intellectual Property"),
          _bodyText("The Service and its original content (excluding Content provided by You or other users), features, and functionality are and will remain the exclusive property of VaarthaHub and its licensors."),

          const SizedBox(height: 20),
          _sectionTitle("5. Links to Other Websites"),
          _bodyText("Our Service may contain links to third-party web sites or services that are not owned or controlled by the Company. We strongly advise You to read the terms and privacy policies of any third-party web sites that You visit."),

          const SizedBox(height: 20),
          _sectionTitle("6. Termination"),
          _bodyText("We may terminate or suspend Your Account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms and Conditions."),

          const SizedBox(height: 20),
          _sectionTitle("7. Limitation of Liability"),
          _bodyText("To the maximum extent permitted by applicable law, in no event shall the Company be liable for any special, incidental, indirect, or consequential damages whatsoever arising out of or in any way related to the use of or inability to use the Service."),

          const SizedBox(height: 20),
          _sectionTitle("8. Governing Law"),
          _bodyText("The laws of India, particularly those applicable in the state of Kerala, shall govern these Terms and Your use of the Service."),

          const SizedBox(height: 20),
          _sectionTitle("9. Changes to These Terms"),
          _bodyText("We reserve the right, at Our sole discretion, to modify or replace these Terms at any time. By continuing to access or use Our Service after those revisions become effective, You agree to be bound by the revised terms."),

          const SizedBox(height: 20),
          _sectionTitle("10. Contact Us"),
          _bodyText("If you have any questions about these Terms and Conditions, You can contact us:"),
          _bulletPoint("Email", "VaarthaHub@gmail.com"),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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
        "Terms & Conditions",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _mainTitle(String title) => Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold));

  Widget _lastUpdated(String date) => Padding(
    padding: const EdgeInsets.only(top: 5, bottom: 15),
    child: Text(date, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryYellow)),
  );

  Widget _bodyText(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
  );

  Widget _bulletPoint(String lead, String desc) => Padding(
    padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: primaryYellow)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              children: [
                if (lead.isNotEmpty) TextSpan(text: "$lead: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}