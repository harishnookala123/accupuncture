import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class AdminBlockPage extends StatefulWidget {
  const AdminBlockPage({super.key});

  @override
  State<AdminBlockPage> createState() => _AdminBlockPageState();
}

class _AdminBlockPageState extends State<AdminBlockPage> {
  final Dio dio = Dio();
  static const String baseUrl = 'https://acupuncturemapp.sssbi.com';

  DateTime? selectedDate;
  Set<String> selectedSlots = {}; // Changed from String? to Set<String>
  final TextEditingController reasonController = TextEditingController();

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

  bool isBlockingDate = false;
  bool isBlockingSlot = false;

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedSlots.clear();
      });
    }
  }

  void _toggleSlotSelection(String slot) {
    setState(() {
      if (selectedSlots.contains(slot)) {
          selectedSlots.remove(slot);
      } else {
         selectedSlots.add(slot);
      }
    });
  }

  void _selectAllMorningSlots() {
    setState(() {
      selectedSlots.addAll(morningSlots);
    });
  }

  void _selectAllAfternoonSlots() {
    setState(() {
      selectedSlots.addAll(afternoonSlots);
    });
  }

  void _clearAllSlots() {
    setState(() {
      selectedSlots.clear();
    });
  }

  Future<void> _blockDate() async {
    if (selectedDate == null) {
      _showMessage("Please select a date", isError: true);
      return;
    }
    if (reasonController.text.trim().isEmpty) {
      _showMessage("Please enter a reason", isError: true);
      return;
    }

    setState(() => isBlockingDate = true);
    try {
      await dio.post("$baseUrl/blockDate", data: {
        "blocked_date": selectedDate!.toIso8601String(),
        "reason": reasonController.text.trim(),
      });
      reasonController.clear();
      setState(() => selectedDate = null);
      _showMessage("✓ Date blocked successfully", isError: false);
    } catch (e) {
      _showMessage("Failed to block date", isError: true);
      debugPrint("ERROR: $e");
    } finally {
      if (mounted) setState(() => isBlockingDate = false);
    }
  }

  Future<void> _blockSlots() async {
    if (selectedDate == null) {
      _showMessage("Please select a date first", isError: true);
      return;
    }
    if (selectedSlots.isEmpty) {
      _showMessage("Please select at least one time slot", isError: true);
      return;
    }
    if (reasonController.text.trim().isEmpty) {
      _showMessage("Please enter a reason", isError: true);
      return;
    }

    setState(() => isBlockingSlot = true);

    int successCount = 0;
    int failCount = 0;

    try {
      // Block each selected slot
      for (String slot in selectedSlots) {
        try {
          await dio.post("$baseUrl/blockSlot", data: {
            "date": selectedDate!.toIso8601String(),
            "slot_time": slot,
            "reason": reasonController.text.trim(),
          });
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint("Failed to block slot $slot: $e");
        }
      }

      if (successCount > 0) {
        _showMessage(
          "✓ $successCount slot(s) blocked successfully${failCount > 0 ? " ($failCount failed)" : ""}",
          isError: false,
        );
      }

      if (failCount > 0 && successCount == 0) {
        _showMessage("Failed to block slots", isError: true);
      }

      // Clear after successful blocking
      if (successCount > 0) {
        reasonController.clear();
        setState(() {
          selectedSlots.clear();
        });
      }
    } finally {
      if (mounted) setState(() => isBlockingSlot = false);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Block Dates",
              style: TextStyle(
                fontSize: 21,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),

          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.calendar_today,
                                  size: 20, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Select Date",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: selectedDate != null
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade200,
                                  width: selectedDate != null ? 2 : 1),
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (selectedDate != null) ...[
                                      Text(
                                        _formatDate(selectedDate!),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Tap to change",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        "Choose a date",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Reason Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit_note,
                              size: 20, color: Colors.purple.shade700),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Reason for Blocking",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Why is this date/slot being blocked?",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade700),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Block Full Date Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isBlockingDate ? null : _blockDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.red.shade300,
                ),
                child: isBlockingDate
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 22),
                    SizedBox(width: 12),
                    Text(
                      "Block Full Date",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Divider with OR text

            const SizedBox(height: 16),

            // Selected Slots Counter

          ],
        ),
      ),
    );
  }
}