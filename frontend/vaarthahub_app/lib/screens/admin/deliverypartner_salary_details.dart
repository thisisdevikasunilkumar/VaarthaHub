import 'package:flutter/material.dart';
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
    // API Call to fetch salary history for the given partnerId
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
      debugPrint("Error fetching salary: $e");
      if (mounted) {
        _showFeedback("Connection Error: Server reachable?", Colors.redAccent);
        setState(() => isLoading = false);
      }
    }
  }

  // --- 2. Update Salary to Backend ---
  Future<void> _updateSalary() async {
    final String url = '${ApiConstants.baseUrl}/Admin/UpdatePartnerSalary';
    
    // JSON Payload
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
        _fetchSalaryData(); // Refresh table to show updated total
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
                          _buildTotalCard(),
                          const SizedBox(height: 30),
                          const Text("Salary Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: "Basic Monthly Salary",
                            controller: _basicSalaryController,
                            hint: "₹ Enter basic salary amount",
                            lastUpdate: "Last updated: ${formatDate(salaryHistory.firstOrNull?.basicSalaryLastUpdate)}",
                          ),
                          const SizedBox(height: 10),
                          _buildInputField(
                            label: "Incentive Amount",
                            controller: _incentiveController,
                            hint: "₹ Enter Incentive amount",
                            lastUpdate: "Last updated: ${formatDate(salaryHistory.firstOrNull?.incentiveLastUpdate)}",
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
              ),
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
          const Text("Salary Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    double currentTotal = salaryHistory.isNotEmpty ? salaryHistory.first.totalMonthlyEarnings : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ 
          Text("Partner: ${widget.partnerName}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
          const SizedBox(height: 8),
          const Text("Current Monthly Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text("₹ ${currentTotal.toStringAsFixed(0)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
          const SizedBox(height: 5),
          Text("Month: ${salaryHistory.isNotEmpty ? salaryHistory.first.monthYear : 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
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
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("Update Salary", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHistoricalEarningsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text("Historical Earnings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const SizedBox(height: 15),
        _buildEarningsTable(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildEarningsTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.3),
        4: FlexColumnWidth(1.2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F4FF)),
          children: [
            _tableHeader("Month"),
            _tableHeader("Basic"),
            _tableHeader("Commission"),
            _tableHeader("Incentive"),
            _tableHeader("Total"),
          ],
        ),
        ...salaryHistory.map((data) => _tableRow(
          data.monthYear,
          data.basicSalary.toStringAsFixed(0),
          data.totalCommission.toStringAsFixed(0),
          data.incentive.toStringAsFixed(0),
          data.totalMonthlyEarnings.toStringAsFixed(0),
        )),
      ],
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  );

  TableRow _tableRow(String m, String b, String c, String i, String t) {
    return TableRow(
      children: [_tableCell(m), _tableCell(b), _tableCell(c), _tableCell(i), _tableCell(t)],
    );
  }

  Widget _tableCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
  );

  Widget _buildInputField({required String label, required TextEditingController controller, required String hint, required String lastUpdate}) {
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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD1E1FF)), borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFF9C55E)), borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 5),
        Text(lastUpdate, style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildIncentiveLogicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your Incentive Slab Logic", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          _logicRow("4.5 to 5.0 Rating", "₹ 1,000"),
          _logicRow("4.0 to 4.4 Rating", "₹ 500"),
          _logicRow("Below 4.0 Rating", "₹ 0"),
        ],
      ),
    );
  }

  Widget _logicRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}