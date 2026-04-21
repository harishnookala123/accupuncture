import 'package:acupuncture/Admin/block_date_history.dart';
import 'package:acupuncture/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'all_users.dart';
import 'appointments.dart';
import 'block_date.dart';

class AdminScreen extends StatefulWidget {
  final String? username;

  const AdminScreen({super.key, this.username});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Stats variables
  int todayActive = 0;
  int todayCancelled = 0;
  int totalActive = 0;
  int totalBooked = 0;
  int totalCompleted = 0;
  int totalCancelled = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final slots = await ApiService().allSlots();
      print("Raw slots data: $slots");

      DateTime now = DateTime.now();

      // Reset counters
      int todayActiveCount = 0;
      int todayCancelledCount = 0;
      int activeCount = 0;
      int bookedCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;

      for (var slot in slots) {
        String status = slot["status"]?.toString().toLowerCase() ?? "";
        print("Processing slot - Status: $status");

        // Count by status
        switch (status) {
          case "booked":
            bookedCount++;
            activeCount++;
            print("  -> Booked count: $bookedCount");
            break;
          case "completed":
            completedCount++;
            activeCount++;
            print("  -> Completed count: $completedCount");
            break;
          case "cancelled":
            cancelledCount++;
            print("  -> Cancelled count: $cancelledCount");
            break;
        }

        // Check for today's appointments - Check if booking_date exists
        if (slot.containsKey("booking_date") && slot["booking_date"] != null) {
          try {
            DateTime bookingDate = DateTime.parse(slot["booking_date"]);
            bool isToday = bookingDate.year == now.year &&
                bookingDate.month == now.month &&
                bookingDate.day == now.day;

            print("  -> Booking date: ${slot["booking_date"]}, isToday: $isToday");

            if (isToday) {
              if (status == "cancelled") {
                todayCancelledCount++;
                print("  -> Today cancelled: $todayCancelledCount");
              } else if (status == "booked" || status == "completed") {
                todayActiveCount++;
                print("  -> Today active: $todayActiveCount");
              }
            }
          } catch (e) {
            print("Error parsing date: ${slot["booking_date"]} - $e");
          }
        } else {
          print("  -> No booking_date found for this slot");
        }
      }

      setState(() {
        todayActive = todayActiveCount;
        todayCancelled = todayCancelledCount;
        totalActive = activeCount;
        totalBooked = bookedCount;
        totalCompleted = completedCount;
        totalCancelled = cancelledCount;
        isLoading = false;
      });



    } catch (e) {
      print("Error loading stats: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildStatCard(String title, String value, Color color, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Admin Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Welcome, ${widget.username ?? 'Admin'}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.clear();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isLoading
                ? const Center(
              child: SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            ) : Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      "Today's Active",
                      todayActive.toString(),
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Total Active",
                      totalActive.toString(),
                      const Color(0xFF10B981),
                      subtitle: "$totalBooked booked • $totalCompleted completed",
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (todayCancelled > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          "$todayCancelled cancelled appointment(s) today",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (totalCancelled > 0 && todayCancelled == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "$totalCancelled total cancelled appointments",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Feature Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBlockPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Manage Appointments",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "View and manage all Date Appointments",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Menu Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                physics: ScrollPhysics(),
                scrollDirection: Axis.vertical,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(Icons.people, "Users", const Color(0xFF3B82F6), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UsersScreen()),
                    );
                  }),
                  _buildMenuCard(Icons.analytics, "Reports", const Color(0xFF8B5CF6), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Coming soon"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }),
                  _buildMenuCard(Icons.block, "Block Dates", const Color(0xFFF59E0B), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BlockedDatesScreen()),
                    );
                  }),
                  _buildMenuCard(Icons.history, "All Appointments", const Color(0xFF10B981), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}