import '../models/user.dart';
import 'api_client.dart';

class AuthApi {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await apiClient.post('/auth/login/', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    return data; // contains 'access' and 'refresh'
  }

  Future<User> register(
    String username,
    String email,
    String password,
  ) async {
    final data = await apiClient.post('/auth/register/', {
      'username': username,
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<User> me() async {
    final data = await apiClient.get('/auth/me/') as Map<String, dynamic>;
    return User.fromJson(data);
  }
}

final authApi = AuthApi();
