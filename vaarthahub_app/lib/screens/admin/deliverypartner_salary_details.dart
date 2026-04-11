import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vaarthahub_app/models/delivery_partner_salary_model.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class DeliveryPartnerSalaryDetails extends StatefulWidget {
  final int partnerId; 
  final String partnerName;
  
  const DeliveryPartnerSalaryDetails({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<DeliveryPartnerSalaryDetails> createState() => _DeliveryPartnerSalaryDetailsState();
}

class _DeliveryPartnerSalaryDetailsState extends State<DeliveryPartnerSalaryDetails> {
  final TextEditingController _basicSalaryController = TextEditingController();
  final TextEditingController _incentiveController = TextEditingController();

  List<DeliveryPartnerSalaryModel> salaryHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalaryData();
  }

  // --- 1. Fetch Salary History from Backend ---
  Future<void> _fetchSalaryData() async {
    final String url = '${ApiConstants.baseUrl}/Admin/GetPartnerSalaryDetails/${widget.partnerId}';
    
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List historyJson = data['history'];
        
        setState(() {
          salaryHistory = historyJson.map((json) => DeliveryPartnerSalaryModel.fromJson(json)).toList();
          
          if (salaryHistory.isNotEmpty) {
            _basicSalaryController.text = salaryHistory.first.basicSalary.toStringAsFixed(0);
            _incentiveController.text = salaryHistory.first.incentive.toStringAsFixed(0);
          }
          isLoading = false;
        });
      } else {
        _showFeedback("Error: Server returned ${response.statusCode}", Colors.orange);
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showFeedback("Connection Error: Server reachable?", Colors.redAccent);
        setState(() => isLoading = false);
      }
    }
  }

  /// PERFORMANCE STATUS LOGIC (Synchronized with Performance Screen)
  Map<String, dynamic> _getStatus(double rating, int reviewCount) {
    if (rating >= 4.7 && reviewCount >= 10) {
      return {"text": "Top Rated", "color": Colors.purple, "bgColor": const Color(0xFFF3E5F5)};
    } else if (rating >= 4.0) {
      return {"text": "Excellent", "color": Colors.green, "bgColor": const Color(0xFFE8F5E9)};
    } else if (rating >= 3.0) {
      return {"text": "Average", "color": Colors.orange, "bgColor": const Color(0xFFFFF3E0)};
    } else if (rating > 0.1) {
      return {"text": "Below Average", "color": Colors.red, "bgColor": const Color(0xFFFFEBEE)};
    } else {
      return {"text": "No Ratings", "color": Colors.grey, "bgColor": const Color(0xFFF5F5F5)};
    }
  }

  // --- 2. Update Salary to Backend ---
  Future<void> _updateSalary() async {
    final String url = '${ApiConstants.baseUrl}/Admin/UpdatePartnerSalary';
    
    final updateData = {
      'deliveryPartnerId': widget.partnerId,
      'basicSalary': double.tryParse(_basicSalaryController.text) ?? 0.0,
      'incentive': double.tryParse(_incentiveController.text) ?? 0.0,
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        _showFeedback("Salary Updated Successfully!", Colors.green);
        _fetchSalaryData(); 
      } else {
        _showFeedback("Update failed. Please try again.", Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback("Connection Error: Please check your internet.", Colors.redAccent);
    }
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return "N/A";
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
  // Extracting rating and review count for status and incentive logic
  double rating = salaryHistory.isNotEmpty ? salaryHistory.first.averageRating : 0.0;
  int reviewCount = salaryHistory.isNotEmpty ? salaryHistory.first.ratingCount : 0; 
  
  final statusInfo = _getStatus(rating, reviewCount);

  // Suggested Incentive Logic (Matching your status levels)
  String suggestedIncentive;
  if (rating >= 4.7 && reviewCount >= 10) {
    suggestedIncentive = "1,000"; // Top Rated
  } else if (rating >= 4.0) {
    suggestedIncentive = "500"; // Excellent
  } else if (rating >= 3.0) {
    suggestedIncentive = "100"; // Average
  } else {
    suggestedIncentive = "0"; // Below Average / No Ratings
  }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png', 
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => Container(height: 150, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))) 
            : Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTotalCard(rating, statusInfo),
                          const SizedBox(height: 30),
                          const Text("Salary Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: "Basic Monthly Salary",
                            controller: _basicSalaryController,
                            hint: "₹ Enter basic salary",
                            footerText: "Last updated: ${formatDate(salaryHistory.firstOrNull?.basicSalaryLastUpdate)}",
                          ),
                          const SizedBox(height: 10),
                          _buildInputField(
                            label: "Incentive Amount",
                            controller: _incentiveController,
                            hint: "₹ Enter incentive",
                            footerText: "Suggested for ${statusInfo['text']} status: ₹$suggestedIncentive",
                            isSuggested: true,
                          ),
                          const SizedBox(height: 15),
                          _buildUpdateButton(),
                          const SizedBox(height: 30),
                          _buildIncentiveLogicCard(),
                          _buildHistoricalEarningsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Text("Salary Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double rating, Map<String, dynamic> statusInfo) {
    double currentTotal = salaryHistory.isNotEmpty ? salaryHistory.first.totalMonthlyEarnings : 0.0;
    
    Color ratingColor = rating >= 4.5 ? Colors.green : (rating >= 3.0 ? const Color(0xFFF9C55E) : Colors.redAccent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Partner: ${widget.partnerName}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(6)),
                      child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  // ignore: deprecated_member_use
                  border: Border.all(color: ratingColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: ratingColor),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ratingColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Current Monthly Total", style: TextStyle(fontSize: 13, color: Colors.grey)),
          Text("₹ ${currentTotal.toStringAsFixed(0)}", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          const SizedBox(height: 5),
          Text("Month: ${salaryHistory.isNotEmpty ? salaryHistory.first.monthYear : 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required String hint, required String footerText, bool isSuggested = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD1E1FF)), borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFF9C55E)), borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 5),
        Text(footerText, style: TextStyle(fontSize: 11, color: isSuggested ? Colors.blue.shade700 : Colors.redAccent, fontWeight: isSuggested ? FontWeight.w600 : FontWeight.normal)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateSalary,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFCC66),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("UPDATE PAYROLL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildIncentiveLogicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text("Incentive Slab Logic", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          // Top Rated Slab
          _logicRow("Rating 4.7 (min. 10 reviews)", "₹ 1,000", Colors.purple.shade700, const Color(0xFFF3E5F5)),
          const SizedBox(height: 8),
          
          // Excellent Slab
          _logicRow("Rating 3.10 - 4.7", "₹ 500", Colors.green.shade700, const Color(0xFFE8F5E9)),
          const SizedBox(height: 8),
          
          // Average Slab
          _logicRow("Rating 3.9 - 3.0", "₹ 100", Colors.orange.shade800, const Color(0xFFFFF3E0)),
          const SizedBox(height: 8),
          
          // Below Average Slab
          _logicRow("Below 3.0", "₹ 0", Colors.red.shade700, const Color(0xFFFFEBEE)),
        ],
      ),
    );
  }

  Widget _logicRow(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildHistoricalEarningsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Historical Earnings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const SizedBox(height: 10),
        _buildEarningsTable(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEarningsTable() {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.0), 2: FlexColumnWidth(1.3), 3: FlexColumnWidth(1.3), 4: FlexColumnWidth(1.2)},
      border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F4FF)),
          children: [_tableHeader("Month"), _tableHeader("Basic"), _tableHeader("Comm."), _tableHeader("Incent."), _tableHeader("Total")],
        ),
        ...salaryHistory.map((data) => TableRow(
          children: [
            _tableCell(data.monthYear),
            _tableCell(data.basicSalary.toStringAsFixed(0)),
            _tableCell(data.totalCommission.toStringAsFixed(0)),
            _tableCell(data.incentive.toStringAsFixed(0)),
            _tableCell(data.totalMonthlyEarnings.toStringAsFixed(0)),
          ],
        )),
      ],
    );
  }

  Widget _tableHeader(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)));
  Widget _tableCell(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)));
}