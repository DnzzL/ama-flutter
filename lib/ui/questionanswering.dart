import 'dart:convert';
import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class QuestionAnswering extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => QuestionAnsweringState();
}

class QuestionAnsweringState extends State {
  File _image;
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool isImageLoaded = false;
  var client = new http.Client();
  bool _isTextFieldVisible = false;

  Future _pickImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);

    setState(() {
      _image = image;
      isImageLoaded = true;
      _questionController.text = "";
      _answerController.text = "";
      _isTextFieldVisible = false;
    });
  }

  Future _readText() async {
    setState(() {
      _isTextFieldVisible = false;
    });
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(_image);
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

  Future _answerQuestion() async {
    var passage = await _readText();
    var question = _questionController.text;
    var headers = {"Content-Type": "application/json"};
    var request = {'passage': passage, 'question': question};

    var response = await http.post("http://10.0.2.2:8000/qa",
        headers: headers, body: json.encode(request));

    setState(() {
      _answerController.text = json.decode(response.body);
      _isTextFieldVisible = true;
    });
  }

  Widget _buildImageComposer() {
    return new IconTheme(
      //new
      data: new IconThemeData(color: Theme.of(context).accentColor), //new
      child: new Container(
        //modified
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: new Column(
          children: <Widget>[
            isImageLoaded
                ? new Container(
                    margin: new EdgeInsets.symmetric(horizontal: 4.0),
                    child: Center(
                      child: _image == null
                          ? new Container(
                              margin: new EdgeInsets.symmetric(vertical: 20.0),
                              child: Text('No image selected.'),
                            )
                          : Container(
                              height: 300.0,
                              width: 300.0,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: FileImage(_image),
                                      fit: BoxFit.cover))),
                    ))
                : Container(),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                  icon: new Icon(Icons.photo_library), onPressed: _pickImage),
            ),
          ],
        ),
      ), //new
    );
  }

  Widget _buildQuestionComposer() {
    return new IconTheme(
      //new
      data: new IconThemeData(color: Theme.of(context).accentColor), //new
      child: new Container(
        //modified
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: _image != null
            ? new Row(
                children: <Widget>[
                  new Flexible(
                    child: new TextField(
                      controller: _questionController,
                      decoration: new InputDecoration.collapsed(
                          hintText: "Ask a question"),
                    ),
                  ),
                  new Container(
                    margin: new EdgeInsets.symmetric(horizontal: 6.0),
                    child: new IconButton(
                        icon: new Icon(Icons.send), onPressed: _answerQuestion),
                  ),
                ],
              )
            : Container(),
      ), //new
    );
  }

  Widget _buildAnswerComposer() {
    return new IconTheme(
      //new
      data: new IconThemeData(color: Theme.of(context).accentColor), //new
      child: new Container(
        //modified
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: _isTextFieldVisible
                  ? new TextField(
                      decoration: InputDecoration(labelText: 'Answer'),
                      readOnly: true,
                      controller: _answerController,
                    )
                  : Container(),
            ),
          ],
        ),
      ), //new
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(
      children: <Widget>[
        _buildImageComposer(),
        SizedBox(height: 15.0),
        _buildQuestionComposer(),
        SizedBox(height: 15.0),
        _buildAnswerComposer()
      ],
    )));
  }
}
