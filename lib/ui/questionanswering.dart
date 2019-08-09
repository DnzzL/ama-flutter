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
  var client = new http.Client();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _summaryController = TextEditingController();
  bool isImageLoaded = false;
  bool isTextFieldVisible = false;
  bool summaryMode = false;
  bool conversationMode = false;

  Widget _buildButtonColumn(
      Color color, IconData icon, String label, Function() onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: new Icon(icon),
          color: color,
          onPressed: onPressed,
          iconSize: 32,
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getButtonSection() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumn(Theme.of(context).accentColor, Icons.short_text,
              'Summary', _summarize),
          _buildButtonColumn(Theme.of(context).accentColor,
              Icons.question_answer, 'Q&A', _toConversation),
          _buildButtonColumn(
              Theme.of(context).accentColor, Icons.clear, 'Clear', _clearImage),
        ],
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _image = null;
      isImageLoaded = false;
      isTextFieldVisible = false;
      summaryMode = false;
      conversationMode = false;
    });
  }

  void _toConversation() {
    setState(() {
      summaryMode = false;
      conversationMode = true;
    });
  }



  Future _pickImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);

    setState(() {
      _image = image;
      isImageLoaded = true;
    });
  }

  Future _readText() async {
    setState(() {
      isTextFieldVisible = false;
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
      summaryMode = false;
      conversationMode = true;
      _answerController.text = json.decode(response.body);
      isTextFieldVisible = true;
    });
  }

  Future _summarize() async {
    var text = await _readText();
    var headers = {"Content-Type": "application/json"};
    var request = {'text': text};

    var response = await http.post("http://10.0.2.2:8000/summarize",
        headers: headers, body: json.encode(request));
    setState(() {
      summaryMode = true;
      conversationMode = false;
      _summaryController.text = json.decode(response.body);
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
            new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: Center(
                  child: _image == null
                      ? new Column(
                          children: <Widget>[
                            new Container(
                              margin: new EdgeInsets.symmetric(horizontal: 4.0),
                              child: new IconButton(
                                icon: new Icon(Icons.photo_library),
                                onPressed: _pickImage,
                                iconSize: 60,
                              ),
                            ),
                            new Container(
                              margin: new EdgeInsets.symmetric(vertical: 5.0),
                              child: Text('Select an image'),
                            ),
                          ],
                        )
                      : Container(
                          height: 300.0,
                          width: 300.0,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: FileImage(_image),
                                  fit: BoxFit.cover))),
                )),
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
        child: new Row(
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
                  )
                ],
              )
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
                child: new TextField(
              decoration: InputDecoration(labelText: 'Answer'),
              readOnly: true,
              controller: _answerController,
            )),
          ],
        ),
      ), //new
    );
  }

  Widget _buildSummaryComposer() {
    return new Container(
      //modified
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: new Row(
        children: <Widget>[
          new Flexible(
              child: new TextField(
            decoration: InputDecoration(labelText: 'Answer'),
            readOnly: true,
            controller: _summaryController,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(
      children: <Widget>[
        _buildImageComposer(),
        isImageLoaded ? _getButtonSection() : new Container(),
        SizedBox(height: 15.0),
        isImageLoaded & summaryMode ? _buildSummaryComposer() : new Container(),
        SizedBox(height: 15.0),
        isImageLoaded & conversationMode
            ? new Column(
                children: <Widget>[
                  _buildQuestionComposer(),
                  _buildAnswerComposer(),
                ],
              )
            : new Container(),
      ],
    )));
  }
}
