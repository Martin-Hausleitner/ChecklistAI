import 'dart:convert';
import 'dart:html' as html show File, FileReader;
import 'dart:io' as io show File, HttpException, HttpHeaders;
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<String> encodeImage(html.File image) async {
    final reader = html.FileReader();
    reader.readAsDataUrl(image.slice(0, image.size, image.type));
    await reader.onLoad.first;
    print('Image encoded successfully');
    return reader.result as String;
  }

  Future<String> sendMessageGPT({required String diseaseName}) async {
    try {
      print('Sending message to GPT...');
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
        print('Error received from API: ${jsonResponse['error']["message"]}');
        throw HttpException(jsonResponse['error']["message"]);
      }

      print('Message sent successfully');
      return jsonResponse["choices"][0]["message"]["content"];
    } catch (error) {
      print('Error: $error');
      throw Exception('Error: $error');
    }
  }

  Future<String> sendImageToGPT4Vision({
    required io.File image,
    int maxTokens = 1000,
    String model = "gpt-4-vision-preview",
  }) async {
    final String base64Image = await encodeImage(image);

    try {
      print('Sending image to GPT4 Vision...');
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
        print('Error received from API: ${jsonResponse['error']["message"]}');
        throw HttpException(jsonResponse['error']["message"]);
      }

      print('Image sent successfully');
      return jsonResponse["choices"][0]["message"]["content"];
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
}
