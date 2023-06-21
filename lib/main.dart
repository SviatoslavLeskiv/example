import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tesseract Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Tesseract Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _ocrText = '';
  String _ocrHocr = '';
  Map<String, String> tessimgs = {
    "kor":
        "https://raw.githubusercontent.com/khjde1207/tesseract_ocr/master/example/assets/test1.png",
    "en": "https://tesseract.projectnaptha.com/img/eng_bw.png",
    "ch_sim": "https://tesseract.projectnaptha.com/img/chi_sim.png",
    "ru": "https://tesseract.projectnaptha.com/img/rus.png",
  };
  var LangList = [
    "deu",
    "eng",
    "spa",
    "fra",
    "ita",
    "jpn",
    "kor",
    "gla",
    "por",
    "rus",
    "swe",
    "chi_sim",
  ];
  var selectList = [
    "deu",
    "eng",
    "spa",
    "fra",
    "ita",
    "jpn",
    "kor",
    "gla",
    "por",
    "ukr",
    "rus",
    "swe",
    "chi_sim"
  ];
  String path = "";
  bool bload = false;

  bool bDownloadtessFile = false;
  // "https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FqCviW%2FbtqGWTUaYLo%2FwD3ZE6r3ARZqi4MkUbcGm0%2Fimg.png";
  var urlEditController = TextEditingController()
    ..text = "https://tesseract.projectnaptha.com/img/eng_bw.png";

  void runFilePiker() async {
    // android && ios only
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _ocr(pickedFile.path);
    }
  }

  void _ocr(String path) async {
    var langs = selectList.join("+");

    _ocrText =
        await FlutterTesseractOcr.extractText(path, language: langs, args: {
      "preserve_interword_spaces": "1",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SimpleDialog(
                                    title: const Text('Select Url'),
                                    children: tessimgs
                                        .map((key, value) {
                                          return MapEntry(
                                              key,
                                              SimpleDialogOption(
                                                  onPressed: () {
                                                    urlEditController.text =
                                                        value;
                                                    setState(() {});
                                                    Navigator.pop(context);
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Text(key),
                                                      Text(" : "),
                                                      Flexible(
                                                          child: Text(value)),
                                                    ],
                                                  )));
                                        })
                                        .values
                                        .toList(),
                                  );
                                });
                          },
                          child: Text("urls")),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'input image url',
                        ),
                        controller: urlEditController,
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          _ocr(urlEditController.text);
                        },
                        child: Text("Run")),
                  ],
                ),
                Row(
                  children: [
                    ...LangList.map((e) {
                      return Row(children: [
                        Checkbox(
                            value: selectList.indexOf(e) >= 0,
                            onChanged: (v) async {
                              // dynamic add Tessdata
                              if (kIsWeb == false) {
                                Directory dir = Directory(
                                    await FlutterTesseractOcr
                                        .getTessdataPath());
                                if (!dir.existsSync()) {
                                  dir.create();
                                }
                                bool isInstalled = false;
                                dir.listSync().forEach((element) {
                                  String name = element.path.split('/').last;
                                  // if (name == 'deu.traineddata') {
                                  //   element.delete();
                                  // }
                                  isInstalled |= name == '$e.traineddata';
                                });
                                if (!isInstalled) {
                                  bDownloadtessFile = true;
                                  setState(() {});
                                  HttpClient httpClient = new HttpClient();
                                  HttpClientRequest request =
                                      await httpClient.getUrl(Uri.parse(
                                          'https://github.com/tesseract-ocr/tessdata/raw/main/${e}.traineddata'));
                                  HttpClientResponse response =
                                      await request.close();
                                  Uint8List bytes =
                                      await consolidateHttpClientResponseBytes(
                                          response);
                                  String dir = await FlutterTesseractOcr
                                      .getTessdataPath();
                                  print('$dir/${e}.traineddata');
                                  File file = new File('$dir/${e}.traineddata');
                                  await file.writeAsBytes(bytes);
                                  bDownloadtessFile = false;
                                  setState(() {});
                                }
                                print(isInstalled);
                              }
                              if (selectList.indexOf(e) < 0) {
                                selectList.add(e);
                              } else {
                                selectList.remove(e);
                              }
                              setState(() {});
                            }),
                        Text(e)
                      ]);
                    }).toList(),
                  ],
                ),
                Expanded(
                    child: ListView(
                  children: [
                    path.length <= 0
                        ? Container()
                        : path.indexOf("http") >= 0
                            ? Image.network(path)
                            : Image.file(File(path)),
                    bload
                        ? Column(children: [CircularProgressIndicator()])
                        : Text(
                            '$_ocrText',
                          ),
                  ],
                ))
              ],
            ),
          ),
          Container(
            color: Colors.black26,
            child: bDownloadtessFile
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text('download Trained language files')
                    ],
                  ))
                : SizedBox(),
          )
        ],
      ),

      floatingActionButton: kIsWeb
          ? Container()
          : FloatingActionButton(
              onPressed: () {
                runFilePiker();
                // _ocr("");
              },
              tooltip: 'OCR',
              child: Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
