import 'package:acupuncture/static_homescreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Set<String> blockedDates = {};
  Set<String> bookedSlots = {};
  bool isLoading = true;
  bool isLoadingSlots = false;

  final List<String> morningSlots = [
    "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
    "12:00 PM", "12:30 PM", "01:00 PM",
  ];

  final List<String> afternoonSlots = [
    "03:00 PM", "03:30 PM", "04:00 PM", "04:30 PM",
    "05:00 PM", "05:30 PM", "06:00 PM",
  ];

  @override
  void initState() {
    super.initState();
    _initDates();
    _loadBlockedDates();
  }

  void _initDates() {
    DateTime now = DateTime.now();
    quickDates = [now, now.add(const Duration(days: 1)), now.add(const Duration(days: 2))];
  }

  Future<void> _loadBlockedDates() async {
    setState(() => isLoading = true);
    try {
      List<String> dates = quickDates.map((d) => DateFormat("yyyy-MM-dd").format(d)).toList();
      final response = await ApiService().getBlockedDates(dates);

      Set<String> blocked = {};
      if (response['blockedDates'] is List) {
        for (var item in response['blockedDates']) {
          String date = item['blocked_date'] ?? '';
          if (date.isNotEmpty) {
            blocked.add(DateFormat("yyyy-MM-dd").format(DateTime.parse(date)));
          }
        }
      }
      setState(() {
        blockedDates = blocked;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadBookedSlots() async {
    if (selectedDate == null) return;
    setState(() => isLoadingSlots = true);
    try {
      String date = DateFormat("yyyy-MM-dd").format(selectedDate!);
      final response = await ApiService().getBookedSlotsForDate(date);

      Set<String> booked = {};
      if (response['booked_times'] is List) {
        for (var time in response['booked_times']) {
          booked.add(_normalizeTime(time.toString()));
        }
      }
      setState(() {
        bookedSlots = booked;
        isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => isLoadingSlots = false);
    }
  }

  String _normalizeTime(String time) {
    String t = time.trim();
    if (t.toLowerCase().contains('am')) t = t.replaceAll(RegExp(r'Am|am|AM'), 'AM');
    if (t.toLowerCase().contains('pm')) t = t.replaceAll(RegExp(r'Pm|pm|PM'), 'PM');
    if (!t.contains(' ') && (t.contains('AM') || t.contains('PM'))) {
      t = t.replaceAll('AM', ' AM').replaceAll('PM', ' PM');
    }
    return t;
  }

  bool _isSlotBooked(String time) {
    return bookedSlots.contains(_normalizeTime(time));
  }

  bool _isDateBlocked(DateTime date) {
    return blockedDates.contains(DateFormat("yyyy-MM-dd").format(date));
  }

  bool _isDateAvailable(DateTime date) {
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime checkDate = DateTime(date.year, date.month, date.day);
    return !checkDate.isBefore(today) && !_isDateBlocked(date);
  }

  bool _isPastTime(String time) {
    if (selectedDate == null) return false;
    DateTime now = DateTime.now();
    if (selectedDate!.year != now.year || selectedDate!.month != now.month || selectedDate!.day != now.day) {
      return false;
    }
    String t = _normalizeTime(time);
    List parts = t.split(' ');
    List hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    int minute = int.parse(hm[1]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;
    DateTime slotTime = DateTime(now.year, now.month, now.day, hour, minute);
    return slotTime.isBefore(now);
  }

  String _getDateLabel(DateTime date) {
    DateTime now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return "Today";
    if (date.day == now.add(const Duration(days: 1)).day && date.month == now.month) return "Tomorrow";
    if (date.day == now.add(const Duration(days: 2)).day && date.month == now.month) return "Day After";
    return "";
  }

  Future<void> _bookAppointment() async {
    if (selectedDate == null || selectedTime == null) {
      _showMessage("Please select date & time", Colors.red);
      return;
    }
    if (_isDateBlocked(selectedDate!)) {
      _showMessage("This date is not available", Colors.red);
      return;
    }
    if (_isSlotBooked(selectedTime!)) {
      _showMessage("This time slot is already booked", Colors.red);
      return;
    }

    _showLoading();
    var result = await ApiService().bookSlot(
        widget.userId!,
        DateFormat("yyyy-MM-dd").format(selectedDate!),
        selectedTime!,
        1
    );
    Navigator.pop(context);

    if (result['status'] == "Slot booked successfully") {
      await ApiService().sendNotificationToAdmin(
        adminId: 'Admin2',
        userName: widget.name ?? '',
        date: DateFormat("dd MMM yyyy").format(selectedDate!),
        time: selectedTime!,
      );
      _showMessage("Booking confirmed!", Colors.green);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => StaticHomeScreen(userId: widget.userId, name: widget.name)),
            (route) => false,
      );
    } else {
      _showMessage(result['status'] ?? "Booking failed", Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 24),
            if (selectedDate != null) _buildTimeSelector(),
            const SizedBox(height: 24),
            if (selectedDate != null && selectedTime != null) _buildSummary(),
            const SizedBox(height: 16),
            _buildNote(),
            const SizedBox(height: 24),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medical_services, color: Colors.teal, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Doctor Consultation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Select your preferred date and time", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: quickDates.asMap().entries.map((entry) {
            int index = entry.key;
            DateTime date = entry.value;
            bool isSelected = selectedDate != null &&
                selectedDate!.day == date.day &&
                selectedDate!.month == date.month;
            bool isAvailable = _isDateAvailable(date);
            bool isBlocked = _isDateBlocked(date);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 8, right: index == 2 ? 0 : 8),
                child: InkWell(
                  onTap: isAvailable ? () async {
                    setState(() {
                      selectedDate = date;
                      selectedTime = null;
                    });
                    await _loadBookedSlots();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : (isBlocked ? Colors.grey.shade100 : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(_getDateLabel(date),
                            style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(DateFormat("dd MMM").format(date),
                            style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                        if (isBlocked)
                          Text("Blocked", style: TextStyle(fontSize: 10, color: Colors.red.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    if (_isDateBlocked(selectedDate!)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text("This date is not available", style: TextStyle(color: Colors.red.shade700))),
          ],
        ),
      );
    }

    if (isLoadingSlots) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSlotSection("Morning", Icons.wb_sunny, Colors.orange, morningSlots),
        const SizedBox(height: 12),
        _buildSlotSection("Afternoon & Evening", Icons.nightlight_round, Colors.indigo, afternoonSlots),
      ],
    );
  }

  Widget _buildSlotSection(String title, IconData icon, Color color, List<String> slots) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Text(title)]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((time) {
              bool isBooked = _isSlotBooked(time);
              bool isPast = _isPastTime(time);
              bool isSelected = selectedTime == time;
              bool enabled = !isBooked && !isPast;

              return FilterChip(
                label: Text(_normalizeTime(time)),
                selected: isSelected,
                onSelected: enabled ? (v) => setState(() => selectedTime = time) : null,
                backgroundColor: Colors.grey.shade50,
                selectedColor: Colors.teal,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isBooked || isPast ? Colors.grey : Colors.black),
                ),
                avatar: isBooked ? const Icon(Icons.check_circle, size: 14) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${_getDateLabel(selectedDate!)} • ${DateFormat("dd MMM").format(selectedDate!)} at $selectedTime",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.info, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text("Treatment will be suggested after consultation", style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    bool enabled = selectedDate != null && selectedTime != null &&
        !_isDateBlocked(selectedDate!) && !_isSlotBooked(selectedTime!);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Confirm Booking", style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}