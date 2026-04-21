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
  Future<Map<String,dynamic>>bookSlot(String userId, String date, String time,
      int sessionNumber) async {
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
    final response = await dio.put(
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
    final response = await dio.get('$baseUrl/ ');

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
  Future<void> updateSessions(String id, List<int> sessions, int treatmentId, List<Map<String, dynamic>> slots, DateTime createdAt) async {
    print(id);
    print(sessions);
    print(treatmentId);
    print(slots);
    print(createdAt);
    try {
      // ✅ Convert to JSON strings before sending
      final response = await dio.put(
        '$baseUrl/updateSession',
        data: {
          'id': id,
          'session_number': jsonEncode(sessions),  // Convert to JSON string
          'treatment_id': treatmentId,
          'slots': jsonEncode(slots),              // Convert to JSON string
          'created_at': createdAt.toIso8601String(),
        },
      );

      print("Update response: ${response.data}");
      return response.data;
    } catch (e) {
      print("Error updating sessions: $e");
      rethrow;
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
  //get slots for particular date
  Future<Map<String, dynamic>> getBookedSlotsForDate(String date) async {
    try {
      final response = await dio.post(
        '$baseUrl/getBookedSlotsForDate',
        data: {'date': date},
      );
      print(response.data.toString() +" Slots");
      return response.data;
    } catch (e) {
      print('Error fetching booked slots for date $date: $e');
      return {'slots': []};
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
  Future<void> saveFcmToken(String userId, String fcmToken) async {
    try {
      final response = await dio.post('$baseUrl/api/save-fcm-token', data: {
        'user_id': userId,
        'fcm_token': fcmToken,
      });
      print('Token saved: ${response.data}');
    } catch (e) {
      print('Error saving token: $e');
      rethrow;
    }
  }
  Future<void> sendNotificationToUser({
    required String userId,
    required int newSessionNumber,
    required formattedDate,
    required selectedSlot,
    required serviceName,
  }) async {
    try {
      final response = await dio.post('$baseUrl/send-booking-confirmation-to-user',
          data: {
            'user_id': userId,
            'session_number': newSessionNumber,
            'date': formattedDate,
            'time': selectedSlot,
            'service_name': serviceName ?? "Acupuncture Session",
            'admin_name': "Admin",
          }
      );
      print('Notification sent: ${response.data}');
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> sendBookingCancellation({
    required String userId,
    required int sessionNumber,
    required String date,
    required String time,
  }) async {
    try {
      final response = await dio.post(
        "$baseUrl/send-booking-cancellation-to-user",
        data: {
          "user_id": userId,
          "session_number": sessionNumber,
          "date": date,
          "time": time,
        },
      );

      print("✅ Cancellation sent: ${response.data}");
    } catch (e) {
      print("❌ Cancellation API error: $e");
      rethrow;
    }
  }

// Add to your ApiService class in api_service.dart

  Future<dynamic> sendNotificationToAdmin({
    required String adminId,
    required String userName,
    required String date,
    required String time,
  }) async {
    print(adminId);

    try {
      final response = await dio.post('$baseUrl/notify-admin-new-booking', data: {
        'admin_id': adminId,
        'user_name': userName,
        'date': date,
        'time': time,
        'type': 'new_booking',
      });
      return response.data;
    } catch (e) {
      print('Error sending admin notification: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  // In api_service.dart - Add the appointmentId to the URL
  // api_service.dart

  Future<void> rescheduleDate(
      int appointmentId,
      List<Map<String, dynamic>> bookingDate,
      ) async {
    try {
      final response = await dio.put(
        '${baseUrl}/appointments/resheduledate',
        data: {
          'id':appointmentId,
          'booking_date': bookingDate,
        },
        options: Options(
          validateStatus: (status) {
            return status! < 500;  // Accept all status codes below 500
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('Rescheduled successfully');
        return;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to reschedule');
      }
    } catch (e) {
      print('Error rescheduling: $e');
      throw e;
    }
  }
}