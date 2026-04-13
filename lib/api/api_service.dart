import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../model/user_model.dart';

class ApiService{
  static const String baseUrl = 'https://acupuncturemapp.sssbi.com';
  Dio dio = Dio();
  Future<User?> registerUser(String name, String phonenumber, String password) async {
    final response = await dio.post(
      '$baseUrl/registerUser',
      data: {
        'name': name,
        'phone_number': phonenumber,
        'password': password,
         'user_id' : name,
      },
    );

    if (response.statusCode == 200) {
      print(response.data);
      return User.fromJson(response.data);
    } else {
      throw Exception('Failed to register user');
    }
  }
  Future<User>loginUser(String phonenumber, String password) async {
    print('Attempting to login with phone: $phonenumber and password: $password');
    final response = await dio.post(
      '$baseUrl/login',
      data: {
        'phone_number': phonenumber,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      print(response.data);
      return User.fromJson(response.data);
    } else {
      throw Exception('Failed to login user');
    }
  }
  Future<Map<String,dynamic>>bookSlot(String userId, String date, String time,int sessionNumber) async {
    final response = await dio.post(
      '$baseUrl/bookSlot',
      data: {
        'user_id': userId,
        'date': date,
        'slot': time,
        'session_number': sessionNumber
      },
    );

    if (response.statusCode == 200) {
      print(response.data);
      return response.data;
    } else {
      throw Exception('Failed to book slot');
    }
  }
  Future<List<dynamic>> getServices() async {
    final response = await dio.get("$baseUrl/services");

    if (response.statusCode == 200) {
      return response.data["services"]; // 👈 FIX HERE
    } else {
      throw Exception("Failed to Load Services");
    }
  }

  Future<Map<String,dynamic>> getUserBookings(String userId) async {
    print(userId);
    final response = await dio.post(
      '$baseUrl/getUserSlots',
      data: {
        'user_id': userId,
      },
    );

    if (response.statusCode == 200) {
      print(response.data);
      return response.data;
    } else {
      throw Exception('Failed to fetch user bookings');
    }
  }
  Future<Map<String,dynamic>> cancelBooking(bookingId,String status) async {
    final response = await dio.post(
      '$baseUrl/updateSlotStatus',
      data: {
        'id': bookingId,
        'status': status,
      },
    );

    if (response.statusCode == 200) {
      print(response.data);
      return response.data;
    } else {
      throw Exception('Failed to cancel booking');
    }
  }
  Future<List<Map<String, dynamic>>> allUsers() async {
    final response = await dio.get('$baseUrl/getAllUsers');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;

      if (data['status'] == "Users fetched successfully") {

        // ✅ Directly return List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(data['users']);

      } else {
        throw Exception('API error');
      }
    } else {
      throw Exception('Failed to fetch users');
    }
  }
  //get All slots
  Future<List<Map<String, dynamic>>> allSlots() async {
    final response = await dio.get('$baseUrl/getAllSlots');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;

      if (data['status'] == "Slots fetched successfully") {
        print(data);
        // ✅ Directly return List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(data['slots']);

      } else {
        throw Exception('API error');
      }
    } else {
      throw Exception('Failed to fetch slots');
    }
  }
  //get user details by passing user id in the body
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    print("Fetching details for user ID: $userId");
    try {
      final response = await dio.post(
        '$baseUrl/getUserDetails',
        data: {'user_id': userId},
      );

      print("USER RESPONSE: ${response.data}");
      return response.data;

    } catch (e) {
      print("USER API ERROR: $e");
      rethrow;
    }
  }
 Future<Map<String,dynamic>>updateSessions(int id, int sessionNumber,  int service_id,String date,String slot_time, DateTime dateTime,) async {
    String fullDateTime =
    DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
    final response = await dio.put(
      '$baseUrl/updateSession',
      data: {
        'id': id,
        'session_number': sessionNumber,
        'treatment_id' : service_id,
         'booking_date': date,
          'slot_time': slot_time,
         'created_at':fullDateTime
      },
    );

    if (response.statusCode == 200) {
      print(response.data);
      return response.data;
    } else {
      throw Exception('Failed to update sessions');
    }
  }

  Future<Map<String,dynamic>>getServiceDetails(int serviceId) async {
    final response = await dio.post(
      '$baseUrl/getTreatmentDetails',
       data: {
        'service_id': serviceId,
       }
    );

    if (response.statusCode == 200) {
      print(response.data);
      return response.data;
    } else {
      throw Exception('Failed to fetch service details');
    }
  }
  //mark slot as completed
  Future<Map<String,dynamic>> markSlotCompleted(int id) async {
    final response = await dio.put(
      '$baseUrl/markSlotCompleted',
      data: {
        'id': id,
      },
    );
    return response.data;
  }

  //get blockdates and block slots
  Future<Map<String,dynamic>> getBlockedDates(List<String> dates) async {
    try {
      final response = await dio.post(
        "$baseUrl/getBlockedDate",
        data: {
          "dates": dates, // ✅ sending array
        },
      );

      return response.data;
    } catch (e) {
      print("API Error: $e");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getAllBlockedDates() async {
    try {
      final response = await dio.get("$baseUrl/getAllBlockedDates");

      return response.data;
    } catch (e) {
      print("API Error: $e");
      rethrow;
    }
  }

   deleteAccount(String userId) async {
    try {
      final response = await dio.delete(
        "$baseUrl/deleteAccount",
        data: {
          "user_id": userId,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("Account deleted successfully");
      } else {
        print("Failed: ${response.data}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}