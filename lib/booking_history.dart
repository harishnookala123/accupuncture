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
  Map<String, String> userNames = {};
  static const String baseUrl = 'https://acupuncturemapp.sssbi.com';

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  // Parse booking_date which is List<Map<String, dynamic>>
  List<Map<String, dynamic>> parseBookingDates(dynamic data) {
    if (data == null) return [];

    if (data is List) {
      return data.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        }
      } catch (e) {
        print("Error parsing booking_date string: $e");
      }
    }
    return [];
  }

  // Parse session numbers from List<int>
  List<int> parseSessionNumbers(dynamic data) {
    if (data == null) return [];

    if (data is List) {
      return data.map((e) {
        if (e is int) return e;
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.map((e) {
            if (e is int) return e;
            if (e is String) return int.tryParse(e) ?? 0;
            return 0;
          }).toList();
        }
      } catch (e) {
        return [int.tryParse(data) ?? 0];
      }
    } else if (data is int) {
      return [data];
    }
    return [];
  }

  Future<void> fetchBookings() async {
    Dio dio = Dio();
    try {
      final response = await dio.post(
        "$baseUrl/getUserSlots",
        data: {"user_id": widget.userId},
      );
      final data = response.data;

      print("Raw slots data: ${data["slots"]}");

      if (data["status"] == "User slots fetched successfully") {
        final slotsData = data["slots"];

        for (var slot in slotsData) {
          String userId = slot["user_id"]?.toString() ?? "";
          if (userId.isNotEmpty && !userNames.containsKey(userId)) {
            await fetchUserName(userId);
          }
        }

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
      print("Error fetching bookings: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserName(String userId) async {
    try {
      print("Fetching details for user ID: $userId");
      final response = await ApiService().getUserDetails(userId);
      print("USER RESPONSE: $response");
      if (response["status"] == "User details fetched successfully") {
        final user = response["user"];
        String name = user["name"] ?? userId;
        setState(() {
          userNames[userId] = name;
        });
      }
    } catch (e) {
      setState(() {
        userNames[userId] = userId;
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
      print("Service response for $treatmentId: $response");
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

  String getUserName(String? userId) {
    if (userId == null || userId.isEmpty) return "Unknown User";
    return userNames[userId] ?? userId;
  }

  String formatDate(String date) {
    try {
      DateTime d = DateTime.parse(date);
      return DateFormat("dd MMM yyyy").format(d);
    } catch (e) {
      return date;
    }
  }

  String formatTime(String time) {
    // Handle inconsistent time formats like "10:30Am" -> "10:30 AM"
    try {
      String formattedTime = time;
      if (time.toLowerCase().contains('am')) {
        formattedTime = time.replaceAll(RegExp(r'Am|am|AM'), 'AM');
      } else if (time.toLowerCase().contains('pm')) {
        formattedTime = time.replaceAll(RegExp(r'Pm|pm|PM'), 'PM');
      }
      return formattedTime;
    } catch (e) {
      return time;
    }
  }

  // ✅ NEW: Check if session can be cancelled (more than 3 hours before appointment)
  bool canCancelSession(String date, String time) {
    try {
      DateTime now = DateTime.now();
      DateTime sessionDate = DateTime.parse(date);

      // Parse time
      String cleanTime = time.replaceAll(RegExp(r'Am|am|AM|Pm|pm|PM'), '').trim();
      final parts = cleanTime.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Adjust for AM/PM
      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      DateTime fullDateTime = DateTime(
        sessionDate.year, sessionDate.month, sessionDate.day, hour, minute,
      );

      // Calculate difference in hours
      Duration difference = fullDateTime.difference(now);
      double hoursDifference = difference.inMinutes / 60;

      // Can cancel if more than 3 hours remaining
      return hoursDifference > 3;
    } catch (e) {
      print("Error checking cancellation eligibility: $e");
      return false;
    }
  }

  // ✅ Check if session is past
  bool isSessionPast(String date, String time) {
    try {
      DateTime now = DateTime.now();
      DateTime sessionDate = DateTime.parse(date);

      String cleanTime = time.replaceAll(RegExp(r'Am|am|AM|Pm|pm|PM'), '').trim();
      final parts = cleanTime.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      DateTime fullDateTime = DateTime(
        sessionDate.year, sessionDate.month, sessionDate.day, hour, minute,
      );
      return fullDateTime.isBefore(now);
    } catch (e) {
      print("Error checking if session is past: $e");
      return false;
    }
  }

  // ✅ Get cancellation message based on time remaining
  String getCancellationMessage(String date, String time) {
    try {
      DateTime now = DateTime.now();
      DateTime sessionDate = DateTime.parse(date);

      String cleanTime = time.replaceAll(RegExp(r'Am|am|AM|Pm|pm|PM'), '').trim();
      final parts = cleanTime.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      DateTime fullDateTime = DateTime(
        sessionDate.year, sessionDate.month, sessionDate.day, hour, minute,
      );

      Duration difference = fullDateTime.difference(now);
      double hoursDifference = difference.inMinutes / 60;

      if (hoursDifference <= 0) {
        return "This session has already passed";
      } else if (hoursDifference <= 3) {
        return "Cannot cancel less than 3 hours before appointment";
      } else {
        int hoursLeft = hoursDifference.floor();
        int minutesLeft = difference.inMinutes % 60;
        return "Cancel available (${hoursLeft}h ${minutesLeft}m remaining)";
      }
    } catch (e) {
      return "Cancellation not available";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.black87,
        title: const Text(
          "Booking History",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) =>
            _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF10B981),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No bookings yet",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    List<Map<String, dynamic>> slotsList = parseBookingDates(booking["booking_date"]);
    List<int> sessions = parseSessionNumbers(booking["session_number"]);

    String status = booking["status"] ?? "booked";
    bool isCancelled = status.toLowerCase() == "cancelled";
    String userName = getUserName(booking["user_id"]?.toString());
    String serviceName = getServiceName(booking["treatment_id"]);

    // Create session list from the correct data structure
    List<Map<String, dynamic>> sessionList = [];

    if (slotsList.isNotEmpty && sessions.isNotEmpty) {
      int minLength = slotsList.length < sessions.length ? slotsList.length : sessions.length;

      for (int i = 0; i < minLength; i++) {
        sessionList.add({
          'number': sessions[i],
          'date': slotsList[i]["date"],
          'time': slotsList[i]["time"],
        });
      }
    }

    // ✅ Check if there are any sessions that cannot be cancelled (less than 3 hours before)
    bool hasNonCancellableUpcomingSession = false;
    String nonCancellableMessage = "";

    for (var session in sessionList) {
      if (!isCancelled &&
          !isSessionPast(session['date'], session['time']) &&
          !canCancelSession(session['date'], session['time']) &&
          status.toLowerCase() == "booked") {
        hasNonCancellableUpcomingSession = true;
        nonCancellableMessage = getCancellationMessage(session['date'], session['time']);
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCancelled ? Colors.grey[50] : const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.grey[200] : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    booking["treatment_id"] != null && booking["treatment_id"] != 0
                        ? Icons.medical_services
                        : Icons.person,
                    size: 20,
                    color: isCancelled ? Colors.grey[500] : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? Colors.grey[500] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCancelled ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.grey[200]
                        : const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCancelled ? "Cancelled" : "Active",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCancelled ? Colors.grey[500] : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sessions List
          if (sessionList.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessionList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                var session = sessionList[index];
                bool isPast = isSessionPast(session['date'], session['time']);
                bool canCancel = canCancelSession(session['date'], session['time']);

                return _buildSessionItem(
                  sessionNumber: session['number'],
                  date: session['date'],
                  time: session['time'],
                  isPast: isPast,
                  isCancelled: isCancelled,
                  canCancel: !isCancelled && !isPast && canCancel && status.toLowerCase() == "booked",
                  bookingId: booking["id"],
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "No session details available",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),

          // ✅ NOTE AT THE BOTTOM OF THE PAGE - Shows when there are non-cancellable upcoming sessions
          if (hasNonCancellableUpcomingSession && !isCancelled)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nonCancellableMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Small footer spacing
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSessionItem({
    required int sessionNumber,
    required String? date,
    required String? time,
    required bool isPast,
    required bool isCancelled,
    required bool canCancel,
    required int bookingId,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Session number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPast || isCancelled
                  ? Colors.grey[100]
                  : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                sessionNumber.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPast || isCancelled ? Colors.grey[400] : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Date and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Session $sessionNumber",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPast || isCancelled ? Colors.grey[400] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (date != null && time != null)
                  Text(
                    "${formatDate(date)} • ${formatTime(time)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast || isCancelled ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),

          // Status or action
          if (isCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Cancelled",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            )
          else if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Completed",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF10B981),
                ),
              ),
            )
          else if (canCancel)
              GestureDetector(
                onTap: () => _showCancelDialog(bookingId, sessionNumber, date!, time!),
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
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Upcoming",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _showCancelDialog(int bookingId, int sessionNum, String date, String time) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Session $sessionNum"),
        content: Text(
          "Are you sure you want to cancel session $sessionNum on ${formatDate(date)} at ${formatTime(time)}?\n\nNote: This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Cancel Session"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().cancelBooking(bookingId, "cancelled");
        await fetchBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session cancelled successfully"),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error cancelling session: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}