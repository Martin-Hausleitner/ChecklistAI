import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gpt_vision_leaf_detect/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Analysis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class InputWidget extends StatefulWidget {
  final Map<String, dynamic> jsonData;

  const InputWidget({Key? key, required this.jsonData}) : super(key: key);

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  @override
  Widget build(BuildContext context) {
    var allItems = [
      ..._buildCheckboxList(),
      ..._buildTextFieldList(),
      ..._buildNumberInputList(),
    ];
    return ListView.builder(
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        return allItems[index];
      },
    );
  }

  List<Widget> _buildCheckboxList() {
    return (widget.jsonData['checkbox'] ?? []).map<Widget>((item) {
      return CheckboxListTile(
        title: Text(item['label'] ?? ''),
        value: item['checked'] ?? false,
        onChanged: (bool? value) {
          setState(() {
            item['checked'] = value ?? false;
          });
        },
      );
    }).toList();
  }

  List<Widget> _buildNumberInputList() {
    return (widget.jsonData['numberinput'] ?? []).map<Widget>((item) {
      return ListTile(
        title: TextField(
          decoration: InputDecoration(
            labelText: item['label'] ?? '',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ], // Only numbers can be entered
          onChanged: (value) {
            item['value'] = int.tryParse(value) ?? 0;
          },
        ),
      );
    }).toList();
  }

  List<Widget> _buildTextFieldList() {
    return (widget.jsonData['textfield'] ?? []).map<Widget>((item) {
      return ListTile(
        title: TextField(
          decoration: InputDecoration(
            labelText: item['label'] ?? '',
          ),
          onChanged: (value) {
            item['value'] = value;
          },
        ),
      );
    }).toList();
  }
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _response = '';
  final apiService = ApiService();

  Future<void> _pickImage(ImageSource source) async {
    print('Image picking started');
    final pickedFile =
        await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      print('Image picked successfully');
      setState(() {
        _image = File(pickedFile.path);
      });
    }

    if (_image != null) {
      print('Sending image to GPT4 Vision');
      _response = await apiService.sendImageToGPT4Vision(image: _image!) ?? '';
      print('Response received: $_response');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building widget');
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Analysis'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_response),
            SizedBox(height: 20),
            _response.isEmpty
                ? Container()
                : (() {
                    print('Processing response');
                    var trimmedResponse = _response
                        .replaceAll('```json\n', '')
                        .replaceAll('\n```', '');
                    try {
                      var jsonData = jsonDecode(trimmedResponse);
                      print('Response is valid JSON');
                      return Expanded(
                        child: InputWidget(
                          jsonData: jsonData,
                        ),
                      );
                    } catch (e) {
                      print('The provided string is not a valid JSON string.');
                      return Text(
                          trimmedResponse); // Display the trimmedResponse as a Text widget even if it's not a valid JSON string.
                    }
                  }()),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: 'Take Picture',
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Pick Image from gallery',
            child: Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }
}

// class _HomePageState extends State<HomePage> {
//   Map<String, dynamic> jsonData = {
//     "checkbox": [],
//     "textfield": [],
//   };

//   void updateInputWidget() {
//     setState(() {
//       jsonData = {
//         "checkbox": [
//           {
//             "label": "Hallo",
//             "checked": false,
//           },

//         ],
//         "textfield": [
//           {
//             "label": "Dein Name",
//             "value": "",
//           },

//         ],
//         "numberinput": [
//           {
//             "label": "Geben Sie eine andere Zahl ein",
//             "value": 0,
//           },
//         ],
//       };
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home Page'),
//       ),
//       body: Column(
//         children: [
//           ElevatedButton(
//             child: Text('Update Input Widget'),
//             onPressed: updateInputWidget,
//           ),
//           Expanded(
//             // Add this
//             child: InputWidget(jsonData: jsonData),
//           ),
//         ],
//       ),
//     );
//   }
// }
