import 'package:get/get.dart';

class SearchController extends GetxController {
  var searchQuery = ''.obs;

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
