import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

import 'image_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final tfl.Interpreter interpreter;
  late final _inputShape;
  late final _outputShape;
  late final Map percentMap = {};
  XFile? selectedImage;

  @override
  void initState() {
    super.initState();
    initModel();
  }

  initModel() async {
    try {
      final options = tfl.InterpreterOptions();
      interpreter = await tfl.Interpreter.fromAsset('assets/mushroomv2.tflite',
          options: options);
      print('Interpreter Created Successfully');
      options.addDelegate(XNNPackDelegate());

      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;

      final _inputType = interpreter.getInputTensor(0).type;
      final _outputType = interpreter.getOutputTensor(0).type;

      print("inputShape $_inputShape , outputShape $_outputShape");
      print("inputType $_inputType , outputType $_outputType");
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  runModel(XFile image) async {
    List<String> names = [
      'bal',
      'borozan',
      'corek',
      'imparator',
      'istiridye',
      'kanlica',
      'kultur',
      'kuzugobegi',
      'sigirdili',
      'agulu',
      'olummelegi',
      'panter',
      'seytan',
      'sinek'
    ];

    imglib.Image? img = imglib.decodeImage(await image.readAsBytes());

    imglib.Image imageInput = imglib.copyResize(
      img!,
      width: _inputShape[1],
      height: _inputShape[2],
    );

    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        },
      ),
    );

    final input = [imageMatrix];

    final output = [List<double>.filled(_outputShape[1], 0)];

    interpreter.run(input, output);
    final result = output.first;

    Map<String, double> resultMap = {};

    for (var i = 0; i < result.length; i++) {
      resultMap[names[i]] = result[i];
    }

    print(resultMap);

    var maks = result.reduce(max);
    print("MAKS: $maks");

    var percentList = result;
    for (var i = 0; i < result.length; i++) {
      percentList[i] = result[i] * 100;
      print("yuzdelik degerlerrrr:");
      print(" %${percentList[i].round()}");
    }

    for (var i = 0; i < result.length; i++) {
      percentMap[names[i]] = percentList[i].round();
    }

    print(percentMap);

    var sortedByValueMap = Map.fromEntries(percentMap.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value)));

    print(sortedByValueMap);

    setState(() {
      percentMap.clear();
      percentMap.addAll(sortedByValueMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                final img = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxHeight: 300,
                  maxWidth: 300,
                );
                if (img == null) return;
                setState(() {
                  selectedImage = img;
                });
                runModel(img);
              },
              child: Text("Pick image"),
            ),
            if (selectedImage != null)
              Container(
                width: 300,
                height: 300,
                child: Image.file(File(selectedImage!.path)),
              ),
            Column(
              children: percentMap.entries.take(4).map((entry) {
                return ListTile(
                  title: Text(entry.key.toString()),
                  subtitle: Text("%${entry.value.toString()}"),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
