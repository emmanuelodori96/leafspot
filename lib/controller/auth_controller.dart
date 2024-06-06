import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:diagno/pages/login_signup.dart';


import 'package:path/path.dart' as Path;

import '../pages/home_page.dart';

class AuthController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;

  var isLoading = false.obs;

  void login({String? email, String? password}) {
    isLoading(true);

    auth
        .signInWithEmailAndPassword(email: email!, password: password!)
        .then((value) {
      /// Login Success

      isLoading(false);
      Get.to(() => HomePage(title: 'Diagno vision'));
    }).catchError((e) {
      isLoading(false);
      Get.snackbar('Error', "$e");

      ///Error occured
    });
  }

  void signUp({String? email, String? password}) {
    ///here we have to provide two things
    ///1- email
    ///2- password

    isLoading(true);

    auth
        .createUserWithEmailAndPassword(email: email!, password: password!)
        .then((value) {
      isLoading(false);


    }).catchError((e) {
      /// print error information
      print("Error in authentication $e");
      isLoading(false);
    });
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
      // Navigate to the login screen after signing out
      Get.offAllNamed('/login');
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  void forgetPassword(String email) {
    auth.sendPasswordResetEmail(email: email).then((value) {
      Get.back();
      Get.snackbar('Email Sent', 'We have sent password reset email');
    }).catchError((e) {
      print("Error in sending password reset email is $e");
    });
  }

  // signInWithGoogle() async {
  //   isLoading(true);
  //   // Trigger the authentication flow
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //
  //   // Obtain the auth details from the request
  //   final GoogleSignInAuthentication? googleAuth =
  //       await googleUser?.authentication;
  //
  //   // Create a new credential
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth?.accessToken,
  //     idToken: googleAuth?.idToken,
  //   );
  //
  //   // Once signed in, return the UserCredential
  //   FirebaseAuth.instance.signInWithCredential(credential).then((value) {
  //     isLoading(false);
  //
  //     ///SuccessFull loged in
  //     Get.to(() => HomePage(selectedLanguage: 'en'));
  //   }).catchError((e) {
  //     /// Error in getting Login
  //     isLoading(false);
  //     print("Error is $e");
  //   });
  // }


  var isProfileInformationLoading = false.obs;

  Future<String> uploadImageToFirebaseStorage(File image) async {
    String imageUrl = '';
    String fileName = Path.basename(image.path);

    var reference =
        FirebaseStorage.instance.ref().child('profileImages/$fileName');
    UploadTask uploadTask = reference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    await taskSnapshot.ref.getDownloadURL().then((value) {
      imageUrl = value;
    }).catchError((e) {
      print("Error happen $e");
    });

    return imageUrl;
  }




  void uploadProfileData({String? imageUrl, String? name, String? email, String? location,
      String? mobileNumber, String? scale, String? gender, String? cropType}) {

    String uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance.collection('farmers').doc(uid).set({
      'image': imageUrl,
      'name': name,
      'email': email,
      'phone': mobileNumber,
      'location': location,
      'scale': scale,
      'gender': gender,
      'crop_type': cropType
    }).then((value) {
      isProfileInformationLoading(false);
      Get.offAll(()=> HomePage(title: 'Diagno vision'));
    });

  }
}
