import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as Path;

class CreateStory extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CreateStoryView();
  }
}

class CreateStoryView extends State<CreateStory> {
  final FlutterFFmpegConfig _flutterFFmpegConfig = new FlutterFFmpegConfig();
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  Directory tempDirectory;
  Future<String> combinedVideo;
  List videos = [];

  @override
  void initState() {
    getDirectory();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getDirectory() async {
    tempDirectory = await getTemporaryDirectory();
    setFontConfigConfigurationPath(tempDirectory.path);
  }

  Future<void> setFontConfigConfigurationPath(String path) async {
    await _flutterFFmpegConfig.setFontconfigConfigurationPath(path);
  }

  String getVideoPath(String assetName) {
    return Path.join(tempDirectory.path, assetName);
  }

  Future chooseVideo() async {
    this.videos = [];
    await FilePicker.getMultiFile().then((List<dynamic> videosPaths) {
      videosPaths.forEach((path) {
        this.videos.add(path
            .toString()
            .replaceAll(RegExp('File:'), '')
            .replaceAll(RegExp("'"), ""));
      });
      combineVideos();
    });
  }

  String _initVideosCode() {
    String ffmpegInputs = "";
    String ffmpegFilter = "";
    this.getDirectory();
    String output = getVideoPath('output.mp4');
    for (var i = 0; i < this.videos.length; i++) {
      ffmpegFilter += "[$i:v:0][$i:a:0]";
      ffmpegInputs += "-i ${videos[i]} ";
    }
    print('$ffmpegInputs-filter_complex ${ffmpegFilter}concat=n=${videos.length}:v=1:a=1[outv][outa] -map [outv] -map [outa] -vsync 2 $output"');
    return "$ffmpegInputs-filter_complex ${ffmpegFilter}concat=n=${videos.length}:v=1:a=1[outv][outa] -map [outv] -map [outa] -vsync 2 $output";
  }

  void deleteDirectory() {
    final dir = Directory(this.tempDirectory.path);
    dir.deleteSync(recursive: true);
  }

  void combineVideos() async {
    if (this.videos.length > 1) {
      _flutterFFmpeg.execute(_initVideosCode()).then((code) {
        if (code == 0) {
          print('Done!');
          setState(() {
            this.combinedVideo = getVideo();
          });
        } else {
          print('Error');
        }
      });
    } else {
      print('Videos can not be less than 2');
    }
  }

  Future<String> getVideo() async {
    return getVideoPath('output.mp4');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Container(
          alignment: Alignment.center,
          child: Text(
            "Stories",
            style: TextStyle(color: Color(0xFFBEB2C0)),
          ),
        ),
        leading: Container(
          child: IconButton(
            onPressed: () => chooseVideo(),
            icon: Image.asset(
              "assets/story1.png",
              height: 22,
            ),
          ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () => {},
            child: Text("Edit",
                style: TextStyle(color: Color(0xFF49C1FF), fontSize: 20)),
          ),
        ],
      ),
      body: Theme(
        data: Theme.of(context)
            .copyWith(scaffoldBackgroundColor: Color(0xFFEEF8FF)),
        child: Scaffold(
          body: SafeArea(
            child: FutureBuilder<String>(
              future: combinedVideo,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  final chewieController = ChewieController(
                    videoPlayerController:
                        VideoPlayerController.file(File(snapshot.data)),
                    aspectRatio: 3 / 2,
                    autoPlay: false,
                    autoInitialize: true,
                    allowFullScreen: false,
                  );
                  final playerWidget = Chewie(
                    controller: chewieController,
                  );
                  return ListView(
                    children: <Widget>[playerWidget],
                  );
                }
                return noAvailableStoriesLayout();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget noAvailableStoriesLayout() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("Choose your moments", style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Text("To create the story", style: TextStyle(fontSize: 18)),
          FlatButton(
            onPressed: () => deleteDirectory(),
            child: Text("Delete Video direcotry"),
          ),
        ],
      ),
    );
  }
}
