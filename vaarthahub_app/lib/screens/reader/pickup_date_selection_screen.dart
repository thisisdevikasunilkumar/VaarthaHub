import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class PickupDateSelectionScreen extends StatefulWidget {
  const PickupDateSelectionScreen({super.key});

  @override
  State<PickupDateSelectionScreen> createState() =>
      _PickupDateSelectionScreenState();
}

class _PickupDateSelectionScreenState extends State<PickupDateSelectionScreen> {
  String selectedTime = "Morning";

  // State variables for Date Logic
  DateTime _focusedDay = DateTime(2026, 1, 12); // Calendar display month
  DateTime _selectedDay = DateTime(2026, 1, 12); // Selected pickup date

  // Function to change Date via arrows (Top Right)
  void _updateDate(int days) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: days));
      _focusedDay = DateTime(_selectedDay.year, _selectedDay.month);
    });
  }

  // Function to change Month via arrows (Calendar Header)
  void _updateMonth(int months) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + months);
    });
  }

  // Date Picker from Icon
  Future<void> _selectDateFromPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;
        _focusedDay = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Preferred Date",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _selectDateFromPicker,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFFFCE6D),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Pickup Date",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCE6D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('EEE, d MMM , yyyy').format(_selectedDay),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => _updateDate(-1),
                        child: const Icon(Icons.keyboard_arrow_left, size: 18),
                      ),
                      GestureDetector(
                        onTap: () => _updateDate(1),
                        child: const Icon(Icons.keyboard_arrow_right, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFigmaCalendar(),

            const SizedBox(height: 30),
            const Text(
              "Select Pickup Time",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildRadioOption("Morning"),
                const SizedBox(width: 20),
                _buildRadioOption("Evening"),
              ],
            ),

            const SizedBox(height: 30),
            _buildSummaryCard(),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _showSuccessDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCE6D),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildFigmaCalendar() {
    // Days of the week labels
    final List<String> weekDays = [
      "Sun",
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
    ];

    // Logic to calculate days in the month
    int daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    int firstDayOfWeek =
        DateTime(_focusedDay.year, _focusedDay.month, 1).weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_left),
              onPressed: () => _updateMonth(-1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_right),
              onPressed: () => _updateMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: daysInMonth + firstDayOfWeek,
          itemBuilder: (context, index) {
            if (index < firstDayOfWeek) return const SizedBox.shrink();

            int day = index - firstDayOfWeek + 1;
            DateTime currentDay = DateTime(
              _focusedDay.year,
              _focusedDay.month,
              day,
            );
            bool isSelected =
                _selectedDay.year == currentDay.year &&
                _selectedDay.month == currentDay.month &&
                _selectedDay.day == currentDay.day;

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = currentDay),
              child: Center(
                child: Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFCE6D)
                        : const Color(0xFFF4F7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$day",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- BAKKI CODES (NO CHANGES) ---
  Widget _buildRadioOption(String value) {
    return GestureDetector(
      onTap: () => setState(() => selectedTime = value),
      child: Row(
        children: [
          Icon(
            selectedTime == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: const Color(0xFFFFCE6D),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        border: Border.all(color: const Color(0xFFFFCE6D).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pickup Time Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _summaryRow(
            Icons.calendar_today_outlined,
            "Date",
            DateFormat('EEE, MMM d, yyyy').format(_selectedDay),
          ),
          const Divider(height: 30),
          _summaryRow(Icons.access_time, "Time", selectedTime),
          const Divider(height: 30),
          _summaryRow(
            Icons.location_on_outlined,
            "Address",
            "House No. 42, Kottayam Panchayat",
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey, size: 20),
        ),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Image.asset(
                  'assets/images/Scrap Request Success.png',
                  height: 150,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                const Text(
                  "Scrap Pickup Scheduled!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Great! Your scrap pickup has been successfully scheduled.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9C55E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to home',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
