import 'dart:convert';
import 'package:acupuncture/api/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  final String? userId;

  const BookingHistoryScreen({super.key, required this.userId});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List bookings = [];
  bool isLoading = true;
  Map<int, String> serviceNames = {};
  Set<int> fetchingIds = {};
  static const String baseUrl = 'https://acupuncturemapp.sssbi.com';

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    Dio dio = Dio();
    try {
      final response = await dio.post(
        "$baseUrl/getUserSlots",
        data: {"user_id": widget.userId},
      );
      final data = response.data;

      if (data["status"] == "User slots fetched successfully") {
        final slotsData = data["slots"];
        setState(() {
          bookings = slotsData;
        });
        await fetchServiceNames(slotsData);
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchServiceNames(List slots) async {
    List<Future> futures = [];

    for (var slot in slots) {
      int? treatmentId = slot["treatment_id"];
      if (treatmentId != null && treatmentId > 0 &&
          !serviceNames.containsKey(treatmentId) &&
          !fetchingIds.contains(treatmentId)) {
        fetchingIds.add(treatmentId);
        futures.add(_fetchServiceName(treatmentId));
      }
    }

    await Future.wait(futures);
  }

  Future<void> _fetchServiceName(int treatmentId) async {
    try {
      final response = await ApiService().getServiceDetails(treatmentId);
      String serviceName = response['title'] ?? "Treatment";
      setState(() {
        serviceNames[treatmentId] = serviceName;
      });
    } catch (e) {
      setState(() {
        serviceNames[treatmentId] = "Treatment";
      });
    } finally {
      fetchingIds.remove(treatmentId);
    }
  }

  String getServiceName(int? treatmentId) {
    if (treatmentId == null || treatmentId == 0) return "Consultation";
    return serviceNames[treatmentId] ?? "Treatment";
  }

  String formatDate(String date) {
    try {
      DateTime d = DateTime.parse(date);
      return DateFormat("dd MMM yyyy").format(d);
    } catch (e) {
      return date;
    }
  }

  String formatDateTime(String dateTime) {
    try {
      DateTime d = DateTime.parse(dateTime);
      return DateFormat("dd MMM yyyy, hh:mm a").format(d);
    } catch (e) {
      return dateTime;
    }
  }

  bool isDatePassed(String date, String time) {
    try {
      DateTime now = DateTime.now();
      DateTime bookingDate = DateTime.parse(date);
      final parts = time.split(" ");
      final hm = parts[0].split(":");
      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);
      if (parts[1] == "PM" && hour != 12) hour += 12;
      if (parts[1] == "AM" && hour == 12) hour = 0;
      DateTime fullDateTime = DateTime(
        bookingDate.year, bookingDate.month, bookingDate.day, hour, minute,
      );
      return fullDateTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  bool canCancel(String status, String date, String time) {
    if (status.toLowerCase() == "cancelled") return false;
    if (isDatePassed(date, time)) return false;
    return true;
  }

  String getDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case "cancelled":
        return "Cancelled";
      case "booked":
        return "Upcoming";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.black,
        title: const Text(
          "Booking History",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? _buildLoadingState()
          : bookings.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading...",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No bookings yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your appointments will appear here",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic item) {
    String date = item["booking_date"] ?? "";
    String time = item["slot_time"] ?? "";
    String status = item["status"] ?? "booked";
    int bookingId = item["id"] ?? 0;
    int? treatmentId = item["treatment_id"];
    int sessionNumber = item["session_number"] ?? 1;
    String createdAt = item["created_at"] ?? "";

    bool showCancelButton = canCancel(status, date, time);
    bool datePassed = isDatePassed(date, time);
    String serviceName = getServiceName(treatmentId);
    String displayStatus = getDisplayStatus(status);
    bool isCancelled = status.toLowerCase() == "cancelled";
    bool isUpcoming = status.toLowerCase() == "booked" && !datePassed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Optional: Add detail view
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? Colors.grey[50]
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        treatmentId != null && treatmentId > 0
                            ? Icons.medical_services_outlined
                            : Icons.person_outline,
                        size: 24,
                        color: isCancelled ? Colors.grey[500] : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treatmentId != null && treatmentId > 0 ? serviceName : "Doctor Consultation",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCancelled ? Colors.grey[500] : const Color(0xFF1A1A1A),
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(date),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isCancelled ? Colors.grey[500] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isCancelled ? Colors.grey[500] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.repeat, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                "Session $sessionNumber",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCancelled ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? Colors.grey[100]
                            : isUpcoming
                            ? const Color(0xFFF0FDF4)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? Colors.grey[500]
                              : isUpcoming
                              ? const Color(0xFF10B981)
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Divider
                Container(height: 1, color: Colors.grey[100]),

                const SizedBox(height: 12),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_note, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          "Booked ${_getRelativeTime(createdAt)}",
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),

                    if (showCancelButton)
                      GestureDetector(
                        onTap: () => _showCancelDialog(bookingId, date, time),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ),

                    if (!showCancelButton && !isCancelled && datePassed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Expired",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRelativeTime(String createdAt) {
    try {
      DateTime created = DateTime.parse(createdAt);
      DateTime now = DateTime.now();
      Duration diff = now.difference(created);

      if (diff.inDays > 30) return formatDateTime(createdAt).split(',')[0];
      if (diff.inDays > 0) return "${diff.inDays} days ago";
      if (diff.inHours > 0) return "${diff.inHours} hours ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes} min ago";
      return "just now";
    } catch (e) {
      return "";
    }
  }

  void _showCancelDialog(int bookingId, String date, String time) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_outlined, size: 28, color: Colors.red[600]),
              ),
              const SizedBox(height: 20),
              Text(
                "Cancel Booking",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to cancel your appointment on ${formatDate(date)} at $time?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Keep it",
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await ApiService().cancelBooking(bookingId, "cancelled");
      await fetchBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Booking cancelled"),
            backgroundColor: Colors.black87,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}