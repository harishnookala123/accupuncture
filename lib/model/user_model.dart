class User{
  final String user_name;
  final String phone_number;
  final String password;
  final String user_id;
  final String status;
  User({
    required this.user_name,
    required this.phone_number,
    required this.password,
    required this.user_id,
    required this.status
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      user_name: json['user_name'] ?? '',
      phone_number: json['phone_number'] ?? '',
      password: json['password'] ?? '',
      user_id: json['user_id'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_name': user_name,
      'phone_number': phone_number,
      'password': password,
      'user_id': user_id,
      'status': status,
    };
  }
}