import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:diagno/search/search_controller.dart' as search;

class FirstTab extends StatelessWidget {
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
                title: Text(experts[index]['name']),
              );
            },
          );
        },
      );
    });
  }
}
