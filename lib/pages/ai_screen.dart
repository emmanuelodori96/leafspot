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
  TabController? _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String detectedDiseaseScale = "Leafspot Scale 1"; // this will be updated when the model finished running
  String userRegion = "Kampala"; // This will be updated based on GPS location
  late Map<String, dynamic> recommendation;


  @override
  void initState() {
    super.initState();
    _determinePosition();
    loadYoloModel().then((value) {
      setState(() {
        isLoaded = true;
      });
    });
    _tabController = TabController(length: 6, vsync: this);

  }

  // Example data to upload
  final Map<String, dynamic> recommendationData = {
    'region': 'Unknown',
    'disease': 'Early Leafspot',
    'scale': ['Leafspot Scale 1', 'Leafspot Scale 2', 'Leafspot Scale 3'],
    'description': 'Early leaf spot is a common and destructive foliar disease of groundnuts (peanuts) caused by the fungal pathogen Cercospora arachidicola. It is characterized by the appearance of small, brown to black spots on the leaves, which can coalesce to form larger lesions, ultimately leading to defoliation and significant yield losses. The disease is prevalent in regions with warm, humid climates and can affect groundnut crops at various stages of growth, reducing both the quantity and quality of the harvest.',
    'causes': [
      'Temperature: Warm temperatures between 25-30°C (77-86°F) are ideal for the growth and spread of the fungus.',
      'Humidity: High humidity and frequent rainfall create a conducive environment for fungal spores to germinate and infect the plant tissues.',
      'Leaf Wetness: Prolonged periods of leaf wetness due to dew, rain, or irrigation facilitate spore germination and penetration into the leaf surface.',
      'Varietal Susceptibility: Some groundnut varieties are more susceptible to early leaf spot than others. Susceptible varieties lack genetic resistance to the pathogen.',
      'Crop Density: Dense planting can create a microclimate that favors the disease by reducing air circulation and increasing humidity within the canopy.',
      'Previous Crop Residue: Infected plant debris left in the field from previous crops can harbor the fungus and serve as a source of inoculum for new infections.',
    ],
    'prevention_and_cure': [
      'Crop Rotation: Rotate groundnuts with non-host crops such as cereals or legumes to reduce the buildup of the pathogen in the soil.',
      'Resistant Varieties: Plant groundnut varieties that are resistant or tolerant to early leaf spot to minimize disease incidence.',
      'Planting Density: Avoid overly dense planting to improve air circulation and reduce humidity levels within the crop canopy.',
      'Field Sanitation: Remove and destroy infected plant debris after harvest to reduce the amount of inoculum available for the next planting season.',
      'Antagonistic Microorganisms: Utilize beneficial microorganisms such as Trichoderma spp. and Bacillus spp. that can suppress the growth of Cercospora arachidicola through competition or antagonism.',
      'Fungicides: Apply fungicides as a preventive measure or at the onset of the disease. Commonly used fungicides include chlorothalonil, tebuconazole, and mancozeb. Fungicide applications should follow recommended schedules and dosage to be effective and minimize the risk of resistance development.',
    ],
    'cure': [
      'Apply fungicides at regular intervals, starting at the first sign of disease symptoms. Follow label recommendations for dosage and application frequency.',
      'Combine cultural practices, resistant varieties, and fungicide applications in an integrated approach to manage the disease effectively.',
      'Regularly monitor fields for early signs of the disease. Early detection allows for timely intervention and reduces the spread of the disease.',
      'Avoid overhead irrigation during periods of high humidity and leaf wetness. Opt for drip or furrow irrigation to minimize leaf wetness.',
    ],
    'symptoms': [
      'Appearance: Small, circular to irregular spots that are brown to black in color.',
      'Size: Spots are typically 1-10 mm in diameter.',
      'Halos: Spots are often surrounded by yellow halos, giving a "fried egg" appearance on the leaves',
      'Location: Spots primarily appear on the upper surface of older leaves but can also be found on stems, petioles, and pegs in severe cases.',
      'Early Season: The disease typically appears earlier in the growing season compared to late leaf spot.',
      'Coalescence: As the disease progresses, individual spots can merge to form larger, irregularly shaped lesions.',
      'Leaf Tissue Damage: Infected leaf tissue eventually turns necrotic, leading to leaf browning and death.',
      'Premature Leaf Drop: Severe infections can cause premature defoliation, weakening the plant and reducing photosynthetic capacity, ultimately impacting yield.',
      'Stem Lesions: In advanced stages, lesions can spread to stems, appearing as elongated, dark brown to black streaks.',
      'Yield Loss: Early and extensive defoliation can significantly reduce pod formation and kernel development, leading to substantial yield losses.',
    ],
  };
  final Map<String, dynamic> recommendationDataLate = {
    'region': 'Unknown',
    'disease': 'Late Leafspot',
    'scale': ['Leafspot Scale 4', 'Leafspot Scale 5', 'Leafspot Scale 6'],
    'description': 'Late leaf spot is a severe foliar disease of groundnuts (peanuts), caused by the fungal pathogen Phaeoisariopsis personata. It typically manifests later in the growing season compared to early leaf spot. The disease is characterized by the appearance of dark brown to black spots on the leaves, which can merge, leading to significant defoliation and yield loss. Late leaf spot is particularly problematic in tropical and subtropical regions where warm and humid conditions prevail.',
    'causes': [
      'Temperature: The fungus thrives in warm temperatures between 25-30°C (77-86°F).',
      'Humidity: High humidity and frequent rainfall are conducive to the disease, promoting spore germination and infection.',
      'Leaf Wetness: Extended periods of leaf wetness due to dew, rain, or irrigation facilitate fungal penetration into leaf tissues.',
      'Varietal Susceptibility: Certain groundnut varieties are more susceptible to late leaf spot due to genetic factors.',
      'Crop Density: Dense planting can create microenvironments with high humidity, enhancing disease spread.',
      'Previous Crop Residue: Infected plant debris from previous seasons can harbor the fungus, serving as a source of new infections.',

    ],
    'prevention_and_cure': [
      'Crop Rotation: Rotate groundnuts with non-host crops, such as cereals or legumes, to break the disease cycle.',
      'Resistant Varieties: Planting resistant or tolerant groundnut varieties helps reduce disease incidence.',
      'Planting Density: Avoid overly dense planting to improve air circulation and reduce humidity within the canopy.',
      'Field Sanitation: Remove and destroy infected plant debris post-harvest to lower the inoculum load for the next season.',
      'Beneficial Microorganisms: Use antagonistic microorganisms such as Trichoderma spp. and Bacillus spp. to suppress the growth of Phaeoisariopsis personata.',
      'Fungicides: Apply fungicides as a preventive measure or at the onset of symptoms. Common fungicides include chlorothalonil, tebuconazole, and mancozeb. Follow recommended schedules and dosages to ensure efficacy and prevent resistance.',
      '',

    ],
    'cure': [
      'Begin fungicide applications at the first sign of disease symptoms, adhering to label recommendations for dosage and frequency.',
      'Combine cultural practices, resistant varieties, and fungicide treatments for effective disease management.',
      'Regularly monitor fields for early disease symptoms. Early detection allows for timely intervention, reducing disease spread.',
      'Use irrigation methods that minimize leaf wetness, such as drip or furrow irrigation, instead of overhead irrigation.',

    ],
    'symptoms': [
      'Leaf Spots: Dark brown to black spots, often without yellow halos, appearing predominantly on the upper surface of the leaves.',
      'Defoliation: Severe infections lead to premature leaf drop, significantly affecting plant health and yield.',
      'Lesion Appearance: Lesions are generally smaller and darker compared to early leaf spot, and they appear later in the season.',
    ],
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
    recommendation = (await queryRecommendationsByRegionAndScale(userRegion, detectedDiseaseScale))!;
    saveRecommendationToPreferences(recommendation);
  }

  Future<Map<String, dynamic>?> queryRecommendationsByRegionAndScale(String region, String scale) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('disease_recommendations')
          .where('region', isEqualTo: region)
          .where('scale', arrayContains: scale)
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

  Future<bool> checkLeafspotScale(String scale) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('disease_recommendation')
          .where('scale', arrayContains: scale)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle any errors
      return false; // Default to false in case of an error
    }
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
                  : imageFile != null &&_disease != null && recommendation.isNotEmpty?
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
                      Text("Symptoms"),
                      Text("Causes"),
                      Text("Prevention"),
                      Text("Cure"),

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
                                'Disease: ${_disease!.substring(0,8)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Time New Roman'),
                              ),
                              Text(
                                '${_disease!.substring(9,15)}: ${_disease!.substring(15,16)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Time New Roman'),
                              ),

                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: [
                              Text(
                                  recommendation['description'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20,
                                      fontFamily: 'Time New Roman')
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: (recommendation['symptoms'] as List<dynamic>)
                                .map((cause) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.label),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cause,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 20,
                                          fontFamily: 'Times New Roman'),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: (recommendation['causes'] as List<dynamic>)
                                .map((cause) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.label),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cause,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 20,
                                          fontFamily: 'Times New Roman'),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: (recommendation['prevention_and_cure'] as List<dynamic>)
                                .map((cause) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.label),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cause,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 20,
                                          fontFamily: 'Times New Roman'),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView(
                            children: (recommendation['cure'] as List<dynamic>)
                                .map((cause) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.label),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cause,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 20,
                                          fontFamily: 'Times New Roman'),
                                    ),
                                  ),
                                ],
                              ),
                            ))
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
    //Results are in the format [disease, confidence]
    _disease = results[0]['tag'];
    _confidence = results[0]['box'][4];
    detectedDiseaseScale = _disease!.trim();
    final connectivityResult = (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      getRecommendation();
      if(_disease.toString().trim() == 'Leafspot Scale 1'||_disease.toString().trim() == 'Leafspot Scale 2'||_disease.toString().trim() == 'Leafspot Scale 3'){
        recommendation = recommendationData;
      }
      else{
        recommendation = recommendationDataLate;
      }

    }
    else{
      if(_disease.toString().trim() == 'Leafspot Scale 1'||_disease.toString().trim() == 'Leafspot Scale 2'||_disease.toString().trim() == 'Leafspot Scale 3'){
        recommendation = recommendationData;
      }
      else{
        recommendation = recommendationDataLate;
      }
      loadRecommendationFromPreferences(userRegion, _disease!);

    }

    loadRecommendationFromPreferences(userRegion, _disease!);

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