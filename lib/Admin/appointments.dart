import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool isLoading = true;
  int selectedFilterIndex = 0; // 0: All, 1: Booked, 2: Completed, 3: Cancelled
  DateTime? selectedDate; // Date filter
  List services = [];
  List<Map<String, dynamic>> appointments = [];
  Map<String, dynamic> userCache = {};

  final List<String> morningSlots = [
    "10:00 AM","10:30 AM","11:00 AM","11:30 AM","12:00 PM","12:30 PM","01:00 PM"
  ];

  final List<String> afternoonSlots = [
    "03:00 PM","03:30 PM","04:00 PM","04:30 PM","05:00 PM","05:30 PM","06:00 PM"
  ];

  final List<String> filters = ["All", "Booked", "Completed", "Cancelled"];

  // Muted color palette
  final Color primaryMuted = const Color(0xFF4A5568); // Slate gray
  final Color successMuted = const Color(0xFF2F855A); // Muted green
  final Color warningMuted = const Color(0xFFC47F2E); // Muted orange
  final Color errorMuted = const Color(0xFFB84C4C); // Muted red
  final Color accentMuted = const Color(0xFF5B6E8C); // Muted blue-gray

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final slots = await ApiService().allSlots();

    for (var slot in slots) {
      String userId = slot["user_id"];

      try {
        final user = await ApiService().getUserDetails(userId);
        userCache[userId] = user["user"];
      } catch (e) {}

      slot["userDetails"] = userCache[userId];
      slot["showDropdown"] = false;
      slot["selectedServiceId"] = slot["treatment_id"]?.toString();

      // CRITICAL FIX: Parse booking_date properly and keep ALL slots
      if (slot["booking_date"] != null) {
        try {
          if (slot["booking_date"] is String) {
            final parsed = jsonDecode(slot["booking_date"]);
            if (parsed is List) {
              slot["booking_date"] = parsed;
              print("✅ Parsed booking_date: ${slot["booking_date"]}");
              print("📊 Number of slots: ${parsed.length}");
            }
          } else if (slot["booking_date"] is List) {
            print("✅ booking_date is already a list: ${slot["booking_date"]}");
            print("📊 Number of slots: ${slot["booking_date"].length}");
          }
        } catch (e) {
          print("Error parsing booking_date: $e");
        }
      }

      // Parse session_number properly
      if (slot["session_number"] != null) {
        try {
          if (slot["session_number"] is String) {
            final parsed = jsonDecode(slot["session_number"]);
            if (parsed is List) {
              slot["session_number"] = parsed;
              print("✅ Parsed session_number: ${slot["session_number"]}");
            }
          } else if (slot["session_number"] is List) {
            print("✅ session_number is already a list: ${slot["session_number"]}");
          }
        } catch (e) {
          print("Error parsing session_number: $e");
        }
      }

      if (slot["treatment_id"] != null) {
        try {
          final res = await ApiService().getServiceDetails(slot["treatment_id"]);
          slot["serviceTitle"] = res["title"];
        } catch (e) {}
      }
    }

    setState(() {
      appointments = slots;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredAppointments {
    return appointments.where((e) {
      // Status filter
      bool statusMatch = false;
      switch(selectedFilterIndex) {
        case 0:
          statusMatch = true;
          break;
        case 1:
          statusMatch = e["status"].toString().toLowerCase() == "booked";
          break;
        case 2:
          statusMatch = e["status"].toString().toLowerCase() == "completed";
          break;
        case 3:
          statusMatch = e["status"].toString().toLowerCase() == "cancelled";
          break;
      }

      // Date filter
      bool dateMatch = true;
      if (selectedDate != null) {
        try {
          var bookingData = e["booking_date"];
          List<Map<String, dynamic>> slotsList = [];

          if (bookingData is List) {
            slotsList = List<Map<String, dynamic>>.from(bookingData);
          }

          if (slotsList.isNotEmpty) {
            final lastDateStr = slotsList.last["date"]?.toString() ?? "";
            if (lastDateStr.isNotEmpty) {
              final appointmentDate = DateTime.parse(lastDateStr);
              dateMatch = appointmentDate.year == selectedDate!.year &&
                  appointmentDate.month == selectedDate!.month &&
                  appointmentDate.day == selectedDate!.day;
            } else {
              dateMatch = false;
            }
          } else {
            dateMatch = false;
          }
        } catch (e) {
          print("Date filter error: $e");
          dateMatch = false;
        }
      }

      return statusMatch && dateMatch;
    }).toList();
  }

  void _clearDateFilter() {
    setState(() {
      selectedDate = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryMuted,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> openBookingModal(Map<String, dynamic> appt) async {
    DateTime? selectedDateModal;
    String? selectedSlot;

    List<int> currentSessions = [];
    dynamic sessionData = appt["session_number"];

    if (sessionData == null) {
      currentSessions = [];
    } else if (sessionData is List) {
      currentSessions = sessionData.map((e) {
        if (e is int) return e;
        if (e is String) return int.parse(e);
        return 0;
      }).toList();
    } else if (sessionData is String) {
      try {
        if (sessionData.trim().startsWith('[')) {
          List<dynamic> parsed = jsonDecode(sessionData);
          currentSessions = parsed.map((e) {
            if (e is int) return e;
            if (e is String) return int.parse(e);
            return 0;
          }).toList();
        } else {
          currentSessions = [int.parse(sessionData)];
        }
      } catch (e) {
        currentSessions = [];
      }
    }

    int lastSession = currentSessions.isNotEmpty ? currentSessions.last : 0;
    int nextSession = lastSession + 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Book Follow-up ",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Session $nextSession",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: primaryMuted,
                          ),
                        ),
                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDateModal = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: primaryMuted),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedDateModal == null
                                        ? "Select date"
                                        : DateFormat("EEEE, MMM d, yyyy").format(selectedDateModal!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: selectedDateModal == null ? Colors.grey[500] : Colors.grey[900],
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          "Morning",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: morningSlots.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final slot = morningSlots[index];
                              final isSelected = selectedSlot == slot;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedSlot = slot),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryMuted : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? primaryMuted : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slot,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Afternoon",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: afternoonSlots.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final slot = afternoonSlots[index];
                              final isSelected = selectedSlot == slot;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedSlot = slot),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryMuted : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? primaryMuted : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slot,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (selectedDateModal == null || selectedSlot == null)
                                ? null
                                : () async {
                              String formattedDate = DateFormat("yyyy-MM-dd").format(selectedDateModal!);

                              try {
                                List<Map<String, dynamic>> slotsList = [];

                                if (appt["booking_date"] != null) {
                                  try {
                                    var data = appt["booking_date"];
                                    if (data is String) {
                                      data = jsonDecode(data);
                                    }
                                    if (data is List) {
                                      slotsList = List<Map<String, dynamic>>.from(data);
                                    }
                                  } catch (e) {
                                    slotsList = [];
                                  }
                                }

                                List<int> existingSessions = [];
                                var sessionData = appt["session_number"];
                                if (sessionData is List) {
                                  existingSessions = List<int>.from(sessionData.map((e) => int.parse(e.toString())));
                                } else if (sessionData is String) {
                                  try {
                                    List<dynamic> parsed = jsonDecode(sessionData);
                                    existingSessions = parsed.map((e) => int.parse(e.toString())).toList();
                                  } catch (e) {
                                    existingSessions = [];
                                  }
                                }

                                Map<String, String> newSlot = {
                                  "date": formattedDate,
                                  "time": selectedSlot!
                                };

                                bool alreadyExists = slotsList.any((s) =>
                                s["date"] == newSlot["date"] && s["time"] == newSlot["time"]);

                                if (alreadyExists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("❌ This slot is already booked!")),
                                  );
                                  return;
                                }

                                int newSessionNumber = existingSessions.isNotEmpty
                                    ? existingSessions.last + 1
                                    : 1;

                                await ApiService().updateSessions(
                                  appt["id"].toString(),
                                  [newSessionNumber],
                                  int.parse(appt["selectedServiceId"].toString()),
                                  [newSlot],
                                  DateTime.now(),
                                );

                                final appointmentIndex = appointments.indexWhere((a) => a["id"] == appt["id"]);

                                if (appointmentIndex != -1) {
                                  setState(() {
                                    List<Map<String, dynamic>> updatedSlots = List.from(appointments[appointmentIndex]["booking_date"] ?? []);
                                    List<int> updatedSessions = List.from(appointments[appointmentIndex]["session_number"] ?? []);

                                    updatedSlots.add(newSlot);
                                    updatedSessions.add(newSessionNumber);

                                    appointments[appointmentIndex]["booking_date"] = updatedSlots;
                                    appointments[appointmentIndex]["session_number"] = updatedSessions;

                                    if (appointments[appointmentIndex]["treatment_id"] == null) {
                                      appointments[appointmentIndex]["treatment_id"] = int.parse(appt["selectedServiceId"].toString());
                                      appointments[appointmentIndex]["serviceTitle"] = appt["serviceTitle"];
                                    }
                                  });
                                }

                                await ApiService().sendNotificationToUser(
                                  userId: appt["user_id"].toString(),
                                  serviceName: appt["serviceTitle"].toString(),
                                  formattedDate: formattedDate,
                                  newSessionNumber: newSessionNumber,
                                  selectedSlot: selectedSlot!,
                                );

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 5),
                                    content: Text("✅ Follow-up booked successfully! Session $newSessionNumber"),
                                  ),
                                );

                                await loadAppointments();

                              } catch (e) {
                                print("Error: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error booking follow-up: ${e.toString()}"),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryMuted,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Confirm Booking",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget appointmentCard(Map<String, dynamic> appt, int cardIndex) {
    final user = appt["userDetails"];
    String name = user?["name"] ?? appt["user_id"];
    String phone = user?["phone_number"] ?? "";

    // CRITICAL FIX: Parse ALL slots correctly
    List<Map<String, dynamic>> slotsList = [];

    try {
      var rawData = appt["booking_date"];

      print("🔍 Raw booking_date for card: $rawData");
      print("🔍 Type: ${rawData.runtimeType}");

      if (rawData != null) {
        if (rawData is List) {
          slotsList = List<Map<String, dynamic>>.from(rawData);
          print("✅ Got ${slotsList.length} slots from List");
        } else if (rawData is String && rawData.isNotEmpty) {
          final decoded = jsonDecode(rawData);
          if (decoded is List) {
            slotsList = List<Map<String, dynamic>>.from(decoded);
            print("✅ Got ${slotsList.length} slots from JSON string");
          }
        }
      }

      // Debug: Print all slots
      for (int i = 0; i < slotsList.length; i++) {
        print("📅 Slot ${i+1}: ${slotsList[i]}");
      }

    } catch (e) {
      print("❌ ERROR parsing booking_date in card: $e");
    }

    String displayDate = "";
    String displaySlot = "";
    int currentSession = 0;

    if (slotsList.isNotEmpty) {
      final lastSlot = slotsList.last;
      displayDate = lastSlot["date"]?.toString() ?? "";
      displaySlot = lastSlot["time"]?.toString() ?? "";
    }

    // Parse sessions
    List<int> sessions = [];

    try {
      var sessionData = appt["session_number"];

      if (sessionData != null) {
        if (sessionData is List) {
          sessions = sessionData.map((e) => int.parse(e.toString())).toList();
        } else if (sessionData is String && sessionData.isNotEmpty) {
          if (sessionData.trim().startsWith('[')) {
            final decoded = jsonDecode(sessionData);
            if (decoded is List) {
              sessions = decoded.map((e) => int.parse(e.toString())).toList();
            }
          } else {
            sessions = [int.parse(sessionData)];
          }
        }
      }

      print("✅ Sessions: $sessions");

    } catch (e) {
      print("❌ Session parse error: $e");
    }

    if (sessions.isNotEmpty) {
      currentSession = sessions.last;
    }

    String formattedDate = "No date";
    if (displayDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(displayDate);
        formattedDate = DateFormat("dd MMM yyyy").format(parsed);
      } catch (e) {
        formattedDate = displayDate;
      }
    }

    bool isBooked = appt["status"].toString().toLowerCase() == "booked";
    bool isCompleted = appt["status"].toString().toLowerCase() == "completed";
    bool isCancelled = appt["status"].toString().toLowerCase() == "cancelled";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryMuted,
                            accentMuted,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "U",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? successMuted.withOpacity(0.1)
                            : isCompleted
                            ? primaryMuted.withOpacity(0.1)
                            : errorMuted.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? successMuted
                                  : isCompleted
                                  ? primaryMuted
                                  : errorMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appt["status"].toString().toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isBooked
                                  ? successMuted
                                  : isCompleted
                                  ? primaryMuted
                                  : errorMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: primaryMuted),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                      ),
                      Container(
                        width: 1,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.grey[300],
                      ),
                      Icon(Icons.access_time, size: 14, color: primaryMuted),
                      const SizedBox(width: 6),
                      Text(
                        displaySlot.isNotEmpty ? displaySlot : "No time",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                      ),
                      if (currentSession > 0) ...[
                        Container(
                          width: 1,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.grey[300],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "S$currentSession",
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: primaryMuted
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (!isCompleted && !isCancelled) ...[
                  if (appt["treatment_id"] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryMuted.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryMuted.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medical_services, size: 16, color: primaryMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appt["serviceTitle"] ?? "Treatment",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => openBookingModal(appt),
                                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                                label: Text("Follow-up", style: GoogleFonts.poppins(fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w600
                                )),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => openRescheduleModal(appt, cardIndex),
                                icon: const Icon(Icons.edit_calendar, size: 16, color: Colors.white),
                                label: Text("Reschedule", style: GoogleFonts.poppins(fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w600
                                )),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "Cancel Appointment",
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Are you sure you want to cancel this appointment?",
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "No",
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      await ApiService().cancelBooking(appt["id"], "cancelled");
                                                      Navigator.pop(context);
                                                      await ApiService().sendBookingCancellation(
                                                        userId: appt["user_id"],
                                                        date: selectedDate.toString(),
                                                        sessionNumber: currentSession,
                                                        time: ""
                                                      );
                                                      await loadAppointments();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Yes, Cancel",
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
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
                                    setState(() => appt["status"] = "cancelled");
                                  }
                                },
                                icon: const Icon(Icons.cancel, size: 16, color: Colors.white),
                                label: Text("Cancel", style: GoogleFonts.poppins(fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w600
                                )),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ApiService().markSlotCompleted(appt["id"]);
                                  setState(() => appt["status"] = "completed");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: successMuted,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text("Complete", style: GoogleFonts.poppins(fontSize: 13.8,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w600
                                )),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ]
                  else if (appt["isVisited"] != true && isBooked) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3.0,
                          child: OutlinedButton(
                            onPressed: () async {
                              final res = await ApiService().getServices();
                              setState(() {
                                services = res;
                                appt["showDropdown"] = true;
                                appt["isVisited"] = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: warningMuted,
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Visit",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: warningMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              var id = appt["id"];
                              await ApiService().markSlotCompleted(id);

                              setState(() {
                                appt["status"] = "completed";
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Marked as completed", style: GoogleFonts.poppins()),
                                  backgroundColor: successMuted,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: successMuted,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Complete",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]
                else if (isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: successMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Appointment completed",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
                else if (isCancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorMuted.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: errorMuted.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 18, color: errorMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Appointment cancelled",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: errorMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                if (appt["showDropdown"] == true && appt["treatment_id"] == null && !isCompleted && !isCancelled) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Select Treatment",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: appt["selectedServiceId"],
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Choose a service",
                          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                      items: services.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem(
                          value: s["service_id"].toString(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              s["title"],
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => appt["selectedServiceId"] = value);
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: appt["selectedServiceId"] == null
                          ? null
                          : () async {
                        final res = await ApiService().getServiceDetails(
                          int.parse(appt["selectedServiceId"]),
                        );
                        setState(() {
                          appt["treatment_id"] = int.parse(appt["selectedServiceId"]);
                          appt["serviceTitle"] = res["title"];
                          appt["showDropdown"] = false;
                        });
                        openBookingModal(appt);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openRescheduleModal(
      Map<String, dynamic> appt, int cardindex,
      ) async {
    DateTime? selectedDateModal;
    String? selectedSlot;

    List<Map<String, dynamic>> slotsList = [];

    try {
      var bookingData = appt["booking_date"];

      if (bookingData != null) {
        if (bookingData is List) {
          slotsList = List<Map<String, dynamic>>.from(bookingData);
        } else if (bookingData is String && bookingData.isNotEmpty) {
          final decoded = jsonDecode(bookingData);
          if (decoded is List) {
            slotsList = List<Map<String, dynamic>>.from(decoded);
          }
        }
      }
    } catch (e) {
      print("❌ Parse error: $e");
      return;
    }

    if (slotsList.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // TITLE
                    Text(
                      "Reschedule Appointment",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // INFO (shows last session)
                    Text(
                      "Rescheduling Last Session (${slotsList.length})",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DATE PICKER
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setModalState(() => selectedDateModal = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: primaryMuted),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDateModal == null
                                    ? "Select New Date"
                                    : DateFormat("dd MMM yyyy")
                                    .format(selectedDateModal!),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // MORNING
                    Text("Morning", style: GoogleFonts.poppins()),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: morningSlots.map((slot) {
                        final isSelected = selectedSlot == slot;

                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedSlot = slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryMuted
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              slot,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // AFTERNOON
                    Text("Afternoon", style: GoogleFonts.poppins()),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: afternoonSlots.map((slot) {
                        final isSelected = selectedSlot == slot;

                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedSlot = slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryMuted
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              slot,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    // CONFIRM BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (selectedDateModal == null ||
                            selectedSlot == null)
                            ? null
                            : () async {
                          try {
                            String formattedDate =
                            DateFormat("yyyy-MM-dd")
                                .format(selectedDateModal!);

                            String fixedTime = selectedSlot!
                                .replaceAll("Am", "AM")
                                .replaceAll("Pm", "PM");

                            // ✅ COPY LIST
                            List<Map<String, dynamic>> updatedSlots =
                            List<Map<String, dynamic>>.from(slotsList);

                            // 🔥 ALWAYS UPDATE LAST SESSION
                            updatedSlots[updatedSlots.length - 1] = {
                              "date": formattedDate,
                              "time": fixedTime,
                            };

                            await ApiService().rescheduleDate(
                              appt["id"],
                              updatedSlots,
                            );
                            await ApiService().sendNotificationToUser(
                              userId: appt["user_id"].toString(),
                              serviceName: appt["serviceTitle"].toString(),
                              formattedDate: formattedDate,
                              newSessionNumber: slotsList.length,
                              selectedSlot: selectedSlot!,
                            );
                            // ✅ UPDATE CORRECT APPOINTMENT
                            setState(() {
                              final index = appointments.indexWhere(
                                      (a) => a["id"] == appt["id"]);

                              if (index != -1) {
                                appointments[index]["booking_date"] =
                                    updatedSlots;
                              }
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text("✅ Rescheduled successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );

                            await loadAppointments();
                          } catch (e) {
                            print("❌ Error: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMuted,
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "Confirm Reschedule",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredAppointments;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: Colors.teal,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Appointments",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${appointments.length} total",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedDate != null ? primaryMuted : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        size: 22,
                        color: selectedDate != null ? Colors.white : primaryMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (selectedDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: primaryMuted),
                        const SizedBox(width: 8),
                        Text(
                          "Filtered by: ${DateFormat("dd MMM yyyy").format(selectedDate!)}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: primaryMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close, size: 14, color: primaryMuted),
                      ),
                    ),
                  ],
                ),
              ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                margin: const EdgeInsets.fromLTRB(6, 15, 20, 12),
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final isSelected = selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => selectedFilterIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryMuted : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? primaryMuted : Colors.grey[300]!,
                          ),
                          boxShadow: isSelected ? [] : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.03),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          filters[index],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            Expanded(
              child: isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Loading appointments...",
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
                  : list.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_busy, size: 40, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No appointments found",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDate != null
                          ? "No appointments on ${DateFormat("dd MMM yyyy").format(selectedDate!)}"
                          : "Try changing your filters",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) => appointmentCard(list[index], index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}