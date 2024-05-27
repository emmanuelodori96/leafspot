import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:diagno/search/search_controller.dart' as search;

import '../pages/video_page.dart';

class SecondTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final search.SearchController searchController = Get.find();

    return Obx(() {
      final searchQuery = searchController.searchQuery.value;

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('videos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final videos = snapshot.data!.docs.where((doc) {
            final title = doc['title'].toString().toLowerCase();
            return title.contains(searchQuery.toLowerCase());
          }).toList();

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return VideoListItem(
                  videoUrl: videos[index]['videoPath'],
                  title: videos[index]['title'],
                );
            },
          );
        },
      );
    });
  }
}

class VideoListItem extends StatefulWidget {
  final String videoUrl;
  final String title;

  VideoListItem({required this.videoUrl, required this.title});

  @override
  _VideoListItemState createState() => _VideoListItemState();
}

class _VideoListItemState extends State<VideoListItem> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(widget.title),
            onTap: () {
              Get.to(() => VideoPage(
                    videoUrl: widget.videoUrl,
                    videoTitle: widget.title,
                  ));
            },
          ),
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),

                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          ListTile(
            leading: IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            title:  VideoProgressIndicator(_controller, allowScrubbing: true),
          ),


        ],
      );

  }
}
