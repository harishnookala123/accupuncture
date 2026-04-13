class User{
  final String name;
  final String phone_number;
  final String password;
  final String userid;
  final String status;
  User({
    required this.name,
    required this.phone_number,
    required this.password,
    required this.userid,
    required this.status
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      phone_number: json['phone_number'] ?? '',
      password: json['password'] ?? '',
      userid: json['userid'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phone_number,
      'password': password,
      'userid': userid,
      'status': status,
    };
  }
}