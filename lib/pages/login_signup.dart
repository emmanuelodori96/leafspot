import 'dart:io';
import 'dart:ui';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:google_fonts/google_fonts.dart';

import '../../controller/auth_controller.dart';
import '../util/app_color.dart';
import '../util/my_widgets.dart';
import 'package:geocoding/geocoding.dart';


class LoginView extends StatefulWidget {
  LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {


  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController farmSizeController = TextEditingController();
  final TextEditingController cropTypeController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  int selectedRadio = 0;
  TextEditingController forgetEmailController = TextEditingController();

  void setSelectedRadio(int val) {
    setState(() {
      selectedRadio = val;
    });
  }

  imagePickDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                  await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    profileImage = File(image.path);
                    setState(() {});
                    Navigator.pop(context);
                  }

                },
                child: Icon(
                  Icons.camera_alt,
                  size: 30,
                ),
              ),
              SizedBox(
                width: 20,
              ),
              InkWell(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    profileImage = File(image.path);
                    setState(() {});
                    Navigator.pop(context);
                  }

                },
                child:  Icon(
                  Icons.photo,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  File? profileImage;


  bool isSignUp = false;

  late AuthController authController;

  @override
  void initState() {
    super.initState();
    authController = Get.put(AuthController());

  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
            child: Column(
              children: [
                SizedBox(
                  height: Get.height * 0.08,
                ),
                isSignUp
                    ? myText(
                  text: 'Sign Up',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : myText(
                  text: 'Login',
                  // style: GoogleFonts.poppins(
                  //   fontSize: 23,
                  //   fontWeight: FontWeight.w600,
                  // ),
                ),
                SizedBox(
                  height: Get.height * 0.03,
                ),
                isSignUp
                    ? Container(
                  child: myText(
                    text:
                    'Welcome, Please Sign up to see events and classes from your friends.',
                    // style: GoogleFonts.roboto(
                    //   letterSpacing: 0,
                    //   fontSize: 18,
                    //   fontWeight: FontWeight.w400,
                    // ),
                    textAlign: TextAlign.center,
                  ),
                )
                    : Container(
                  child: myText(
                    text:
                    'Welcome back, Please Sign in and continue your journey with us.',
                    // style: GoogleFonts.roboto(
                    //   letterSpacing: 0,
                    //   fontSize: 18,
                    //   fontWeight: FontWeight.w400,
                    // ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.03,
                ),
                Container(
                  width: Get.width * 0.55,
                  child: TabBar(
                    labelPadding: EdgeInsets.all(Get.height * 0.01),
                    unselectedLabelColor: Colors.grey,
                    labelColor: Colors.black,
                    indicatorColor: Colors.black,
                    onTap: (v) {
                      setState(() {
                        isSignUp = !isSignUp;
                      });
                    },
                    tabs: [
                      myText(
                        text: 'Login',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black),
                      ),
                      myText(
                        text: 'Sign Up',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.04,
                ),
                Container(
                  width: Get.width,
                  height: Get.height * 0.6,
                  child: Form(
                    key: formKey,
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        LoginWidget(),
                        SignUpWidget(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget LoginWidget(){
    return SingleChildScrollView(
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              myTextField(
                  bool: false,
                  icon: Icons.mail,
                  text: 'emma12@gmail.com',
                  validator: (String input){
                    if(input.isEmpty){
                      Get.snackbar('Warning', 'Email is required.',colorText: Colors.white,backgroundColor: Colors.blue);
                      return '';
                    }

                    if(!input.contains('@')){
                      Get.snackbar('Warning', 'Email is invalid.',colorText: Colors.white,backgroundColor: Colors.blue);
                      return '';
                    }
                  },
                  controller: emailController
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              myTextField(
                  bool: true,
                  icon: Icons.lock,
                  text: 'password',
                  validator: (String input){
                    if(input.isEmpty){
                      Get.snackbar('Warning', 'Password is required.',colorText: Colors.white,backgroundColor: Colors.blue);
                      return '';
                    }

                    if(input.length <6){
                      Get.snackbar('Warning', 'Password should be 6+ characters.',colorText: Colors.white,backgroundColor: Colors.blue);
                      return '';
                    }
                  },
                  controller: passwordController
              ),
              InkWell(
                onTap: () {
                  Get.defaultDialog(
                    title: 'Forget Password?',
                    content: Container(
                      width: Get.width,
                      child: Column(
                        children: [
                          myTextField(
                              bool: false,
                              icon: Icons.lock,
                              text: 'enter your email...',
                              controller: forgetEmailController
                          ),

                          SizedBox(
                            height: 10,
                          ),

                          MaterialButton(
                            color: Colors.blue,
                            onPressed: (){
                              authController.forgetPassword(forgetEmailController.text.trim());
                            },child: Text("Sent"),minWidth: double.infinity,)

                        ],
                      ),
                    )
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(
                    top: Get.height * 0.02,
                  ),
                  child: myText(
                      text: 'Forgot password?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      )),
                ),
              ),
            ],
          ),
          Obx(()=> authController.isLoading.value? Center(child: CircularProgressIndicator(),) :Container(
            height: 50,
            margin: EdgeInsets.symmetric(
                vertical: Get.height * 0.04),
            width: Get.width,
            child: elevatedButton(
              text: 'Login',
              onpress: () {

                if(!formKey.currentState!.validate()){
                  return;
                }

                authController.login(email: emailController.text.trim(),password: passwordController.text.trim());


              },
            ),
          )),


        ],
      ),
    );
  }
  Widget SignUpWidget(){
    return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: Get.width * 0.1,
            ),
            InkWell(
              onTap: () {
                imagePickDialog();
              },
              child: Container(
                width: 120,
                height: 120,
                margin: EdgeInsets.only(top: 35),
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(70),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff7DDCFB),
                      Color(0xffBC67F2),
                      Color(0xffACF6AF),
                      Color(0xffF95549),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(70),
                      ),
                      child: profileImage == null
                          ? CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                          size: 50,
                        ),
                      )
                          : CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        backgroundImage: FileImage(
                          profileImage!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: Get.width * 0.1,
            ),


            myTextField(
                bool: false,
                icon: Icons.email,
                text: 'Email',
                validator: (String input){
                  if(input.isEmpty){
                    Get.snackbar('Warning', 'Email is required.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }

                  if(!input.contains('@')){
                    Get.snackbar('Warning', 'Email is invalid.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                },
                controller: emailController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: true,
                icon: Icons.lock,
                text: 'password',
                validator: (String input){
                  if(input.isEmpty){
                    Get.snackbar('Warning', 'Password is required.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }

                  if(input.length <6){
                    Get.snackbar('Warning', 'Password should be 6+ characters.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                },
                controller: passwordController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: false,
                icon: Icons.lock,
                text: 'Re-enter password',
                validator: (input){
                  if(input != passwordController.text.trim()){
                    Get.snackbar('Warning', 'Confirm Password is not same as password.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                },
                controller: confirmPasswordController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: false,
                icon: Icons.person,
                text: 'Enter full name',
                validator: (String input){
                  if(input.isEmpty){
                    Get.snackbar('Warning','Your name is required please',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                },
                controller: nameController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: false,
                icon: Icons.phone,
                text: 'Phone Number',
                validator: (String input){
                  if(input.isEmpty){
                    Get.snackbar('Warning', 'Phone number is required please.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                  if(input.trim().length < 10){
                    Get.snackbar('Warning', 'Phone number is not valid.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                  if(input.contains('+', 0) && input.trim().length != 13){
                    Get.snackbar('Warning', 'Phone number is not valid.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                },
                controller: contactController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            Text("Select Gender"),

            RadioListTile(
                title: Text(
                  'Male',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    color: AppColors.genderTextColor,
                  ),
                ),
                value: 0,
                groupValue: selectedRadio,
                onChanged: (int? val) {
                  setSelectedRadio(val!);
                },
              ),

            RadioListTile(
                title: Text(
                  'Female',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    color: AppColors.genderTextColor,
                  ),
                ),
                value: 1,
                groupValue: selectedRadio,
                onChanged: (int? val) {
                  setSelectedRadio(val!);
                },
              ),

            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: false,
                icon: Icons.location_on,
                text: 'Your farm location',
                validator: (String input){
                  if(input.isEmpty){
                    Get.snackbar('Warning', 'Location is required for localize recommendations.',colorText: Colors.white,backgroundColor: Colors.blue);
                    return '';
                  }
                },
                controller: locationController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: false,
                icon: Icons.scale,
                text: 'Farm scale',
                validator: (String input){

                },
                controller: farmSizeController
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            myTextField(
                bool: false,
                icon: Icons.type_specimen,
                text: 'Crop type',
                validator: (String input){
                  if(input.toLowerCase().trim() != 'ground nut'){
                    Get.snackbar('Information', 'We are not having other services for that crop at the moment.',colorText: Colors.white,backgroundColor: Colors.blue);
                  }

                },
                controller: cropTypeController
            ),
            Obx(()=> authController.isLoading.value|| authController.isProfileInformationLoading.value? Center(child: CircularProgressIndicator(),) : Container(
              height: 50,
              margin: EdgeInsets.symmetric(
                vertical: Get.height * 0.04,
              ),
              width: Get.width,
              child: elevatedButton(
                text: 'Sign Up',
                onpress: () async {

                  if(!formKey.currentState!.validate()){
                    return;
                  }

                  authController.signUp(email: emailController.text.trim(),password: passwordController.text.trim());

                  if(profileImage == null){
                    Get.snackbar(
                        'Warning', "Image is required.",
                        colorText: Colors.white,
                        backgroundColor: Colors.blue);
                    return null;
                  }


                  authController.isProfileInformationLoading(true);

                  String imageUrl = await authController.uploadImageToFirebaseStorage(profileImage!);
                  if(FirebaseAuth.instance.currentUser != null && !authController.isLoading.value && imageUrl.isNotEmpty) {
                    authController.uploadProfileData(imageUrl: imageUrl,
                        name: nameController.text,
                        email: emailController.text,
                        location: locationController.text,
                        mobileNumber: contactController.text,
                        scale: farmSizeController.text,
                        gender: selectedRadio == 0 ? "Male" : "Female",
                        cropType: cropTypeController.text);

                    authController.login(email: emailController.text, password: passwordController.text);
                  }


                },
              ),
            )),

            SizedBox(
              height: Get.height * 0.02,
            ),
            Container(
                width: Get.width * 0.8,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(
                        text:
                        'By signing up, you agree our ',
                        style: TextStyle(
                            color: Color(0xff262628),
                            fontSize: 12)),
                    TextSpan(
                        text:
                        'terms, Data policy and cookies policy',
                        style: TextStyle(
                            color: Color(0xff262628),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ]),
                )),
          ],
        )

    );
  }
/*
  Widget SignUpWidget(){
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 35),
          InkWell(
            onTap: () {
              imagePickDialog();
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(70),
                gradient: LinearGradient(
                  colors: [
                    Color(0xff7DDCFB),
                    Color(0xffBC67F2),
                    Color(0xffACF6AF),
                    Color(0xffF95549),
                  ],
                ),
              ),
              child: Icon(Icons.camera_alt, color: Colors.blue, size: 50),
            ),
          ),
          myTextField(
              bool: false,
              icon: Icons.mail,
              text: 'Email',
              validator: (String input){
                if(input.isEmpty){
                  Get.snackbar('Warning', 'Email is required.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }

                if(!input.contains('@')){
                  Get.snackbar('Warning', 'Email is invalid.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
              },
              controller: emailController
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: true,
              icon: Icons.lock,
              text: 'password',
              validator: (String input){
                if(input.isEmpty){
                  Get.snackbar('Warning', 'Password is required.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }

                if(input.length <6){
                  Get.snackbar('Warning', 'Password should be 6+ characters.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
              },
              controller: passwordController
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: false,
              icon: Icons.lock,
              text: 'Re-enter password',
              validator: (input){
                if(input != passwordController.text.trim()){
                  Get.snackbar('Warning', 'Confirm Password is not same as password.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
              },
              controller: confirmPasswordController
          ),
          const Divider(thickness: 5, color: Colors.green,),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: false,
              icon: Icons.person,
              text: 'Enter full name',
              validator: (String input){
                if(input.isEmpty){
                  Get.snackbar('Warning','Your name is required please',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
              },
              controller: nameController
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: false,
              icon: Icons.phone,
              text: 'Phone Number',
              validator: (String input){
                if(input.isEmpty){
                  Get.snackbar('Warning', 'Phone number is required please.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
                if(input.length != 10 || input.length != 13 || !input.isPhoneNumber){
                  Get.snackbar('Warning', 'Phone number is not valid.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
              },
              controller: contactController
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          Row(
            children: [
              Container(
                // alignment: Alignment.topLeft,
                // width: 150,
                child: RadioListTile(
                  title: Text(
                    'Male',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: AppColors.genderTextColor,
                    ),
                  ),
                  value: 0,
                  groupValue: selectedRadio,
                  onChanged: (int? val) {
                    setSelectedRadio(val!);
                  },
                ),
              ),
              Container(
                child: RadioListTile(
                  title: Text(
                    'Female',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: AppColors.genderTextColor,
                    ),
                  ),
                  value: 1,
                  groupValue: selectedRadio,
                  onChanged: (int? val) {
                    setSelectedRadio(val!);
                  },
                ),
              ),

            ],
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: false,
              icon: Icons.lock,
              text: 'Your farm location',
              validator: (String input){
                if(input.isEmpty){
                  Get.snackbar('Warning', 'Location is required for localize recommendations.',colorText: Colors.white,backgroundColor: Colors.blue);
                  return '';
                }
              },
              controller: locationController
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: false,
              icon: Icons.scale,
              text: 'Farm scale',
              validator: (String input){

              },
              controller: farmSizeController
          ),
          SizedBox(
            height: Get.height * 0.02,
          ),
          myTextField(
              bool: false,
              icon: Icons.type_specimen,
              text: 'Crop type',
              validator: (String input){
                if(input.toLowerCase() != 'ground nut' || input.toLowerCase() != 'gnut'){
                  Get.snackbar('Information', 'We are not having other services for that crop at the moment.',colorText: Colors.white,backgroundColor: Colors.blue);
                }

              },
              controller: cropTypeController
          ),

          ElevatedButton(
            onPressed: () {
              // Handle sign-up button press
            },
            child: Text('Sign Up'),
          ),
        ],
      ),
    );
  }
*/
  Future<LocationResult?> captureLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle denied permission
        return null;
      }
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        return LocationResult(
          placeName: placemarks[0].name,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      // Handle errors
      print(e.toString());
    }
    return null;
  }

}



class LocationResult {
  final String? placeName;
  final double latitude;
  final double longitude;

  LocationResult({this.placeName, required this.latitude, required this.longitude});
}