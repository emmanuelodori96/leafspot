import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:diagno/pages/profile_page.dart';
import 'package:diagno/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/data_controller.dart';
import '../search/search_page.dart';
import 'ai_screen.dart';
import 'discussion_room.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});


  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DataController dataController;
  String? imageUrl;
  ImageProvider<Object>? imageProvider;

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
    getImage();

  }

  void getImage() async {
    String? imageUrl = await dataController.myDocument?.get('image');
    if (imageUrl != null && imageUrl.isNotEmpty) {
      setState(() {
        imageProvider = NetworkImage(imageUrl);
      });
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
        color: DataController().isDarkMode.value? Color(0xFF495A4C):Color(0xFFB5DEB7),
        items: [
          CurvedNavigationBarItem(
            labelStyle: TextStyle(
              color: DataController().isDarkMode.value? Colors.black: Colors.white
            ),
            child: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            labelStyle: TextStyle(
                color: DataController().isDarkMode.value? Colors.black: Colors.white
            ),
            child: Icon(Icons.search),
            label: 'Search',
          ),
          CurvedNavigationBarItem(
            labelStyle: TextStyle(
                color: DataController().isDarkMode.value? Colors.black: Colors.white
            ),
            child: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Get.to(()=> DiscussionRoom());
        },
        tooltip: 'Message',
        child: const Icon(Icons.message_rounded),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}