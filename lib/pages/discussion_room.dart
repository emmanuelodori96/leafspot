import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grouped_list/grouped_list.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/data_controller.dart';
import '../util/app_color.dart';
import '../util/my_widgets.dart';

class DiscussionRoom extends StatefulWidget {
  const DiscussionRoom({super.key});


  @override
  _DiscussionRoomState createState() => _DiscussionRoomState();
}

class _DiscussionRoomState extends State<DiscussionRoom> {
  bool isSendingMessage = false;
  bool isEmojiPickerOpen = false;
  String myUid = '';
  String myName = '';
  String myImage = '';
  var screenheight;

  var screenwidth;

  DataController? dataController;
  TextEditingController messageController = TextEditingController();
  FocusNode inputNode = FocusNode();
  String replyText = '';
  void openKeyboard() {
    FocusScope.of(context).requestFocus(inputNode);
  }

  _onEmojiSelected(Emoji emoji) {
    messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length));
  }

  _onBackspacePressed() {
    messageController
      ..text = messageController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length));
  }

  Future<String> fetchMyName() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('farmers').doc(uid).get();

      if (userSnapshot.exists) {
        String name = userSnapshot.get('name') ?? '';

        myName = name;
        return myName;
      } else {
        return '';
      }
    } catch (e) {
      print('Error fetching myName: $e');
      return '';
    }
  }

  Future<String> fetchMyImage() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('farmers').doc(uid).get();

      if (userSnapshot.exists) {
        String image = userSnapshot.get('image') ?? '';

        myImage = image;
        return myImage;
      } else {
        return '';
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    dataController = Get.put(DataController());
    myUid = FirebaseAuth.instance.currentUser!.uid;
    fetchMyName();
    fetchMyImage();
  }

  @override
  Widget build(BuildContext context) {
    screenheight = MediaQuery.of(context).size.height;
    screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      //backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        // centerTitle: true,
        elevation: 0,
        //backgroundColor: Theme.of(context).primaryColor,
        title: myText(
          text: 'Discussion Room',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        leading: InkWell(
          child: const Icon(Icons.arrow_back),
          onTap: () {
            Get.back();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => dataController!.isMessageSending.value
                ? StreamBuilder<QuerySnapshot>(
                    builder: (ctx, snapshot) {
                      // if (!snapshot.hasData) {
                      //   return const Center(
                      //     child: CircularProgressIndicator(),
                      //   );
                      // }

                      List<DocumentSnapshot> data =
                          snapshot.data!.docs.reversed.toList();
                      // Sort messages by timestamp in ascending order
                      data.sort((a, b) {
                        Timestamp timeA = a.get('timeStamp');
                        Timestamp timeB = b.get('timeStamp');
                        return timeA.compareTo(timeB);
                      });

                      // Group messages by date
                      Map<String, List<DocumentSnapshot>> groupedMessages =
                          groupMessagesByDate(data);

                      return GroupedListView<dynamic, String>(
                        elements: groupedMessages.entries.toList(),
                        groupBy: (element) => element.key,
                        reverse: true,
                        groupSeparatorBuilder: (String groupByValue) => Text(
                          groupByValue,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        itemBuilder: (ctx, element) {
                          if (!snapshot.hasData) {
                            // Show CircularProgressIndicator at the top of the list
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            // Build message widget based on message type
                            return buildMessageWidget(element.value);
                          }
                        },
                        //itemCount: groupedMessages.length,
                        order: GroupedListOrder.ASC,
                      );
                    },
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc('group_chat')
                        .collection('chatroom')
                        .snapshots(),
                  )
                : StreamBuilder<QuerySnapshot>(
                    builder: (ctx, snapshot) {
                      // if (!snapshot.hasData) {
                      //   return const Center(
                      //     child: CircularProgressIndicator(),
                      //   );
                      // }
                      List<DocumentSnapshot> data = [];
                      if (snapshot.hasData) {
                        data = snapshot.data!.docs.reversed.toList();
                      }
                      // Sort messages by timestamp in ascending order
                      data.sort((a, b) {
                        Timestamp timeA = a.get('timeStamp');
                        Timestamp timeB = b.get('timeStamp');
                        return timeA.compareTo(timeB);
                      });

                      // Group messages by date
                      Map<String, List<DocumentSnapshot>> groupedMessages =
                          groupMessagesByDate(data);

                      return GroupedListView<dynamic, String>(
                        elements: groupedMessages.entries.toList(),
                        groupBy: (element) => element.key,
                        reverse: true,
                        groupSeparatorBuilder: (String groupByValue) => Text(
                          groupByValue,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        itemBuilder: (ctx, element) =>
                            buildMessageWidget(element.value),
                        //itemCount: groupedMessages.length,
                        order: GroupedListOrder.ASC,
                      );
                    },
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc('group_chat')
                        .collection('chatroom')
                        .snapshots(),
                  )),
          ),
          Container(
            height: isEmojiPickerOpen ? 300 : 75,
            // padding: MediaQuery.of(context).viewInsets,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 9,
                  blurRadius: 9,
                  offset: const Offset(3, 0), // changes position of shadow
                ),
              ],
              color: AppColors.white,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 15,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white2.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isEmojiPickerOpen = !isEmojiPickerOpen;
                          });
                        },
                        child: const Icon(Icons.tag_faces_outlined),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        // width: 200,
                        // height: 50,
                        child: TextFormField(
                          focusNode: inputNode,
                          controller: messageController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type Your Message',
                            hintStyle: TextStyle(
                              color: AppColors.whitegrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: Get.width * 0.13,
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              openMediaDialog();
                            },
                            child: const Icon(Icons.attach_file),
                          ),
                          SizedBox(
                            width: screenwidth * 0.03,
                          ),
                          InkWell(
                            onTap: () {
                              if (messageController.text.isEmpty) {
                                return;
                              }
                              String message = messageController.text;
                              messageController.clear();

                              Map<String, dynamic> data = {
                                'type': 'iSentText',
                                'message': message,
                                'timeStamp': Timestamp.now(),
                                'uid': myUid,
                                'userName': myName,
                                'image': myImage
                              };

                              if (replyText.isNotEmpty) {
                                data['reply'] = replyText;
                                data['type'] = 'iSentReply';
                                replyText = '';
                              }

                              dataController!.sendMessageToFirebase(
                                  data: data, lastMessage: message);

                              //dataController!.createNotification();

                              // LocalNotificationService.sendNotification(title: 'New message',message: message,token: widget.fcmToken);
                            },
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Offstage(
                  offstage: !isEmojiPickerOpen,
                  child: SizedBox(
                    height: 230,
                    child: EmojiPicker(
                        onEmojiSelected: (Category? category, Emoji? emoji) {
                          _onEmojiSelected(emoji!);
                        },
                        onBackspacePressed: _onBackspacePressed,
                        config: Config(
                          height: 256,
                          checkPlatformCompatibility: true,
                          emojiViewConfig: EmojiViewConfig(
                            // Issue: https://github.com/flutter/flutter/issues/28894
                            emojiSizeMax: 28 *
                                (foundation.defaultTargetPlatform ==
                                        TargetPlatform.iOS
                                    ? 1.2
                                    : 1.0),
                          ),
                          swapCategoryAndBottomBar: false,
                          skinToneConfig: const SkinToneConfig(),
                          categoryViewConfig: const CategoryViewConfig(),
                          bottomActionBarConfig: const BottomActionBarConfig(),
                          searchViewConfig: const SearchViewConfig(),
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<DocumentSnapshot>> groupMessagesByDate(
      List<DocumentSnapshot> messages) {
    Map<String, List<DocumentSnapshot>> groupedMessages = {};

    for (var message in messages) {
      DateTime timestamp = (message['timeStamp'] as Timestamp).toDate();
      String date = '${timestamp.year}-${timestamp.month}-${timestamp.day}';

      if (groupedMessages.containsKey(date)) {
        groupedMessages[date]!.add(message);
      } else {
        groupedMessages[date] = [message];
      }
    }

    return groupedMessages;
  }

  Widget buildMessageWidget(List<DocumentSnapshot> messages) {
    return Column(
      children: messages.map((message) {
        String messageUserId = message.get('uid');
        String messageType = message.get('type');

        Widget messageWidget = Container();

        if (messageUserId == myUid) {
          switch (messageType) {
            case 'iSentText':
              messageWidget = textMessageISent(message);
              break;

            case 'iSentImage':
              messageWidget = imageSent(message);
              break;
            case 'iSentReply':
              messageWidget = sentReplyTextToText(message);
          }
        } else {
          switch (messageType) {
            case 'iSentText':
              messageWidget = textMessageIReceived(message);
              break;

            case 'iSentImage':
              messageWidget = imageReceived(message);
              break;
            case 'iSentReply':
              messageWidget = receivedReplyTextToText(message);
          }
        }

        return messageWidget;
      }).toList(),
    );
  }

  textMessageIReceived(DocumentSnapshot doc) {
    String message = '';
    String userName = '';
    String userImage = '';
    Timestamp time = doc.get('timeStamp');
    try {
      message = doc.get('message');
      userName = doc.get('userName');
      userImage = doc.get('image');
    } catch (e) {
      message = '';
    }
    int hour = time.toDate().hour;
    String amPm = hour < 12 ? 'AM' : 'PM';
    return Container(
      margin: const EdgeInsets.only(right: 80, top: 20),
      child: Dismissible(
        confirmDismiss: (a) async {
          replyText = message;
          await Future.delayed(const Duration(seconds: 1));
          openKeyboard();
          return false;
        },
        key: UniqueKey(),
        direction: DismissDirection.startToEnd,
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: userImage.isEmpty
                      ? const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        )
                      : CircleAvatar(
                          backgroundImage:
                              CachedNetworkImageProvider(userImage),
                          radius: 30,
                        ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      //width: 200,
                      // height: screenheight * 0.06,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          topLeft: Radius.zero,
                        ),
                        color: AppColors.greychat,
                      ),
                      child: Stack(
                        //mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Positioned(
                            top: 0,
                            left: 5,
                            child: Text(
                              userName,
                              style: TextStyle(
                                  color: AppColors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              message,
                              style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 0,
                            child: Text(
                              '${hourOf12(hour)}:${time.toDate().minute} $amPm',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String hourOf12(int hour) {
    if (hour == 0) {
      return '12';
    } else if (hour > 12) {
      return '${hour - 12}';
    } else {
      return '$hour';
    }
  }

  textMessageISent(DocumentSnapshot doc) {
    String message = doc.get('message');
    Timestamp time = doc.get('timeStamp');
    int hour = time.toDate().hour;
    String amPm = hour < 12 ? 'AM' : 'PM';

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(right: 20, left: 80, top: 20),
        //width: screenwidth * 0.7,
        // height: screenheight * 0.06,
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              topRight: Radius.zero,
              topLeft: Radius.circular(18),
            ),
            color: Color(0xFFDBF6CD)),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, right: 20),
                    child: Text(
                      '${hourOf12(hour)}:${time.toDate().minute} $amPm',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  imageSent(DocumentSnapshot doc) {
    String message = '';
    Timestamp time = Timestamp.now();

    try {
      message = doc.get('message');
      time = doc.get('timeStamp');
    } catch (e) {
      message = '';
    }
    int hour = time.toDate().hour;
    String amPm = hour < 12 ? 'AM' : 'PM';

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        margin: const EdgeInsets.only(right: 20, top: 10),
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              topRight: Radius.zero,
              topLeft: Radius.circular(18),
            ),
            color: Color(0xFFDBF6CD)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Image(
              image: NetworkImage(message),
            ),
            // const SizedBox(
            //   height: 5,
            // ),
            // Text('crossAxisAlignment: CrossAxisAlignment.end,'),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 0,
                  ),
                  child: Text(
                    '${hourOf12(hour)}:${time.toDate().minute} $amPm',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  imageReceived(DocumentSnapshot doc) {
    String message = '';
    Timestamp time = Timestamp.now();
    String userName = '';
    String userImage = '';
    try {
      message = doc.get('message');
      time = doc.get('timeStamp');
      userName = doc.get('userName');
      userImage = doc.get('image');
    } catch (e) {
      message = '';
    }
    int hour = time.toDate().hour;
    String amPm = hour < 12 ? 'AM' : 'PM';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: userImage.isEmpty
                        ? const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    )
                        : CircleAvatar(
                      backgroundImage:
                      CachedNetworkImageProvider(userImage),
                      radius: 30,
                    ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    topLeft: Radius.zero,
                  ),
                  color: AppColors.greychat,
                ),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      width: screenwidth * 0.5,
                      height: screenheight * 0.2,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(18),
                              topLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18)),
                          image: DecorationImage(
                              image: NetworkImage(message), fit: BoxFit.fill)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${hourOf12(hour)}:${time.toDate().minute} $amPm',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  sentReplyTextToText(DocumentSnapshot doc) {
    String message = '';
    String reply = '';
    String userName = '';
    Timestamp time = Timestamp.now();
    try {
      message = doc.get('message');
      time = doc.get('timeStamp');
      userName = doc.get('userName');
    } catch (e) {
      message = '';
    }

    try {
      reply = doc.get('reply');
    } catch (e) {
      reply = '';
    }

    return Container(
      margin: const EdgeInsets.only(right: 20, top: 5, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 66, top: 5),
                child: Text(
                  "You replied to $userName",
                  style: TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),
          SizedBox(
            height: screenheight * 0.006,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 0),
                width: screenwidth * 0.4,
                // height: screenheight * 0.06,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      topLeft: Radius.circular(18),
                    ),
                    color: AppColors.greychat),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    reply,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                ),
                child: Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xff918F8F),
                ),
              ),
            ],
          ),
          SizedBox(
            height: screenheight * 0.003,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 17),
                width: screenwidth * 0.43,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      topLeft: Radius.circular(18),
                    ),
                    color: Colors.black),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${time.toDate().hour}:${time.toDate().minute}',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  receivedReplyTextToText(DocumentSnapshot doc) {
    String message = '';
    String reply = '';
    String userName = '';
    String userImage = '';
    Timestamp time = Timestamp.now();
    try {
      message = doc.get('message');
      time = doc.get('timeStamp');
      userName = doc.get('userName');
      userImage = doc.get('image');
    } catch (e) {
      message = '';
    }

    try {
      reply = doc.get('reply');
    } catch (e) {
      reply = '';
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 66, top: 5),
                child: Text(
                  "Replied to you ",
                  style: TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),
          SizedBox(
            height: screenheight * 0.006,
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 65, right: 10),
                child: Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xff918F8F),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 0),
                width: screenwidth * 0.4,
                // height: screenheight * 0.06,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      topLeft: Radius.circular(18),
                    ),
                    color: Colors.black),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    reply,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: screenheight * 0.003,
          ),
          Row(
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: userImage.isEmpty
                      ? const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  )
                      : CircleAvatar(
                    backgroundImage:
                    CachedNetworkImageProvider(userImage),
                    radius: 30,
                  ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 17),
                width: screenwidth * 0.43,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      topLeft: Radius.circular(18),
                    ),
                    color: AppColors.greychat),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 73, top: 2),
                child: Text(
                  '${time.toDate().hour}:${time.toDate().minute}',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void openMediaDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    Navigator.pop(context);

                    dataController!.isMessageSending(true);

                    String imageUrl = await dataController!
                        .uploadImageToFirebase(File(image.path));

                    Map<String, dynamic> data = {
                      'type': 'iSentImage',
                      'message': imageUrl,
                      'timeStamp': Timestamp.now(),
                      'uid': myUid,
                      'image': myImage,
                    };

                    dataController!.sendMessageToFirebase(
                        data: data, lastMessage: 'Image');
                  }
                },
                child: const Icon(
                  Icons.camera_alt,
                  size: 30,
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              InkWell(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    Navigator.pop(context);
                    dataController!.isMessageSending(true);

                    String imageUrl = await dataController!
                        .uploadImageToFirebase(File(image.path));

                    Map<String, dynamic> data = {
                      'type': 'iSentImage',
                      'message': imageUrl,
                      'timeStamp': Timestamp.now(),
                      'uid': myUid,
                      'image': myImage,
                    };

                    dataController!.sendMessageToFirebase(
                        data: data, lastMessage: 'Image');
                  }
                },
                child: const Icon(Icons.photo)
              ),
            ],
          ),
        );
      },
    );
  }
}
