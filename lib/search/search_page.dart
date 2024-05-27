import 'package:diagno/controller/data_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:diagno/search/search_controller.dart' as search;

import 'expert_tab.dart';
import 'video_tab.dart';

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final search.SearchController searchController = Get.put(search.SearchController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
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
              Tab(text: 'Experts'),
              Tab(text: 'Videos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FirstTab(),
            SecondTab(),
          ],
        ),
      ),
    );
  }
}
