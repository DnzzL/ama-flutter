import 'dart:convert';
import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File pickedImage;
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool isImageLoaded = false;
  var client = new http.Client();

  Future pickImage() async {
    var tempStore = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);

    setState(() {
      pickedImage = tempStore;
      isImageLoaded = true;
      _questionController.text = "";
      _answerController.text = "";
    });
  }

  Future readText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    var passage = "";
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          passage = passage + " " + word.text;
        }
      }
    }
    return passage;
  }

  Future answerQuestion() async {
    var passage = await readText();
    var question = _questionController.text;
    var headers = {"Content-Type": "application/json"};
    var request = {'passage': passage, 'question': question};

    var response = await http.post("http://10.0.2.2:8000/qa",
        headers: headers, body: json.encode(request));
    _answerController.text = json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(
      children: <Widget>[
        SizedBox(height: 50.0),
        isImageLoaded
            ? Center(
                child: Container(
                    height: 300.0,
                    width: 300.0,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: FileImage(pickedImage), fit: BoxFit.cover))),
              )
            : Container(),
        SizedBox(height: 10.0),
        IconButton(
          icon: Icon(
            Icons.photo_library,
          ),
          color: Colors.blueAccent,
          iconSize: 30.0,
          tooltip: "Pick an image",
          onPressed: pickImage,
        ),
        Text('Pick an image'),
        SizedBox(height: 10.0),
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Question',
              ),
              controller: _questionController,
            )),
        IconButton(
          icon: Icon(Icons.question_answer),
          color: Colors.blueAccent,
          iconSize: 30.0,
          tooltip: "Answer question",
          onPressed: answerQuestion,
        ),
        Text('Answer question'),
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Answer',
              ),
              readOnly: true,
              controller: _answerController,
            )
        ),
      ],
    )));
  }
}
