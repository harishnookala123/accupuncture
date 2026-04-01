import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  String? selectedTime;

  List<DateTime> quickDates = [];

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
    return date.isAfter(today) || date.isAtSameMomentAs(today);
  }

  void confirmBooking() {
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
            Text("Booking Confirmed", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
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
                      const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
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
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    // TODO: Send to backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Book Appointment",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
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
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.teal
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
                                        : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

                /// ⏰ Time Slots
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

                const SizedBox(height: 20),

                /// 📌 Selected Summary
                if (selectedDate != null && selectedTime != null)
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
                    onPressed: confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
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
    return GestureDetector(
      onTap: selectedDate != null
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
          color: isSelected ? Colors.teal : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}