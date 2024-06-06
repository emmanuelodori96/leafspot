import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:diagno/search/search_controller.dart' as search;

class FirstTab extends StatefulWidget {
  const FirstTab({super.key});

  @override
  State<FirstTab> createState() => _FirstTabState();
}

class _FirstTabState extends State<FirstTab> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // late User? _currentUser;
  //
  //
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _currentUser = _auth.currentUser;
  //   _setOnlineStatus();
  //   _auth.authStateChanges().listen((User? user) {
  //     setState(() {
  //       _currentUser = user;
  //     });
  //     if (user != null) {
  //       _setOnlineStatus();
  //     } else {
  //       _setOfflineStatus();
  //     }
  //   });
  // }
  //
  // @override
  // void dispose() {
  //   _setOfflineStatus();
  //   super.dispose();
  // }
  //
  // Future<void> _setOnlineStatus() async {
  //   final connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult != ConnectivityResult.none) {
  //     await _firestore.collection('experts').doc(_currentUser?.uid).update({'isOnline': true});
  //   }
  // }
  //
  // Future<void> _setOfflineStatus() async {
  //   await _firestore.collection('experts').doc(_currentUser?.uid).update({'isOnline': false});
  // }
  @override
  Widget build(BuildContext context) {
    final search.SearchController searchController = Get.find();

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
              );
            },
          );
        },
      );
    });
  }
}
