import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as Path;

class DataController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  DocumentSnapshot? myDocument;
  var allUsers = <DocumentSnapshot>[].obs;
  var filteredUsers = <DocumentSnapshot>[].obs;
  var filteredEvents = <DocumentSnapshot>[].obs;

  var isMessageSending = false.obs;

  var isDarkMode = false.obs;
  var newActivityNotifications = true.obs;
  var emailNotifications = true.obs;
  var smsNotifications = true.obs;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    Color primaryColorLight = Colors.white;
    Color primaryColorDark = Colors.black;
    Color canvasColorLight = Colors.greenAccent;
    Color canvasColorDark = Colors.blueGrey;
    Get.changeTheme(
        value ? ThemeData.dark().copyWith(
          primaryColor: primaryColorDark,
          canvasColor: canvasColorDark,
        )
            : ThemeData.light().copyWith(
          primaryColor: primaryColorLight,
          canvasColor: canvasColorLight,
        )
    );
  }

  void toggleNewActivityNotifications(bool value) {
    newActivityNotifications.value = value;
  }

  void toggleEmailNotifications(bool value) {
    emailNotifications.value = value;
  }

  void toggleSmsNotifications(bool value) {
    smsNotifications.value = value;
  }

  sendMessageToFirebase({
    Map<String, dynamic>? data,
    String? lastMessage,
  }) async {
    isMessageSending(true);
    await FirebaseFirestore.instance.collection('chats').doc('group_chat').collection('chatroom').add(data!);
    await FirebaseFirestore.instance.collection('chats').doc('group_chat').set({
      'lastMessage': lastMessage,
      'group': 'All Users',
    }, SetOptions(merge: true));
    isMessageSending(false);
  }

  sendOneOnOneMessageToFirebase({
    Map<String,dynamic>? data,
    String? lastMessage,
    String? grouid
  })async{

    isMessageSending(true);

    await FirebaseFirestore.instance.collection('inquiry').doc(grouid).collection('inquiryRoom').add(data!);
    await FirebaseFirestore.instance.collection('inquiry').doc(grouid).set({
      'lastMessage': lastMessage,
      'groupId': grouid,
      'group': grouid!.split('-'),
    },SetOptions(merge: true));

    isMessageSending(false);

  }

  createNotification() {
    FirebaseFirestore.instance.collection('notifications').add({
      'message': "Send you a message.",
      'image': myDocument!.get('image'),
      'name': myDocument!.get('first') + " " + myDocument!.get('last'),
      'time': DateTime.now(),
    });
  }

  getMyDocument() {
    FirebaseFirestore.instance.collection('farmers').doc(auth.currentUser?.uid).snapshots().listen((event) {
      myDocument = event;
    });
  }

  Future<String> uploadImageToFirebase(File file) async {
    String fileUrl = '';
    String fileName = Path.basename(file.path);
    var reference = FirebaseStorage.instance.ref().child('myfiles/$fileName');
    UploadTask uploadTask = reference.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    await taskSnapshot.ref.getDownloadURL().then((value) {
      fileUrl = value;
    });
    print("Url $fileUrl");
    return fileUrl;
  }

  Future<String> uploadThumbnailToFirebase(Uint8List file) async {
    String fileUrl = '';
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    var reference = FirebaseStorage.instance.ref().child('myfiles/$fileName.jpg');
    UploadTask uploadTask = reference.putData(file);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    await taskSnapshot.ref.getDownloadURL().then((value) {
      fileUrl = value;
    });
    print("Thumbnail $fileUrl");
    return fileUrl;
  }

  @override
  void onInit() {
    super.onInit();
    getMyDocument();
    getUsers();
  }

  var isUsersLoading = false.obs;

  getUsers() {
    isUsersLoading(true);
    FirebaseFirestore.instance.collection('users').snapshots().listen((event) {
      allUsers.value = event.docs;
      filteredUsers.value.assignAll(allUsers);
      isUsersLoading(false);
    });
  }
}
