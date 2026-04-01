import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> services = [
    'Traditional Acupuncture',
    'Cupping Therapy',
    'Electroacupuncture',
    'Herbal Consultation',
  ];

  String? selectedService;
  DateTime _selectedDate = DateTime.now();
  String? selectedTimeSlot;

  final Map<String, List<String>> availableTimeSlots = {
    'Morning': ['09:00 AM', '10:00 AM', '11:00 AM'],
    'Afternoon': ['02:00 PM', '03:00 PM', '04:00 PM'],
    'Evening': ['06:00 PM', '07:00 PM'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text('Book Appointment',
            style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceDropdown(),
                const SizedBox(height: 20),
                if (selectedService != null) _buildCalendar(),
                const SizedBox(height: 20),
                if (selectedService != null) _buildTimeSlotSelection(),
                const SizedBox(height: 20),
                if (selectedService != null && selectedTimeSlot != null)
                  _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Service',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: selectedService,
          isExpanded: true,

          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,

            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade700, width: 1.5),
            ),
          ),

          hint: const Text('Choose a service'),

          items: services.map((service) {
            return DropdownMenuItem<String>(
              value: service,
              child: Text(
                service,
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),

          onChanged: (value) {
            setState(() {
              selectedService = value;
              selectedTimeSlot = null;
            });
          },
        ),
      ],
    );
  }
  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TableCalendar(
            focusedDay: _selectedDate,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 14)),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                selectedTimeSlot = null;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.teal.shade700,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.teal.shade200,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableTimeSlots.entries.expand((entry) {
              return entry.value.map((time) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(time),
                    selected: selectedTimeSlot == time,
                    selectedColor: Colors.teal.shade700,
                    onSelected: (selected) {
                      setState(() {
                        selectedTimeSlot = selected ? time : null;
                      });
                    },
                    labelStyle: TextStyle(
                      color: selectedTimeSlot == time
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                );
              });
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _showConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          padding:
          const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Confirm Appointment',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Appointment Confirmed'),
          content: Text(
            'Service: $selectedService\n'
                'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}\n'
                'Time: $selectedTimeSlot',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}