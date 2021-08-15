import 'dart:async';

import 'package:Goomtok/firebaseDB/auth.dart';
import 'package:Goomtok/models/live.dart';
import 'package:Goomtok/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uni_links/uni_links.dart';

import '../firebaseDB/firestoreDB.dart';
import '../models/global.dart';
import '../models/post.dart';
import 'agora/host.dart';
import 'agora/join.dart';

class HomePage extends StatefulWidget {
  final User user;

  HomePage(this.user);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlareControls flareControls = FlareControls();
  final db = FirebaseFirestore.instance;
  List<Live> list = [];
  bool ready = false;
  Live liveUser;

  // var name;
  // var image = 'https://nichemodels.co/wp-content/uploads/2019/03/user-dummy-pic.png';
  // var username;
  var postUsername;
  StreamSubscription _sub;
  String initialLink, channelName;
  final TextEditingController channelNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return getMain();
  }

  @override
  void initState() {
    super.initState();
    initUniLinks();
    // loadSharedPref();
    list = [];
    liveUser = Live(username: widget.user.username, me: true, image: widget.user.image);
    setState(() => list.add(liveUser));
    dbChangeListen();
    /*var date = DateTime.now();
    var newDate = '${DateFormat("dd-MM-yyyy hh:mm:ss").format(date)}';
    */
  }

  // Future<void> loadSharedPref() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     name = prefs.getString('name') ?? 'Jon Doe';
  //     username = prefs.getString('username') ?? 'jon';
  //     image = prefs.getString('image') ?? 'https://nichemodels.co/wp-content/uploads/2019/03/user-dummy-pic.png';
  //   });
  // }

  void dbChangeListen() {
    db.collection(FireStoreClass.liveCollection).orderBy("time", descending: true).snapshots().listen((result) {
      setState(() {
        list = [];
        liveUser = Live(username: widget.user.username, me: true, image: widget.user.image);
        list.add(liveUser);
      });
      result.docs.forEach((result) {
        setState(() {
          list.add(Live(
            username: result.data()['name'],
            image: result.data()['image'],
            channelId: result.data()['channel'],
            me: false,
          ));
        });
      });
    });
  }

  Widget getMain() {
    return Scaffold(
      appBar: AppBar(
        leading: Transform.translate(
            offset: Offset(-5, 0),
            child: Icon(
              FontAwesomeIcons.camera,
              // color: Colors.white,
            )),
        titleSpacing: -10,
        title: Text('Goomtok', style: TextStyle(fontFamily: 'Billabong', fontSize: 28)),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(
              FontAwesomeIcons.paperPlane,
              // color: Colors.white,
            ),
          ),
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () => logout(context),
                child: Icon(Icons.exit_to_app),
              )),
        ],
        // backgroundColor: Colors.black87,
      ),
      body: Container(
          // color: Colors.black,
          child: ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(height: 100, child: getStories()),
              Divider(height: 0),
              Column(children: getPosts(context)),
              SizedBox(height: 10)
            ],
          )
        ],
      )),
    );
  }

  Widget getStories() {
    return ListView(scrollDirection: Axis.horizontal, children: getUserStories());
  }

  List<Widget> getUserStories() {
    List<Widget> stories = [];
    for (Live user in list) {
      stories.add(getStory(user));
    }
    return stories;
  }

  Widget getStory(Live user) {
    return Container(
      margin: EdgeInsets.all(5),
      child: Column(
        children: <Widget>[
          Flexible(
            child: Container(
              height: 70,
              width: 70,
              child: GestureDetector(
                onTap: () {
                  if (user.me == true) {
                    onHost(username: user.username, image: user.image);
                  } else {
                    onJoin(
                        channelName: user.username, channelId: user.channelId, username: user.username, hostImage: user.image, userImage: user.image);
                  }
                },
                child: Stack(
                  alignment: Alignment(0, 0),
                  children: <Widget>[
                    !user.me
                        ? Container(
                            height: 60,
                            width: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                      colors: [Colors.indigo, Colors.blue, Colors.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                            ),
                          )
                        : SizedBox(
                            height: 0,
                          ),
                    Container(
                      height: 55.5,
                      width: 55.5,
                      child: CircleAvatar(
                        backgroundColor: Colors.black,
                      ),
                    ),
                    CachedNetworkImage(
                      imageUrl: user.image,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 52.0,
                        height: 52.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    user.me
                        ? Container(
                            height: 55,
                            width: 55,
                            alignment: Alignment.bottomRight,
                            child: Container(
                              decoration: new BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 13.5,
                                // color: Colors.white,
                              ),
                            ))
                        : Container(
                            height: 70,
                            width: 70,
                            alignment: Alignment.bottomCenter,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Container(
                                  height: 17,
                                  width: 25,
                                  decoration: new BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.all(Radius.circular(4.0) //         <--- border radius here
                                        ),
                                    gradient:
                                        LinearGradient(colors: [Colors.black, Colors.black], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                  ),
                                ),
                                Container(
                                  decoration: new BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.all(Radius.circular(2.0) //         <--- border radius here
                                        ),
                                    gradient: LinearGradient(
                                        colors: [Colors.indigo, Colors.blueAccent], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                      'LIVE',
                                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 3),
          Text(user.username ?? '')
        ],
      ),
    );
  }

  List<Widget> getPosts(BuildContext context) {
    List<Widget> posts = [];
    int index = 0;
    for (Post post in userPosts) {
      posts.add(getPost(context, post, index));
      index++;
    }
    return posts;
  }

  Widget getPost(BuildContext context, Post post, int index) {
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(right: 10),
                    height: 30,
                    width: 30,
                    child: CircleAvatar(
                      backgroundImage: AssetImage(post.userPic),
                    ),
                  ),
                  Text(
                    post.user,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    // style: TextStyle(color: Colors.white),
                  )
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  // color: Colors.white,
                ),
                onPressed: () {},
              )
            ],
          ),
        ),
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              userPosts[index].isLiked = post.isLiked ? true : true;
            });
          },
          child: Container(
            constraints: BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(color: Colors.black, image: DecorationImage(image: post.image)),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                post.isLiked
                    ? Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                userPosts[index].isLiked = post.isLiked ? false : true;
                              });
                            },
                            child: Icon(
                              Icons.favorite,
                              size: 30,
                              color: Colors.lightBlue,
                            )),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                userPosts[index].isLiked = post.isLiked ? false : true;
                              });
                            },
                            child: Icon(
                              Icons.favorite_border,
                              size: 30,
                              // color: Colors.white,
                            )),
                      ),
                Padding(
                  padding: const EdgeInsets.only(left: 13),
                  child: Icon(
                    FontAwesomeIcons.comment,
                    size: 25,
                    // color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 13),
                  child: Icon(
                    FontAwesomeIcons.paperPlane,
                    size: 23,
                    // color: Colors.white,
                  ),
                ),
              ],
            ),
            Stack(
              alignment: Alignment(0, 0),
              children: <Widget>[
                Icon(
                  FontAwesomeIcons.bookmark,
                  size: 28,
                  // color: Colors.white,
                ),
                IconButton(
                  icon: Icon(Icons.bookmark),
                  // color: post.isSaved ? Colors.white : Colors.black,
                  onPressed: () {
                    setState(() {
                      userPosts[index].isSaved = post.isSaved ? false : true;
                    });
                  },
                )
              ],
            )
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 15, right: 10),
              child: Text(
                post.user,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              post.description,
              // style: textStyle,
            )
          ],
        ),
        SizedBox(
          height: 10,
        )
      ],
    ));
  }

  onJoinFromLink() {
    if (initialLink != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JoinPage(
            channelName: initialLink,
            channelId: int.parse(initialLink),
            username: initialLink,
            // hostImage: initialLink,
            // userImage: userImage,
          ),
        ),
      );
    }
  }

  Future<void> onJoin({channelName, channelId, username, hostImage, userImage}) async {
    // update input validation
    if (channelName.isNotEmpty) {
      await _handleCameraAndMic();
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JoinPage(
            channelName: channelName,
            channelId: channelId,
            username: username,
            hostImage: hostImage,
            userImage: userImage,
          ),
        ),
      );
    }
  }

  Future<void> onHost({username, image}) async {
    // await for camera and mic permissions before pushing video page
    await _handleCameraAndMic();
    final DateTime date = DateTime.now();
    final String currentTime = '${DateFormat("dd-MM-yyyy hh:mm:ss").format(date)}';
    // push video page with given channel name
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VideoCall(
                  channelName: username,
                  time: currentTime,
                  image: image,
                )));
  }

  Future<void> _handleCameraAndMic() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
  }

  Future<void> initUniLinks() async {
    if (!kIsWeb) {
      try {
        final link = await getInitialLink();
        if (link == null) return;
        final List<String> list = link.split('/');
        setState(() => initialLink = list[3]);
        return;
      } on PlatformException {}
      _sub = uriLinkStream.listen((Uri uri) {
        if (!mounted) return;
        final List<String> list = uri.toString().split('/');
        setState(() => initialLink = list[3]);
      }, onError: (Object err) {
        if (!mounted) return;
        print('got err: $err');
        setState(() {
          // _latestUri = null;
          if (err is FormatException) {
            // _err = err;
          } else {
            // _err = null;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> channelNameDialog() async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Channel name'),
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: channelNameController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Choose channel name',
                contentPadding: EdgeInsets.only(bottom: 10),
              ),
            ),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('GO'))
        ],
      ),
    );
  }
}
