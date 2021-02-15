# flutter_deepspeech Eqra Version (Al Fateha)
# EQRATECH.COM | Feras Melhem | 0799449242
# Getting Started
# 1- add to (pubspec.yaml)  :
  ## 1- 1- under dependencies (maybe you need to change username) ":

```python

  flutter_deepspeech:
    git:
      url: https://feras_m@bitbucket.org/feras_m/flutter_deepspeech.git
      ref: master
```
  ## 1- 2- under assets (copy assets file from example of the project) then add below to pubspec.yaml ":
  ```python
  
  assets:
    - assets/arabic.scorer
    - assets/arabic.tfliter
    
```

## ## #### ## #### ## #### ## ## # ## #### ## #### ## #### ## ##
## 2- add (android/app/build.gradle) in dependencies (last line) :

```python

  implementation fileTree(dir: 'libs', include: ['*.jar'])
  
```

## ## #### ## #### ## #### ## ## # ## #### ## #### ## #### ## ##


## 3- add (android/app/src/main/AndroidManifest.xml) in <manifest> :


```python
 <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
 <uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## ## #### ## #### ## #### ## ## # ## #### ## #### ## #### ## ##


## 4- in (android/app/src/main/kotlin/<project name>/MainActivity.kt) :
  ## 4- 1- before import add ":
```python

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import androidx.core.app.ActivityCompat
```
  ## 4- 2- inside "Flutter Activiy()){ ":
```python

   private fun checkAudioPermission() {
        // Permission is automatically granted on SDK < 23 upon installation.
        if (Build.VERSION.SDK_INT >= 23) {
            val permission = Manifest.permission.RECORD_AUDIO

            if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(permission), 3)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAudioPermission()
    }
```
## ## #### ## #### ## #### ## #### ## #### ## #### ## #### ## #### ## #### ## ##
## then in main or any lib file use the example down :

```python

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_deepspeech/flutter_deepspeech.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String recognizedText = '';
  bool initialized = false;
  bool recognizing = false;

  StreamSubscription partialResultsSubscription;

  Future<File> ensureFileInDir(String fileName, String dirPath) async {
    final file = File("$dirPath/$fileName");
    final exists = await file.exists();
    if (exists) {
      print("$fileName in dir");
      return file;
    }
    final fileBytes = await rootBundle.load("assets/$fileName");
    final buffer = fileBytes.buffer;
    await file.writeAsBytes(
        buffer.asUint8List(fileBytes.offsetInBytes, fileBytes.lengthInBytes));
    print("$fileName moved from assets folder");
    return file;
  }

  Future<void> initDeepSpeech() async {
    final docDir = await getApplicationDocumentsDirectory();
    final model = await ensureFileInDir("arabic.tflite", docDir.path);
    final scorer = await ensureFileInDir("arabic.scorer", docDir.path);
    await FlutterDeepSpeech.init(model.path, 4096, scorer.path);
  }

  @override
  void initState() {
    super.initState();
    initDeepSpeech().then((value) {
      setState(() {
        initialized = true;
      });
      partialResultsSubscription =
          FlutterDeepSpeech.partialResults.listen((event) {
        setState(() {
          recognizedText = event;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    partialResultsSubscription?.cancel();
  }

  Future<void> buttonHandler() async {
    if (!recognizing){
      await FlutterDeepSpeech.start();
      setState(() {
        recognizedText = "";
      });
    } else {
      final finalResult = await FlutterDeepSpeech.finish();
      print("Final result: $finalResult");
      setState(() {
        recognizedText = finalResult;
      });
    }
    setState(() {
      recognizing = !recognizing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter DeepSpeech Demo'),
        ),
        body: Center(
          child: Column(
            children: [
              Spacer(),
              Text('Recognized: $recognizedText\n',
                  style:
                      TextStyle(fontSize: 23.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 50.0),
              Container(
                  child: initialized
                      ? RaisedButton(
                          child: Text(recognizing ? "STOP" : "START"),
                          onPressed: buttonHandler)
                      : null),
              Spacer()
            ],
          ),
        ),
      ),
    );
  }
}
```