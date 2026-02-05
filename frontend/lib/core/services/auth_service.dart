import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';

class AuthService {

  static Future<void> sendOtp(String phone, String captchaId, String captchaValue) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "captcha_id": captchaId,
        "captcha_value": captchaValue,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Failed to send OTP");
    }
  }

  static Future<Map<String, String>> getCaptcha() async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/captcha"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load captcha");
    }

    final data = jsonDecode(response.body);
    return {"captchaID": data["captcha_id"]};
  }
  
  static Future<Map<String, dynamic>> getCitizenHome(String token) async {
  final res = await http.get(
    Uri.parse("${ApiConstants.baseUrl}/api/citizen/home"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to load dashboard");
  }

  return jsonDecode(res.body);
}


  static Future<String> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/auth/citizen/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "code": otp,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Invalid OTP");
    }

    final data = jsonDecode(response.body);
    return data["token"];
  }
  static Future<Map<String, String>> authHeaders() async {
  final token = await TokenStorage.getToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

}
