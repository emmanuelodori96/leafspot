import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var farmerDoc = Rx<DocumentSnapshot<Map<String, dynamic>>?>(null);
  late String uid;

  var isEditing = false.obs;

  ProfileController(String uid) {
    this.uid = uid;
    _loadFarmerData();
  }

  bool get isCurrentUser => _auth.currentUser?.uid == uid;

  void toggleEditing() {
    isEditing.value = !isEditing.value;
  }

  void updateProfile(Map<String, dynamic> data) {
    _firestore.collection('farmers').doc(uid).update(data);
    toggleEditing();
  }

  void _loadFarmerData() async {
    var snapshot = await _firestore.collection('farmers').doc(uid).get();
    farmerDoc.value = snapshot;
  }
}
