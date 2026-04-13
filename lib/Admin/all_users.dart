import 'package:acupuncture/api/api_service.dart';
import 'package:acupuncture/booking_history.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {

  late Future<List<Map<String, dynamic>>> futureUsers;

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
  }

  /// ✅ Fetch + store users
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await ApiService().allUsers();

    allUsers = data;
    filteredUsers = data;

    return data;
  }

  /// 🔍 Search function
  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers = allUsers;
    } else {
      filteredUsers = allUsers.where((user) {
        final name = (user["name"] ?? "").toString().toLowerCase();
        final phone = (user["phone_number"] ?? "").toString();

        return name.contains(query.toLowerCase()) ||
            phone.contains(query);
      }).toList();
    }
    setState(() {});
  }

  /// 👤 Card UI
  Widget userCard(Map<String, dynamic> user) {
    String name = user["name"] ?? "No Name";
    String phone = user["phone_number"] ?? "No Phone";
    String userId = user["user_id"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.indigo,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(phone,
                        style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () {
              if (userId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BookingHistoryScreen(userId: userId),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward,
                  color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  /// 🔄 Pull to refresh
  Future<void> refreshUsers() async {
    final data = await ApiService().allUsers();
    setState(() {
      allUsers = data;
      filteredUsers = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [

          /// 🔥 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patients",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Manage users & appointments",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 8)
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: filterUsers,
                decoration: const InputDecoration(
                  hintText: "Search patients...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// 📋 LIST
          Expanded(
            child: FutureBuilder(
              future: futureUsers,
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Failed to load users"));
                }

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return RefreshIndicator(
                  onRefresh: refreshUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      return userCard(filteredUsers[index]);
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}