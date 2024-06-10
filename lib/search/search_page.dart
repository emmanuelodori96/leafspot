import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diagno/controller/data_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:diagno/search/search_controller.dart' as search;

import 'expert_tab.dart';
import 'video_tab.dart';

class SearchPage extends StatefulWidget {

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
    final search.SearchController searchController = Get.put(search.SearchController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: TextField(
            onChanged: (query) {
              searchController.updateSearchQuery(query);
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.greenAccent,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              suffixIcon: const Icon(Icons.search, color: Colors.grey),

            ),

          ),
          bottom: TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: DataController().isDarkMode.value? Colors.white:Colors.black,
            tabs: [
              Tab(text: isExpert?'Farmers':'Experts'),
              const Tab(text: 'Videos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const FirstTab(),
            SecondTab(),
          ],
        ),
      ),
    );
  }
}
