import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<String> encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> sendMessageGPT({required String diseaseName}) async {
    try {
      final response = await _dio.post(
        "$BASE_URL/chat/completions",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $API_KEY',
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: {
          "model": 'gpt-3.5-turbo',
          "messages": [
            {
              "role": "user",
              "content":
                  "GPT, upon receiving the name of a plant disease, provide three precautionary measures to prevent or manage the disease. These measures should be concise, clear, and limited to one sentence each. No additional information or context is needed—only the three precautions in bullet-point format. The disease is $diseaseName",
            }
          ],
        },
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      return jsonResponse["choices"][0]["message"]["content"];
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<String> sendImageToGPT4Vision({
    required File image,
    int maxTokens = 1000,
    String model = "gpt-4-vision-preview",
  }) async {
    final String base64Image = await encodeImage(image);

    try {
      final response = await _dio.post(
        "$BASE_URL/chat/completions",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $API_KEY',
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Give only in json format back if there a following types: "checkbox": [ { "label": "", "checked": false } ], "textfield": [ { "label": "", "value": "" } ], "numberinput": [ { "label": "", "value": 0 } ] '
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Give only in json format back.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': maxTokens,
        }),
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }
      return jsonResponse["choices"][0]["message"]["content"];
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
