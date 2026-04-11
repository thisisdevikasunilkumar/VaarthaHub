import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/services/invoice_service.dart';

class ReaderOrderDetailsScreen extends StatefulWidget {
  final dynamic booking;
  final String readerCode;

  const ReaderOrderDetailsScreen({
    super.key,
    required this.booking,
    required this.readerCode,
  });

  @override
  State<ReaderOrderDetailsScreen> createState() => _ReaderOrderDetailsScreenState();
}

class _ReaderOrderDetailsScreenState extends State<ReaderOrderDetailsScreen> {
  bool _isLoadingReader = true;
  Map<String, dynamic>? _readerProfile;
  late int _rating;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.booking['deliveryRating'] ?? 0;
    _reviewController.text = widget.booking['deliveryComments'] ?? '';
    _fetchReaderProfile();
  }

  Future<void> _fetchReaderProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/Reader/GetReaderProfile/${widget.readerCode}"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _readerProfile = json.decode(response.body);
          _isLoadingReader = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching reader profile: $e");
      setState(() => _isLoadingReader = false);
    }
  }

  Future<void> _submitRating() async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/OtherProductBookings/RateBooking"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bookingId": widget.booking['bookingId'],
          "rating": _rating,
          "comments": _reviewController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rating submitted successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error submitting rating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Orange decorative curve at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 150, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildHeader(),
                Expanded(
                  child: _isLoadingReader
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProductHeader(),
                              _buildStatusSection(),
                              _buildRatingSection(),
                              _buildDeliveryDetails(),
                              _buildPriceDetails(),
                              _buildFooterButtons(),
                              const SizedBox(height: 30),
                            ],
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Order Details",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.booking['productName']} (${widget.booking['year']})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Color: ${widget.booking['productType'] ?? 'Standard'} | Size: ${widget.booking['size'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "Order #OD${widget.booking['bookingId']}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildProductImage(),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    String? imageUrl = widget.booking['imageUrl'];
    String fullImageUrl = "";
    if (imageUrl != null) {
      fullImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${ApiConstants.baseUrl.replaceAll('/api', '')}$imageUrl';
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? Image.network(fullImageUrl, fit: BoxFit.cover)
            : const Icon(Icons.image, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = widget.booking['status'] ?? "Pending";
    final isDelivered = status.toLowerCase() == 'delivered';
    final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.booking['bookingDate']));

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isDelivered ? "Delivered, $dateStr" : "$status, $dateStr",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (isDelivered)
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _showStatusTimeline,
              child: const Text("See all updates", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusTimeline() {
    final status = widget.booking['status'] ?? "Pending";
    final bookingDate = widget.booking['bookingDate'];
    final shippedDate = widget.booking['shippedDate'];
    final deliveredDate = widget.booking['deliveredDate'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Order Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 24),
              _statusTile(
                "Ordered",
                bookingDate != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(bookingDate)) : null,
                true,
                true,
              ),
              _statusTile(
                "Shipped",
                shippedDate != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(shippedDate)) : null,
                shippedDate != null,
                status.toLowerCase() != 'pending',
              ),
              _statusTile(
                "Delivered",
                deliveredDate != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(deliveredDate)) : null,
                deliveredDate != null,
                status.toLowerCase() == 'delivered',
                isLast: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _statusTile(String title, String? subtitle, bool isCompleted, bool isPast, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
              child: isCompleted ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isPast ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.black : Colors.grey)),
              if (subtitle != null)
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    final status = widget.booking['status'] ?? "Pending";
    if (status.toLowerCase() != 'delivered') return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rate your experience", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.rate_review_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Write a product review"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_getRatingText(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.green : Colors.grey,
                      size: 30, // Slightly larger stars
                    ),
                    onPressed: () {
                      setState(() => _rating = index + 1);
                      _submitRating();
                    },
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _showReviewDialog();
            },
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
            label: const Text("Write review", style: TextStyle(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1: return "Poor";
      case 2: return "Fair";
      case 3: return "Good";
      case 4: return "Very Good";
      case 5: return "Great";
      default: return "Rate";
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Write a Review"),
        content: TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Share your experience with the delivery...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _submitRating();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF9C55E)),
            child: const Text("Submit", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    if (_readerProfile == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Delivery details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _readerProfile!['fullName'] ?? 'Reader',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${_readerProfile!['houseName']}, ${_readerProfile!['houseNo']}, ${_readerProfile!['landmark']}, ${_readerProfile!['panchayatName']}, Ward ${_readerProfile!['wardNumber']}, ${_readerProfile!['pincode']}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text("${_readerProfile!['fullName']} • ${_readerProfile!['phoneNumber']}"),
                  ],
                ),
              ),
            ],
          ),
          if (widget.booking['partnerName'] != null) ...[
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Delivery Partner", style: TextStyle(fontWeight: FontWeight.w600)),
                      Text("${widget.booking['partnerName']} (${widget.booking['partnerPhone'] ?? 'N/A'})"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    final amount = double.tryParse(widget.booking['totalAmount'].toString()) ?? 0.0;
    final qty = widget.booking['quantity'] ?? 1;
    final unitPrice = double.tryParse(widget.booking['unitPrice'].toString()) ?? 0.0;
    final listingPrice = unitPrice * qty;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _priceRow("Listing price", "₹$listingPrice"),
          _priceRow("Special price", "₹$listingPrice"),
          _priceRow("Total fees", "₹$listingPrice", isGreen: true),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              const Text("Payment method", style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              const Text("Cash On Delivery"),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                if (_readerProfile != null) {
                  InvoiceService.generateInvoice(
                    booking: widget.booking,
                    reader: _readerProfile!,
                  );
                }
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text("Download Invoice"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, color: isGreen ? Colors.green : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text("Order ID", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text("VH${widget.booking['bookingId']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text("Shop more from VaarthaHub", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
