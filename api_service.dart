import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "https://aliya-industrial-unfussily.ngrok-free.dev";

  static Future<bool> sendPrintJob(String otp, File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/process_print'));
      request.fields['otp'] = otp;
      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // Ensure your backend expects the key 'files'
          file.path,
          filename: basename(file.path),
        ),
      );

      // Timeout added to prevent infinite loading if ngrok is down
      final response = await request.send().timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("API Error: $e");
      return false;
    }
  }
}