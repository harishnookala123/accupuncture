import 'package:acupuncture/static_homescreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api/api_service.dart';

class BookingScreen extends StatefulWidget {
  final String? userId;
  final String? name;
  const BookingScreen({super.key, this.userId, this.name});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  String? selectedTime;

  List<DateTime> quickDates = [];
  Set<String> blockedDates = {}; // Store blocked dates as "yyyy-MM-dd"
  bool isLoadingBlockedDates = true;

  final List<String> morningSlots = [
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "01:00 PM",
  ];

  final List<String> afternoonSlots = [
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
    "04:30 PM",
    "05:00 PM",
    "05:30 PM",
    "06:00 PM",
  ];

  @override
  void initState() {
    super.initState();
    generateQuickDates();
    checkBlockedDates();
  }

  void generateQuickDates() {
    DateTime now = DateTime.now();
    // Only three dates: Today, Tomorrow, Day After
    quickDates = [
      now, // Today
      now.add(const Duration(days: 1)), // Tomorrow
      now.add(const Duration(days: 2)), // Day After
    ];
  }

  Future<void> checkBlockedDates() async {
    setState(() {
      isLoadingBlockedDates = true;
    });

    try {
      // Format dates as "yyyy-MM-dd"
      List<String> dateStrings = quickDates.map((date) {
        return DateFormat("yyyy-MM-dd").format(date);
      }).toList();

      print("Checking blocked dates: $dateStrings");

      final response = await ApiService().getBlockedDates(dateStrings);
      print("Blocked dates response: $response");

      // Clear previous blocked dates
      Set<String> newBlockedDates = {};

      // Check if response has blockedDates array
      if (response['blockedDates'] != null && response['blockedDates'] is List) {
        List blockedList = response['blockedDates'];

        for (var blockedItem in blockedList) {
          // Extract the blocked_date from each item
          String blockedDateStr = blockedItem['blocked_date'] ?? '';

          if (blockedDateStr.isNotEmpty) {
            // Parse the UTC date
            DateTime blockedDateTime = DateTime.parse(blockedDateStr);

            // Convert to local date without time
            // This ensures we only compare the date part, ignoring timezone
            DateTime localDate = DateTime.utc(
              blockedDateTime.year,
              blockedDateTime.month,
              blockedDateTime.day,
            );

            // Format to "yyyy-MM-dd" for comparison
            String formattedDate = DateFormat("yyyy-MM-dd").format(localDate);
            newBlockedDates.add(formattedDate);

            print("Blocked date from API: $blockedDateStr -> Local date: $formattedDate");
          }
        }
      }

      // Also check if response has blocked_dates (alternative format)
      if (response['blocked_dates'] != null && response['blocked_dates'] is List) {
        List blockedList = response['blocked_dates'];
        for (var blockedDate in blockedList) {
          newBlockedDates.add(blockedDate.toString());
        }
      }

      setState(() {
        blockedDates = newBlockedDates;
        isLoadingBlockedDates = false;
      });

      print("Final blocked dates set: $blockedDates");

    } catch (e) {
      print("Error fetching blocked dates: $e");
      setState(() {
        isLoadingBlockedDates = false;
      });
    }
  }

  String getDateLabel(DateTime date) {
    DateTime today = DateTime.now();
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime dayAfterTomorrow = today.add(const Duration(days: 2));

    if (date.day == today.day &&
        date.month == today.month &&
        date.year == today.year) {
      return "Today";
    }

    if (date.day == tomorrow.day &&
        date.month == tomorrow.month &&
        date.year == tomorrow.year) {
      return "Tomorrow";
    }

    if (date.day == dayAfterTomorrow.day &&
        date.month == dayAfterTomorrow.month &&
        date.year == dayAfterTomorrow.year) {
      return "Day After";
    }

    return "";
  }

  String formatFullDate(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  bool isDateAvailable(DateTime date) {
    // Check if date is not in the past
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime dateToCheck = DateTime(date.year, date.month, date.day);

    // Check if date is in the past
    if (dateToCheck.isBefore(today)) {
      return false;
    }

    // Check if date is blocked
    String dateString = DateFormat("yyyy-MM-dd").format(date);
    if (blockedDates.contains(dateString)) {
      return false;
    }

    return true;
  }

  bool isDateBlocked(DateTime date) {
    String dateString = DateFormat("yyyy-MM-dd").format(date);
    return blockedDates.contains(dateString);
  }

  void confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select date & time"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Double check if selected date is blocked
    if (isDateBlocked(selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("This date is not available for booking"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal, size: 28),
            SizedBox(width: 10),
            Text("Booking Confirmed", style: TextStyle(fontWeight: FontWeight.bold,
                fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your appointment has been booked for:",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_sharp, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        formatFullDate(selectedDate!),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        selectedTime!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              var bookAppointment = await ApiService().bookSlot(
                  widget.userId!,
                  DateFormat("yyyy-MM-dd").format(selectedDate!),
                  selectedTime!,
                  1
              );
              if (bookAppointment['status'] == "Slot booked successfully") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(bookAppointment['status']),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => StaticHomeScreen(
                        userId: widget.userId,
                        name: widget.name,
                      ),
                    ),
                        (route) => false
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(bookAppointment['status']),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Book Appointment",
            style: TextStyle(fontWeight: FontWeight.w600,
                color: Colors.white
            ),
          ),
          backgroundColor: Colors.teal,
          elevation: 1.2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.teal,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Doctor Consultation",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Please select your preferred date and time",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// 📅 Select Date
                const Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 12),

                /// Loading indicator for blocked dates
                if (isLoadingBlockedDates)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                /// Three date chips in a row
                  Row(
                    children: quickDates.asMap().entries.map((entry) {
                      int index = entry.key;
                      DateTime date = entry.value;
                      bool isSelected = selectedDate != null &&
                          selectedDate!.day == date.day &&
                          selectedDate!.month == date.month &&
                          selectedDate!.year == date.year;
                      bool isAvailable = isDateAvailable(date);
                      bool isBlocked = isDateBlocked(date);

                      // Debug print
                      if (isBlocked) {
                        print("Date ${DateFormat("yyyy-MM-dd").format(date)} is blocked");
                      }

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 6,
                            right: index == 2 ? 0 : 6,
                          ),
                          child: GestureDetector(
                            onTap: isAvailable ? () {
                              setState(() {
                                selectedDate = date;
                                selectedTime = null;
                              });
                            } : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.teal
                                    : isBlocked
                                    ? Colors.grey.shade200
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.teal
                                      : isBlocked
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    getDateLabel(date),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : isBlocked
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${date.day} ${_getMonthAbbreviation(date)}",
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : isBlocked
                                          ? Colors.grey.shade500
                                          : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isBlocked)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Blocked",
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 30),

                /// ⏰ Time Slots (only show if date selected and not blocked)
                if (selectedDate != null && !isDateBlocked(selectedDate!)) ...[
                  const Text(
                    "Select Time Slot",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Morning Slots
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              "Morning",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: morningSlots.map((time) {
                            bool isSelected = selectedTime == time;
                            return _buildTimeChip(time, isSelected);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Afternoon Slots
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.nightlight_round, size: 20, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              "Afternoon & Evening",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: afternoonSlots.map((time) {
                            bool isSelected = selectedTime == time;
                            return _buildTimeChip(time, isSelected);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ] else if (selectedDate != null && isDateBlocked(selectedDate!)) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red.shade600, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "This date is not available for booking. Please select another date.",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                /// 📌 Selected Summary
                if (selectedDate != null && selectedTime != null && !isDateBlocked(selectedDate!))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade50, Colors.teal.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selected Appointment",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${getDateLabel(selectedDate!)} • ${formatFullDate(selectedDate!)} at $selectedTime",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                /// ℹ️ Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Note: Treatment will be suggested after consultation with the doctor.",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                /// ✅ Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (selectedDate != null && selectedTime != null && !isDateBlocked(selectedDate!))
                        ? confirmBooking
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      "Confirm Booking",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthAbbreviation(DateTime date) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  Widget _buildTimeChip(String time, bool isSelected) {
    bool isPast = isPastTime(time);

    return GestureDetector(
      onTap: (selectedDate != null && !isPast && !isDateBlocked(selectedDate!))
          ? () {
        setState(() {
          selectedTime = time;
        });
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPast
              ? Colors.grey.shade300
              : isSelected
              ? Colors.teal
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isPast
                ? Colors.grey
                : isSelected
                ? Colors.teal
                : Colors.grey.shade100,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isPast
                ? Colors.grey.shade600
                : isSelected
                ? Colors.white
                : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  bool isPastTime(String slotTime) {
    if (selectedDate == null) return false;

    DateTime now = DateTime.now();

    // Only check for today
    if (selectedDate!.year != now.year ||
        selectedDate!.month != now.month ||
        selectedDate!.day != now.day) {
      return false;
    }

    // Convert "10:30 AM" → DateTime
    final parts = slotTime.split(" ");
    final hm = parts[0].split(":");

    int hour = int.parse(hm[0]);
    int minute = int.parse(hm[1]);

    if (parts[1] == "PM" && hour != 12) {
      hour += 12;
    } else if (parts[1] == "AM" && hour == 12) {
      hour = 0;
    }

    DateTime slotDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    return slotDateTime.isBefore(now);
  }
}