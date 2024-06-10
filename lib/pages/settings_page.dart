import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../controller/data_controller.dart';
import '../util/my_widgets.dart';
import 'profile_page.dart';


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late DataController dataController;
  final AuthController _authController = Get.put(AuthController());
  TextEditingController forgetEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dataController = Get.put(DataController());
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account Settings'),
            leading: const Icon(Icons.person),
            onTap: () {
              Get.to(() => ProfilePage(uid: FirebaseAuth.instance.currentUser!.uid));
            },
          ),
          ListTile(
            title: const Text('Change Password'),
            leading: const Icon(Icons.lock),
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

                          const SizedBox(
                            height: 10,
                          ),

                          MaterialButton(
                            color: Colors.blue,
                            onPressed: (){
                              _authController.forgetPassword(forgetEmailController.text.trim());
                            },
                            child: const Text("Sent"),minWidth: double.infinity,)

                        ],
                      ),
                    )
                );
              }
          ),
          const Divider(),
          ListTile(
            title: const Text('Preferences'),
            leading: const Icon(Icons.settings),
            onTap: () {},
          ),
          Obx(() => SwitchListTile(
            title: const Text('Dark Mode'),
            value: dataController.isDarkMode.value,
            onChanged: (bool value) {
              dataController.toggleDarkMode(value);
            },
            secondary: const Icon(Icons.brightness_6),
          )),
          const Divider(),
          ListTile(
            title: const Text('Notifications'),
            leading: const Icon(Icons.notifications),
            onTap: () {
              Get.snackbar('Information', 'Feature coming soon.',colorText: Colors.white,backgroundColor: Colors.blue);
            },
          ),
          Obx(() => SwitchListTile(
            title: const Text('New Activity Notifications'),
            value: dataController.newActivityNotifications.value,
            onChanged: (bool value) {
              dataController.toggleNewActivityNotifications(value);
            },
            secondary: const Icon(Icons.notifications_active),
          )),
          Obx(() => SwitchListTile(
            title: const Text('Email Notifications'),
            value: dataController.emailNotifications.value,
            onChanged: (bool value) {
              dataController.toggleEmailNotifications(value);
            },
            secondary: const Icon(Icons.email),
          )),

          const Divider(),
          ListTile(
            title: const Text('Help & Support'),
            leading: const Icon(Icons.help),
            onTap: () {
              Get.snackbar('Information', 'Feature coming soon.',colorText: Colors.white,backgroundColor: Colors.blue);
            },
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            onTap: () {
              Get.snackbar('Information', 'Page not available now.',colorText: Colors.white,backgroundColor: Colors.blue);
            },
          ),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () {
              _authController.signOut();
            },
          ),
        ],
      ),
    );
  }
}


