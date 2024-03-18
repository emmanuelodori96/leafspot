import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../util/app_color.dart';
import '../util/circular_progress.dart';
import '../util/my_widgets.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? selectedImage;
  bool _processing = false;
  double _processingPercentage = 0.0;

  getImageDialog(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final pickedImage = await picker.pickImage(
      source: source,
    );

    if (pickedImage != null) {
      setState(() {
        selectedImage = File(pickedImage.path);
      });

    }

    setState(() {});
    Navigator.pop(context);
    _processImage();
  }


  Future<void> _processImage() async {
    setState(() {
      _processing = true;
    });

    // Simulating image processing
    for (int i = 0; i < 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _processingPercentage = (i + 1) / 100;
      });
    }

    setState(() {
      _processing = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          child: Container(
            alignment: Alignment.center,
            height: MediaQuery.of(context).size.width* 0.8,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                image: (selectedImage != null)
                    ? DecorationImage(
                  image: FileImage(selectedImage!),
                  fit: BoxFit.cover,
                )
                    : null,
                color: selectedImage == null? AppColors.border.withOpacity(0.2): Colors.transparent,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Container(
                  width: 76,
                  height: 59,
                  child: Image.asset('assets/uploadIcon.png'),
                ),
                myText(
                  text: 'Click and upload image',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                elevatedButton(
                    onpress: () async {
                      imageDialog(context, true);
                    },
                    text: 'Upload'
                ),


              ],
            ),

          ),

        ),
        Expanded(
          child: SingleChildScrollView(
            child:  _processing?
            Align(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _processingPercentage,
                  ),
                  const Text(
                    'Processing...',
                    style: TextStyle(fontSize: 16.0),
                  )
                ],
              ),
            ): Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width*0.9,
                  height: 100.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text("The percentage of disease is:"),
                      Container(
                        width: 70,
                        height: 70,
                        child: CustomPaint(
                          painter: CircleProgressBar(
                            percentage: _processingPercentage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      selectedImage != null
                          ? Container(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Image.file(
                                    selectedImage!,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                const Text("Cercospora arachidicola"),
                                const Text("Leaf Spot")
                              ],
                            ),
                            const Text("Groundnut leaf spot is a common fungal disease affecting groundnut (peanut) plants, caused by various pathogens such as Cercospora arachidicola and Cercosporidium personatum. It typically manifests as small, dark spots on the leaves, which can merge and cause extensive damage if not managed properly"),
                            ElevatedButton(
                              onPressed: () {
                                // Display bottom sheet with recommendations
                                _showRecommendations(context);
                              },
                              child: const Text('View Recommendations'),
                            ),
                          ],
                        ),
                      )
                          : const Text('No image selected'),
                      const SizedBox(height: 10.0),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Disease Recommendations:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              Text(
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
                      } else {

                      }
                    },
                    icon: const Icon(Icons.image)),
                IconButton(
                    onPressed: () {
                      if (image) {
                        getImageDialog(ImageSource.camera);
                      } else {

                      }
                    },
                    icon: const Icon(Icons.camera_alt)),
              ],
            ),
          );
        },
        context: context);
  }

}
