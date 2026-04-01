import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/user_model.dart';

class ApiService{
  static const String baseUrl = 'http://192.168.29.190:3000';
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
}