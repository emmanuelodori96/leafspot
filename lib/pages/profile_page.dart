import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/data_controller.dart';
import '../util/app_color.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {


  TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController farmSizeController = TextEditingController();
  final TextEditingController cropTypeController = TextEditingController();




  bool isNotEditable = true;
  
  
  DataController? dataController;

  int? followers = 0,following=0;
  String image = '';

  @override
  initState(){
    super.initState();
    dataController = Get.put(DataController());



    try{
      nameController.text = dataController!.myDocument!.get('name');
      emailController.text = dataController!.myDocument!.get('email');
      locationController.text = dataController!.myDocument!.get('location');
      contactController.text = dataController!.myDocument!.get('phone');
      cropTypeController.text = dataController!.myDocument!.get('crop_type');
      farmSizeController.text = dataController!.myDocument!.get('scale');
    }catch(e){

    }

    try{
      image = dataController!.myDocument!.get('image');
    }catch(e){
      image = '';
    }

    try{
      locationController.text = dataController!.myDocument!.get('location');
    }catch(e){
      locationController.text = '';
    }


  }

  @override
  Widget build(BuildContext context) {
    var screenheight = MediaQuery.of(context).size.height;
    var screenwidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(
                      left: Get.width * 0.75, top: 20, right: 20),
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {

                        },
                        // child: Image(
                        //   image: AssetImage('assets/images/sms.png'),
                        //   width: 28,
                        //   height: 25,
                        // ),
                      ),
                      Icon(Icons.menu),
                    ],
                  ),
                ),
              ),
              Align(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 90, horizontal: 20),
                  width: Get.width,
                  height: isNotEditable? 240: 310,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 3,
                        offset: Offset(0, 0), // changes position of shadow
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {

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
                              child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                   image,
                                  )
                              ),
                              // child: Image.asset(
                              //   'assets/profilepic.png',
                              //   fit: BoxFit.contain,
                              // ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    isNotEditable?Text(
                      "${nameController.text}",
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ):
                    Container(
                      width: Get.width*0.6,
                      child: Row(
                        children: [
                          Expanded(child: TextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Name',

                            ),
                          ),),

                          SizedBox(
                            width: 10,
                          ),

                          Expanded(child: TextField(
                            controller: contactController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Phone',

                            ),
                          ),),
                        ],
                      ),
                    ),
                   isNotEditable? Text(
                      "${locationController.text}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff918F8F),
                      ),
                    ):
                   Container(
                     width: Get.width*0.6,
                     child: TextField(
                       controller: locationController,
                       textAlign: TextAlign.center,
                       decoration: InputDecoration(
                           hintText: 'Location',

                       ),
                     ),
                   ),
                    SizedBox(
                      height: 15,
                    ),
                    isNotEditable?Container(
                      width: 270,
                      child: Text(
                        '${emailController.text}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          letterSpacing: -0.3,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ): Container(
                      width: Get.width*0.6,
                      child: TextField(
                        controller: emailController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Description',

                        ),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      child: DefaultTabController(
                        length: 2,
                        initialIndex: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 0.01,
                                  ),
                                ),
                              ),
                              child: TabBar(
                                indicatorColor: Colors.black,
                                labelPadding: EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 10,
                                ),
                                unselectedLabelColor: Colors.black,
                                tabs: [
                                  Tab(
                                    icon: Icon(Icons.post_add),
                                    height: 20,
                                  ),
                                  Tab(
                                    icon: Icon(Icons.group),
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: screenheight * 0.46,
                              //height of TabBarView
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: TabBarView(
                                physics: NeverScrollableScrollPhysics(),
                                children: <Widget>[
                                  Text("No content"),

                                  Container(
                                    child: Center(
                                      child: Text('Tab 2',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: EdgeInsets.only(top: 105, right: 35),

                  child: InkWell
                    (
                    onTap: (){


                      if(isNotEditable ==false){
                        FirebaseFirestore.instance.collection('farmers').doc(FirebaseAuth.instance.currentUser!.uid)
                            .set({
                          'name': nameController.text,
                          'email': emailController.text,
                          'location':locationController.text,
                          'crop_type': cropTypeController.text,
                          'scale': farmSizeController.text,
                          'phone': contactController.text,
                        },SetOptions(merge: true)).then((value) {
                          Get.snackbar('Profile Updated', 'Profile has been updated successfully.',colorText: Colors.white,
                              backgroundColor: Colors.blue);
                        });
                      }


                      setState(() {
                        isNotEditable = !isNotEditable;
                      });





                    },
                    child: isNotEditable? Image(
                      image: AssetImage('assets/images/edit.png'),
                      width: screenwidth * 0.04,
                    ): Icon(Icons.check,color: Colors.black,),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}