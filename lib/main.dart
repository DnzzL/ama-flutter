import 'package:flutter/material.dart';
import 'package:flutter_mlkit/ui/questionanswering.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color.fromRGBO(0, 162, 103, 1),
        accentColor: Color.fromRGBO(77, 77, 77, 1),
        fontFamily: 'Roboto',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Ask Me Anything"),
      ),
      body: QuestionAnswering(),
    );
  }
}
