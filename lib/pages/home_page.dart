import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:diagno/pages/profile_page.dart';
import 'package:diagno/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../controller/data_controller.dart';
import '../search/search_page.dart';
import 'ai_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});


  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DataController dataController;
  String? imageUrl;
  bool isExpert =false;
  bool isLoading = true;
  ImageProvider<Object>? imageProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _currentUser;
  LocationPermission _permission = LocationPermission.denied;
  String myUid = FirebaseAuth.instance.currentUser!.uid;


  int currentIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  List<Widget> widgetOption = [
    LeafSpotDetectionScreen(),
    SearchPage(),
    SettingsPage()
  ];

  @override
  void initState() {
    super.initState();
    dataController = Get.put(DataController());
    _requestLocationPermission();
    fetchUserType();
    getImage();
    _currentUser = _auth.currentUser;
    _setOnlineStatus();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        _setOnlineStatus();
      } else {
        _setOfflineStatus();
      }
    });



  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    setState(() {
      _permission = permission;
    });
    locationImpact();
  }

  void getImage() async {
    String? imageUrl = await dataController.myDocument?.get('image');
    if (imageUrl != null && imageUrl.isNotEmpty) {
      setState(() {
        imageProvider = NetworkImage(imageUrl);
      });
    }
  }
  void locationImpact(){
    if(_permission == LocationPermission.denied) {
      Get.snackbar('Information', 'You may not have localized recommendation unless the app has access to your location.',colorText: Colors.white,backgroundColor: Colors.blue);
    }
  }

  @override
  void dispose() {
    _setOfflineStatus();

    super.dispose();
  }
  Future<void> fetchUserType() async {
    try {
      myUid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch from farmers collection
      DocumentSnapshot farmerSnapshot = await FirebaseFirestore.instance.collection('farmers').doc(myUid).get();

      // Check if the document exists in the farmers collection
      if (farmerSnapshot.exists) {
        setState(() {
          isExpert = farmerSnapshot['isExpert'];
          isLoading = false;
        });
      } else {
        // Fetch from experts collection if not found in farmers
        DocumentSnapshot expertSnapshot = await FirebaseFirestore.instance.collection('experts').doc(myUid).get();
        if (expertSnapshot.exists) {
          setState(() {
            isExpert = expertSnapshot['isExpert'];
            isLoading = false;
          });
        } else {
          // Handle the case where the user is not found in either collection
          setState(() {
            isExpert = false; // Default to false if user is not found
            isLoading = false;
          });
        }
      }
    } catch (e) {
      // Handle any errors
      setState(() {
        isExpert = false; // Default to false in case of an error
        isLoading = false;
      });
    }
  }

  Future<void> _setOnlineStatus() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      if(isExpert) {
        await _firestore.collection('experts').doc(_currentUser?.uid).update({'isOnline': true});
      } else {
        await _firestore.collection('farmers').doc(_currentUser?.uid).update({'isOnline': true});
      }
    }
  }

  Future<void> _setOfflineStatus() async {
    if(isExpert) {
      await _firestore.collection('experts').doc(_currentUser?.uid).update({'isOnline': false});
    } else {
      await _firestore.collection('farmers').doc(_currentUser?.uid).update({'isOnline': false});
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: currentIndex != 1? AppBar(
        leadingWidth: 50,
        leading: imageProvider !=null? Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: (){
              Get.to(()=> ProfilePage(uid: FirebaseAuth.instance.currentUser!.uid,));
            },
            child: CircleAvatar(
              backgroundImage: imageProvider,
            ),
          ),
        ): const Icon(Icons.person),
        title: currentIndex ==2? const Text('Settings'):Text(widget.title),
      ): null,
      body: widgetOption[currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        buttonBackgroundColor: Theme.of(context).dividerColor,
        backgroundColor: DataController().isDarkMode.value? Colors.transparent: Colors.white,
        color: DataController().isDarkMode.value? const Color(0xFF495A4C):const Color(0xFFB5DEB7),
        items: [
          CurvedNavigationBarItem(
            labelStyle: TextStyle(
              color: DataController().isDarkMode.value? Colors.white: Colors.black
            ),
            child: const Icon(Icons.home_outlined),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            labelStyle: TextStyle(
                color: DataController().isDarkMode.value? Colors.white: Colors.black
            ),
            child: const Icon(Icons.search),
            label: 'Search',
          ),
          CurvedNavigationBarItem(
            labelStyle: TextStyle(
                color: DataController().isDarkMode.value? Colors.white: Colors.black
            ),
            child: const Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}