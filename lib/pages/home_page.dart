import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:diagno/pages/profile_page.dart';
import 'package:diagno/pages/search_page.dart';
import 'package:diagno/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/data_controller.dart';
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
    SettingPage()
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dataController = Get.put(DataController());
    getImage();

  }

  void getImage()async{
    imageUrl = dataController.myDocument?.get('image');
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    }
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: imageProvider !=null? InkWell(
          radius: 10,
          onTap: (){
            Get.to(()=> ProfileScreen());

          },
          child: CircleAvatar(
            backgroundImage: imageProvider,//

          ),
        ): const Icon(Icons.person),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: widgetOption[currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.greenAccent,
        items: const [
          CurvedNavigationBarItem(
            child: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.search),
            label: 'Search',
          ),
          CurvedNavigationBarItem(
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