import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:location/location.dart';

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
  LocationData? _location;

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
              child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: Image.file(File(_image!.path), fit: BoxFit.cover)))
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
            children: _results != null && _results!.isNotEmpty
                ? [
                    ..._results!.map((result) {
                      return Card(
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          child: Text(
                            "${result["label"]} -  ${result["confidence"].toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                    Card(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        child: Text(
                          "Location: ${_location!.latitude}, ${_location!.longitude}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ]
                : [
                    Card(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        child: const Text(
                          "No Potholes detected.",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
          onPressed: selectImage,
          tooltip: 'Select an image',
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.image, color: Colors.white)),
    );
  }

  Future loadModel() async {
    Tflite.close();

    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/label.txt");

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

    // If we have found any potholes, let's log the GPS location
    if (results != null && results.isNotEmpty) {}

    var locationData = await getGpsLocation();

    setState(() {
      _results = results;
      _image = image;
      _location = locationData;
    });
  }

  Future<LocationData?> getGpsLocation() async {
    var completer = Completer<LocationData?>();

    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    completer.complete(await location.getLocation());

    return completer.future;
  }
}
