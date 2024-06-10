import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:diagno/search/search_controller.dart' as search;

import '../controller/data_controller.dart';
import '../pages/chat_page.dart';

class FirstTab extends StatefulWidget {
  const FirstTab({super.key});

  @override
  State<FirstTab> createState() => _FirstTabState();
}

class _FirstTabState extends State<FirstTab> {
  DataController dataController = Get.find<DataController>();
  bool isExpert =false;
  bool isLoading = true;

  String myUid = FirebaseAuth.instance.currentUser!.uid;
  @override
  void initState() {
    super.initState();
    fetchUserType();
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
  @override
  Widget build(BuildContext context) {
    final search.SearchController searchController = Get.find();

    if (isExpert) {
      return Obx(() {
        final searchQuery = searchController.searchQuery.value;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('farmers').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final experts = snapshot.data!.docs.where((doc) {
              final name = doc['name'].toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return ListView.builder(
              itemCount: experts.length,
              itemBuilder: (context, index) {
                String name = '', image = '', spec = '';
                try{
                  name = experts[index]['name'];
                  spec = experts[index]['scale'];
                }catch(e){
                  name = '';
                }

                try{
                  image = experts[index]['image'];
                }catch(e){
                  image = '';
                }


                String fcmToken = '';
                try{
                  fcmToken = experts[index]['fcmToken'];
                }catch(e){
                  fcmToken = '';
                }
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(experts[index]['image']),
                        radius: 30,
                      ),
                      if (experts[index]['isOnline'] == true)
                        Positioned(
                          right: 4,
                          bottom: 2,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3, style: BorderStyle.solid),
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(experts[index]['name']),
                  subtitle: Text(experts[index]['scale']),
                  onTap: (){
                    String chatRoomId = '';
                    if(myUid.hashCode>experts[index].id.hashCode){
                      chatRoomId = '$myUid-${experts[index].id}';
                    }else{
                      chatRoomId = '${experts[index].id}-$myUid';
                    }

                    Get.to(() => Chat(groupId: chatRoomId,name: name,image: image,fcmToken: fcmToken,uid: experts[index].id, spec: spec));
                  },
                );
              },
            );
          },
        );
      });

    } else {
      return Obx(() {
        final searchQuery = searchController.searchQuery.value;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('experts').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final experts = snapshot.data!.docs.where((doc) {
              final name = doc['name'].toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return ListView.builder(
              itemCount: experts.length,
              itemBuilder: (context, index) {
                String name = '', image = '', spec = '';
                try{
                  name = experts[index]['name'];
                  spec = experts[index]['specialization'];
                }catch(e){
                  name = '';
                }

                try{
                  image = experts[index]['profilePic'];
                }catch(e){
                  image = '';
                }


                String fcmToken = '';
                try{
                  fcmToken = experts[index]['fcmToken'];
                }catch(e){
                  fcmToken = '';
                }
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(experts[index]['profilePic']),
                        radius: 30,
                      ),
                      if (experts[index]['isOnline'] == true)
                        Positioned(
                          right: 4,
                          bottom: 2,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3, style: BorderStyle.solid),
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(experts[index]['name']),
                  subtitle: Text(experts[index]['specialization']),
                  onTap: (){
                    String chatRoomId = '';
                    if(myUid.hashCode>experts[index].id.hashCode){
                      chatRoomId = '$myUid-${experts[index].id}';
                    }else{
                      chatRoomId = '${experts[index].id}-$myUid';
                    }

                    Get.to(() => Chat(groupId: chatRoomId,name: name,image: image,fcmToken: fcmToken,uid: experts[index].id, spec: spec));
                  },
                );
              },
            );
          },
        );
      });
    }
  }
}
