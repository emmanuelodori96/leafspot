import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/data_controller.dart';
import '../util/circular_progress.dart';
import 'discussion_room.dart';

class LeafSpotDetectionScreen extends StatefulWidget {

  LeafSpotDetectionScreen({Key? key,}) : super(key: key);

  @override
  State<LeafSpotDetectionScreen> createState() => _LeafSpotDetectionScreenState();
}

class _LeafSpotDetectionScreenState extends State<LeafSpotDetectionScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> yoloResults = [];
  final FlutterVision vision = FlutterVision();
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;
  bool _processing = false;
  String? _disease;
  double _confidence = 0.0;
  String? _recommendation;
  TabController? _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String detectedDisease = "leaf_spot"; // Assume this is detected by your model
  String userRegion = "unknown"; // This will be updated based on GPS location
  Map<String, dynamic>? recommendation;


  @override
  void initState() {
    super.initState();
    _determinePosition();
    loadYoloModel().then((value) {
      setState(() {
        isLoaded = true;
      });
    });
    _tabController = TabController(length: 4, vsync: this);

  }

  // Example data to upload
  final Map<String, dynamic> recommendationData = {
    'region': 'Juba',
    'disease': 'Leafspot Scale 1',
    'scale': 1,
    'description': 'Description of Leafspot at scale 1',
    'causes': ['Cause 1', 'Cause 2'],
    'prevention_and_cure': ['Prevention 1', 'Recommendation 1'],
  };

  Future<void> uploadRecommendation(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('disease_recommendations').add(data);
      print('Recommendation uploaded successfully!');
    } catch (e) {
      print('Failed to upload recommendation: $e');
    }
  }

  void getRecommendation() async{
    recommendation = await queryRecommendationsByRegion(userRegion);
    saveRecommendationToPreferences(recommendation!);
  }

  Future<Map<String, dynamic>?> queryRecommendationsByRegion(String region) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('disease_recommendations')
          .where('region', isEqualTo: region)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Failed to query recommendations: $e');
      return null;
    }
  }

  Future<void> saveRecommendationToPreferences(Map<String, dynamic> recommendation) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('recommendation_${recommendation['region']}_${recommendation['disease']} Scale ${recommendation['scale']}', jsonEncode(recommendation));
    print('Data has been successfully saved in the shared preferences');
  }

  Future<Map<String, dynamic>?> loadRecommendationFromPreferences(String region, String disease ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? recommendationString = prefs.getString('recommendation_${region}_$disease');
    if (recommendationString != null) {
      return jsonDecode(recommendationString) as Map<String, dynamic>;
    }
    return null;
  }


  @override
  void dispose() async {
    super.dispose();
    vision.closeYoloModel();
  }



  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _getAddressFromLatLng(position);
    print(userRegion);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        userRegion = place.locality ?? "unknown";
      });
      getRecommendation();
    } catch (e) {
      print(e);
    }
  }





  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      loadYoloModel();
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );

    }
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.loose,
              children: [
                imageFile != null ? Image.file(
                  imageFile!,
                  fit: BoxFit.fill,
                  scale: 0.4,
                )
                    :Container(
                  alignment: Alignment.center,
                  height: MediaQuery.of(context).size.width* 0.8,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      image: (imageFile!= null)
                          ? DecorationImage(
                        image: FileImage(imageFile!),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: imageFile == null? const Color(0xffC4C4C4).withOpacity(0.2): Colors.transparent,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Your processed image with the detected disease shall appear hear",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Time New Roman'
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),


                ),
                ...displayBoxesAroundRecognizedObjects(size),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Pick or Take an image",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Time New Roman'
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              ElevatedButton(
                onPressed: !_processing? () {
                  setState(() {
                    imageFile = null;
                    _confidence = 0.0;
                    _disease = null;
                    _recommendation =null;
                    yoloResults = [];
                  });
                  imageDialog(context, true);
                  getRecommendation();
                }:null,
                child: Image.asset(
                  'assets/uploadIcon.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ],
          ),
          Expanded(
            flex: 6,
            child: NestedScrollView(
              body:_processing
                  ? Align(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    CircularProgressIndicator(
                      value: _confidence,
                    ),
                    const Text(
                      'Processing...',
                      style: TextStyle(fontSize: 16.0),
                    )
                  ],
                ),
              )
                  : imageFile != null &&_disease != null?
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    labelColor: Colors.green,
                    dividerColor: Colors.transparent,
                    tabAlignment: TabAlignment.start,
                    unselectedLabelColor: DataController().isDarkMode.value? Colors.white:Colors.black,
                    onTap: (index){},
                    labelStyle: const TextStyle(
                        fontSize: 20
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    indicator: const ShapeDecoration(
                      shape: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue, // Set the color to transparent
                          width: 2,
                        ),
                      ),
                    ),
                    tabs: const [
                      Text("Results"),
                      Text("Overview"),
                      Text("Causes"),
                      Text("Prevention & Cure"),

                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 100.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Text(
                                      "The Confidence of result is:",
                                      style: TextStyle(
                                          fontSize: 16, fontFamily: 'Time New Roman'),
                                    ),
                                    SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: CustomPaint(
                                        painter: CircleProgressBar(
                                          percentage: _confidence,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Disease: $_disease',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Time New Roman'),
                              ),

                              const SizedBox(height: 10.0),
                              Text('$_recommendation',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Time New Roman'
                                ),
                              ),

                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Image.file(
                                      imageFile!,
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Text(_disease!,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Time New Roman'),
                                  ),
                                ],
                              ),
                             const Text(
                                "Groundnut leaf spot is a common fungal disease affecting groundnut (peanut) plants, caused by various pathogens such as Cercospora arachidicola and Cercosporidium personatum. It typically manifests as small, dark spots on the leaves, which can merge and cause extensive damage if not managed properly",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Time New Roman'),
                              ),
                              const SizedBox(height: 20.0),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(recommendation!['description']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: (recommendation!['causes'] as List<dynamic>)
                                .map((cause) => ListTile(title: Text(cause)))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: (recommendation!['prevention_and_cure'] as List<dynamic>)
                                .map((item) => ListTile(title: Text(item)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),


                ],
              )
                  :Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'After selecting an image processing it your results will appear here with recommendation based on your location $userRegion',
                  style: const TextStyle(
                      fontSize: 20, fontFamily: 'Time New Roman'),
                  textAlign: TextAlign.center,
                ),
              ), headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) { return []; },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Get.to(()=> DiscussionRoom());
        },
        tooltip: 'Message',
        child: const Icon(Icons.message_rounded),
      ),
    );

  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        modelPath:  'assets/leafspot_identifier_model.tflite',
        labels: 'assets/labels_leafspot.txt',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: false);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Capture a photo
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);
      });
    }
  }



  yoloOnImage() async {
    setState(() {
      _processing = true;
    });

    yoloResults.clear();
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;

    try {
      final result = await Future.delayed(const Duration(seconds: 5), () {
        print("Model has started running");
        return vision.yoloOnImage(
          bytesList: byte,
          imageHeight: image.height,
          imageWidth: image.width,
          iouThreshold: 0.8,
          confThreshold: 0.4,
          classThreshold: 0.5,
        );
      });
      print("Model has completed running successfully");

      if (result.isNotEmpty) {
        setState(() {
          yoloResults = result;
          _processing = false;
        });
        _processResults(result);
      } else {
        setState(() {
          _processing = false;
        });
        // Handle case where No results obtained
        result.isEmpty?
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No results obtained'),
            content: const Text('Either your image is unclear or it is not groundnut leaf'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ):showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delay'),
            content: const Text('The model is taking too much time in processing'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processing = false;
      });
      // Handle timeout or other errors
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('An error occurred while processing the image.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / imageWidth;
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / imageHeight;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      double boxWidth = (result["box"][2] - result["box"][0]) * factorX * 0.8;
      double boxHeight = (result["box"][3] - result["box"][1]) * factorY * 0.8;

      // Calculate text width using TextPainter
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text:
          "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
          style: const TextStyle(fontSize: 18.0),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      double textWidth = textPainter.size.width;

      if (textWidth > boxWidth) {
        // Increase box width if tag text doesn't fit
        boxWidth = textWidth + 20;
      }

      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: boxWidth,
        height: boxHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                background: Paint()..color = colorPick,
                color: Colors.white,
                fontSize: 18.0,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _processResults(List<dynamic> results) {
    // Assume results are in the format [disease, confidence]
    _disease = results[0]['tag'];
    _confidence = results[0]['box'][4];
    final connectivityResult = (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      getRecommendation();
    }
    else{
      loadRecommendationFromPreferences(userRegion, _disease!);

    }

    loadRecommendationFromPreferences(userRegion, _disease!);

  }

  String? _getRecommendationForDisease(String? disease) {
    // Implement your logic to provide recommendations for different diseases
    return "Recommendations for $_disease";
  }

  getImageDialog(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final pickedImage = await picker.pickImage(
      source: source,
    );

    if (pickedImage != null) {
      setState(() {
        imageFile = File(pickedImage.path);
        yoloOnImage();
      });
    }
  }

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recommendations on $_disease:',
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              const Text(
                '1. Practice good field sanitation.\n'
                    '2. Use disease-resistant crop varieties.\n'
                    '3. Implement integrated pest management strategies.\n'
                    '4. Consult with agricultural experts for guidance.',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        );
      },
    );
  }

  void imageDialog(BuildContext context, bool image) {
    showDialog(
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Media Source"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    onPressed: () {
                      if (image) {
                        getImageDialog(ImageSource.gallery);
                        Navigator.pop(context);
                      } else {}
                    },
                    icon: const Icon(Icons.image)),
                IconButton(
                    onPressed: () {
                      if (image) {
                        getImageDialog(ImageSource.camera);
                        Navigator.pop(context);
                      } else {}
                    },
                    icon: const Icon(Icons.camera_alt)),
              ],
            ),
          );
        },
        context: context);
  }
}