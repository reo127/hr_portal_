class User {
  final String userId;
  final String username;
  final String token;
  final String loginTime;

  User({
    required this.userId,
    required this.username,
    required this.token,
    required this.loginTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      token: json['token'] ?? '',
      loginTime: json['loginTimeIST'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'token': token,
      'loginTimeIST': loginTime,
    };
  }

  User copyWith({
    String? userId,
    String? username,
    String? token,
    String? loginTime,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      token: token ?? this.token,
      loginTime: loginTime ?? this.loginTime,
    );
  }
}
