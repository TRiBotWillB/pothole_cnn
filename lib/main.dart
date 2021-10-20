import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData.dark(), home: PotholeDetectionApp());
  }
}

class PotholeDetectionApp extends StatefulWidget {
  const PotholeDetectionApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PotholeDetectionAppState();
}

class _PotholeDetectionAppState extends State<PotholeDetectionApp> {
  XFile? _image;
  List? _results;

  @override
  void initState() {
    super.initState();

    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pothole Detection CNN')),
      body: Column(children: [
        if (_image != null)
          Container(
              margin: const EdgeInsets.all(10),
              child: Image.file(File(_image!.path)))
        else
          Container(
            margin: const EdgeInsets.all(40),
            child: const Opacity(
              opacity: 0.6,
              child: Center(
                child: Text('No Image Selected!'),
              ),
            ),
          ),
        SingleChildScrollView(
          child: Column(
            children: _results != null
                ? _results!.map((result) {
                    return Card(
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Text(
                          "${result["label"]} -  ${result["confidence"].toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList()
                : [],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
          onPressed: selectImage,
          tooltip: 'Select an image',
          child: const Icon(Icons.search)),
    );
  }

  Future loadModel() async {
    Tflite.close();

    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/label.txt"
    );

    print("Loaded model");
  }

  Future selectImage() async {
    var imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    classifyImage(imageFile);
  }

  Future classifyImage(XFile? image) async {
    final List? results = await Tflite.runModelOnImage(
      path: image!.path,
      numResults: 2,
      threshold: 0.2,
      imageMean: 0,
      imageStd: 255,
    );

    setState(() {
      _results = results;
      _image = image;
    });
  }
}
