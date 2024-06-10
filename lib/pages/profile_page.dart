import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controller/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  ProfilePage({required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditable = false;

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController(widget.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        actions: [
          controller.isCurrentUser
              ? IconButton(
                  icon: Icon(
                      isEditable? Icons.save : Icons.edit),
                  onPressed: () {
                    if (isEditable) {
                      // Call updateProfile with new data
                      controller.updateProfile({
                        'name': controller.farmerDoc.value!.data()!['name'],
                        'phone': controller.farmerDoc.value!.data()!['phone'],
                        'location': controller.farmerDoc.value!.data()!['location'],
                        'scale': controller.farmerDoc.value!.data()!['scale'],
                        'crop_type': controller.farmerDoc.value!.data()!['crop_type'],

                      });
                    } else {
                      setState((){
                        isEditable = true;
                        controller.isEditing.value = true;
                      });

                    }
                  })
              : const SizedBox(),
        ],
      ),
      body: Obx(() {
        if (controller.farmerDoc.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.farmerDoc.value!.exists) {
          return const Center(child: Text('Farmer not found'));
        }

        var data = controller.farmerDoc.value!.data()!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: CachedNetworkImageProvider(data['image']),
                ),
                const SizedBox(height: 16),
                _buildProfileField('Name', data['name'], controller.isEditing,
                    (value) {
                  data['name'] = value;
                }),
                _buildProfileField(
                    'Email', data['email'], controller.isEditing, null,
                    readOnly: true),
                _buildProfileField('Phone', data['phone'], controller.isEditing,
                    (value) {
                  data['phone'] = value;
                }),
                _buildProfileField(
                    'Location', data['location'], controller.isEditing,
                    (value) {
                  data['location'] = value;
                }),
                _buildProfileField('Scale', data['scale'], controller.isEditing,
                    (value) {
                  data['scale'] = value;
                }),
                _buildProfileField(
                    'Gender', data['gender'], controller.isEditing, null,
                    readOnly: true),
                _buildProfileField(
                    'Crop Type', data['crop_type'], controller.isEditing,
                    (value) {
                  data['crop_type'] = value;
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileField(
      String label, String value, RxBool isEditing, Function(String)? onChanged,
      {bool readOnly = false}) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            isEditing.value && !readOnly
                ? Expanded(
                    child: TextFormField(
                      initialValue: value,
                      onChanged: onChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                : Text(value),
          ],
        ),
      );
    });
  }
}
