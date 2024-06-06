import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../controller/data_controller.dart';
import 'profile_page.dart';


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late DataController dataController;
  final AuthController _authController = Get.put(AuthController());

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
            title: Text('Account Settings'),
            leading: Icon(Icons.person),
            onTap: () {
              Get.to(() => ProfilePage(uid: FirebaseAuth.instance.currentUser!.uid));
            },
          ),
          ListTile(
            title: Text('Change Password'),
            leading: Icon(Icons.lock),
            onTap: () {
              Get.to(() => ChangePasswordPage());
            },
          ),
          Divider(),
          ListTile(
            title: Text('Preferences'),
            leading: Icon(Icons.settings),
            onTap: () {},
          ),
          Obx(() => SwitchListTile(
            title: Text('Dark Mode'),
            value: dataController.isDarkMode.value,
            onChanged: (bool value) {
              dataController.toggleDarkMode(value);
            },
            secondary: Icon(Icons.brightness_6),
          )),
          Divider(),
          ListTile(
            title: Text('Notifications'),
            leading: Icon(Icons.notifications),
            onTap: () {},
          ),
          Obx(() => SwitchListTile(
            title: Text('New Activity Notifications'),
            value: dataController.newActivityNotifications.value,
            onChanged: (bool value) {
              dataController.toggleNewActivityNotifications(value);
            },
            secondary: Icon(Icons.notifications_active),
          )),
          Obx(() => SwitchListTile(
            title: Text('Email Notifications'),
            value: dataController.emailNotifications.value,
            onChanged: (bool value) {
              dataController.toggleEmailNotifications(value);
            },
            secondary: Icon(Icons.email),
          )),

          Divider(),
          ListTile(
            title: Text('Help & Support'),
            leading: Icon(Icons.help),
            onTap: () {
              // Navigate to help and support page
            },
          ),
          ListTile(
            title: Text('About'),
            leading: Icon(Icons.info),
            onTap: () {
              // Navigate to about page
            },
          ),
          ListTile(
            title: Text('Logout'),
            leading: Icon(Icons.logout),
            onTap: () {
              _authController.signOut();
            },
          ),
        ],
      ),
    );
  }
}


class ChangePasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle change password
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
