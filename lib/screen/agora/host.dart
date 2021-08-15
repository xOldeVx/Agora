import 'dart:async';
import 'dart:math' as math;

import 'package:Goomtok/firebaseDB/api.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wakelock/wakelock.dart';

import '../../firebaseDB/firestoreDB.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../utils/setting.dart';

class VideoCall extends StatefulWidget {
  final String channelName, image, time;

  const VideoCall({Key key, this.channelName, this.time, this.image}) : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  List<int> _users = <int>[];
  List<User> _chatUsers = [];

  bool tryingToEnd = false;
  bool heart = false;
  bool anyPerson = false;
  bool personBool = false;
  bool accepted = false;
  bool _isLogin = true;
  bool _isInChannel = true;
  int viewersNumber = 1;
  var myUserImage;
  final _channelMessageController = TextEditingController();

  RtcEngine _rtcEngine; // Video API
  AgoraRtmClient _rtmClient; // Messages API
  AgoraRtmChannel _rtmChannel; // Messages API

  //Love animation
  final _random = math.Random();
  Timer _timer;
  double height = 0.0;
  int _numConfetti = 5;
  int guestID = -1;
  bool waiting = false;
  String rtcToken, userId, resourceId, sid;

  final _infoStrings = <Message>[];

  @override
  void initState() {
    super.initState();
    myUserImage = {widget.channelName: widget.image};
    initialize();
  }

  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // configuration.dimensions = VideoDimensions(height: 1920, width: 1080);
    await _rtcEngine.setVideoEncoderConfiguration(configuration);
    Api.getTokens(channelName: widget.channelName, userId: widget.channelName).then((value) {
      rtcToken = value['rtcToken'];
      _rtcEngine.joinChannel(value['rtcToken'], widget.channelName, null, 0);
      _createRtmClient(value['rtmToken']);
    });
    // await _rtcEngine.joinChannel(
    //     '006d219fee717034a0a9ebb69b0aeb71b0bIAAtGMhR7Fx5/6jx9o5P9D3m4nS/tYc29pLgWgy1ck+gDfxVPA4AAAAAEAC4541ohQnwYAEAAQCFCfBg', 'am', null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _rtcEngine = await RtcEngine.create(APP_ID);
    await _rtcEngine.enableVideo();
    await _rtcEngine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _rtcEngine.setClientRole(ClientRole.Broadcaster);
  }

  void _addAgoraEventHandlers() {
    _rtcEngine.setEventHandler(RtcEngineEventHandler(error: (code) {
      print(rtcToken);
      setState(() => _log(user: widget.channelName, info: 'onError: $code', type: 'sys'));
    }, joinChannelSuccess: (channel, uid, elapsed) async {
      FireStoreClass.createLiveUser(name: widget.channelName, id: uid, time: widget.time, image: widget.image);
      userId = uid.toString();
      while (resourceId == null) {
        resourceId = await Api.createAcquire(channelName: widget.channelName, userId: userId);
      }
      print(resourceId);
      print(resourceId);
      setState(() => _log(user: widget.channelName, info: 'room is created', type: 'sys'));
      await Wakelock.enable();
    }, leaveChannel: (stats) {
      _users.clear();
      setState(() => _log(user: widget.channelName, info: 'onLeaveChannel:', type: 'sys'));
    }, userJoined: (uid, elapsed) {
      _users.add(uid);
      setState(() => _log(user: uid.toString(), info: 'joined', type: 'sys'));
    }, userOffline: (uid, elapsed) {
      _users.remove(uid);
      setState(() => _log(user: uid.toString(), info: 'left: $uid', type: 'sys'));
    }));
  }

  void _createRtmClient(String rtmToken) async {
    _rtmClient = await AgoraRtmClient.createInstance(APP_ID);
    _rtmClient.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      _log(user: peerId, info: message.text, type: 'sys');
      // _log(user: peerId, info: message.text, type: 'message');
    };
    _rtmClient.onConnectionStateChanged = (int state, int reason) {
      _log(type: 'sys', user: widget.channelName, info: '$state $reason');
      if (state == 5) {
        _rtmClient.logout();
        _log(type: 'sys', user: widget.channelName, info: 'Logout.');
        setState(() => _isLogin = false);
      }
    };

    try {
      _rtmChannel = await _createRtmChannelAndEvents(widget.channelName);
      await _rtmClient.login(rtmToken, widget.channelName);
      await _rtmChannel.join();
    } catch (e) {
      print(e);
    }
  }

  Future<AgoraRtmChannel> _createRtmChannelAndEvents(String name) async {
    AgoraRtmChannel channel = await _rtmClient.createChannel(name);

    channel.onMemberJoined = (AgoraRtmMember member) async {
      var img = await FireStoreClass.getImage(username: member.userId);
      var nm = await FireStoreClass.getName(username: member.userId);
      setState(() {
        _chatUsers.add(new User(username: member.userId, name: nm, image: img));
        if (_chatUsers.length > 0) anyPerson = true;
      });
      myUserImage.putIfAbsent(member.userId, () => img);
      var len;
      _rtmChannel.getMembers().then((value) {
        len = value.length;
        setState(() {
          viewersNumber = len;
        });
      });
      _log(info: 'Member joined: ', user: member.userId, type: 'sys');
    };

    channel.onMemberLeft = (AgoraRtmMember member) {
      var len;
      setState(() {
        _chatUsers.removeWhere((element) => element.username == member.userId);
        if (_chatUsers.length == 0) anyPerson = false;
      });
      _rtmChannel.getMembers().then((value) {
        len = value.length;
        setState(() {
          viewersNumber = len;
        });
      });
    };

    channel.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
      _log(user: member.userId, info: message.text, type: 'message');
    };

    return channel;
  }

  // _addRtmEventHandlers(AgoraRtmChannel channel) {
  //   channel.onMemberJoined = (AgoraRtmMember member) async {
  //     var img = await FireStoreClass.getImage(username: member.userId);
  //     var nm = await FireStoreClass.getName(username: member.userId);
  //     setState(() {
  //       _chatUsers.add(new User(username: member.userId, name: nm, image: img));
  //       if (_chatUsers.length > 0) anyPerson = true;
  //     });
  //     myUserImage.putIfAbsent(member.userId, () => img);
  //     var len;
  //     _rtmChannel.getMembers().then((value) {
  //       len = value.length;
  //       setState(() {
  //         userNo = len;
  //       });
  //     });
  //     _log(info: 'Member joined: ', user: member.userId, type: 'sys');
  //   };
  //
  //   channel.onMemberLeft = (AgoraRtmMember member) {
  //     var len;
  //     setState(() {
  //       _chatUsers.removeWhere((element) => element.username == member.userId);
  //       if (_chatUsers.length == 0) anyPerson = false;
  //     });
  //     _rtmChannel.getMembers().then((value) {
  //       len = value.length;
  //       setState(() {
  //         userNo = len;
  //       });
  //     });
  //   };
  //
  //   channel.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
  //     _log(user: member.userId, info: message.text, type: 'message');
  //   };
  // }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    list.add(RtcLocalView.SurfaceView());
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[_expandedVideoRow(views.sublist(0, 2)), _expandedVideoRow(views.sublist(2, 3))],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[_expandedVideoRow(views.sublist(0, 2)), _expandedVideoRow(views.sublist(2, 4))],
        ));
      default:
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: SafeArea(
        child: Scaffold(
          body: Center(
            child: Stack(
              children: <Widget>[
                _viewRows(),
                // Container(
                //   child: Text(
                //     'HEY',
                //     style: TextStyle(color: Colors.red),
                //   ),
                // )
                if (tryingToEnd == false) _endCall(),
                if (tryingToEnd == false) _topLiveText(),
                // if (heart == true && tryingToEnd == false) heartPop(),
                if (tryingToEnd == false) _bottomBar(), // send message
                if (tryingToEnd == false) messageList(),
                if (tryingToEnd == true) endLive(), // view message
                // if (personBool == true && waiting == false) personList(),
                if (accepted == true) stopSharing(),
                if (waiting == true) guestWaiting(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget personList() {
  //   return Container(
  //     alignment: Alignment.bottomRight,
  //     child: Container(
  //       height: 2 * MediaQuery.of(context).size.height / 3,
  //       width: MediaQuery.of(context).size.height,
  //       decoration: new BoxDecoration(
  //         color: Colors.grey[850],
  //         borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
  //       ),
  //       child: Stack(
  //         children: <Widget>[
  //           Container(
  //             height: 2 * MediaQuery.of(context).size.height / 3 - 50,
  //             child: Column(
  //               children: <Widget>[
  //                 SizedBox(
  //                   height: 10,
  //                 ),
  //                 Container(
  //                   padding: EdgeInsets.symmetric(vertical: 12),
  //                   width: MediaQuery.of(context).size.width,
  //                   alignment: Alignment.center,
  //                   child: Text(
  //                     'Go Live with',
  //                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
  //                   ),
  //                 ),
  //                 SizedBox(
  //                   height: 10,
  //                 ),
  //                 Divider(
  //                   color: Colors.grey[800],
  //                   thickness: 0.5,
  //                   height: 0,
  //                 ),
  //                 Container(
  //                   padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
  //                   width: double.infinity,
  //                   color: Colors.grey[900],
  //                   child: Text(
  //                     'When you go live with someone, anyone who can watch their live videos will be able to watch it too.',
  //                     textAlign: TextAlign.center,
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.grey[400],
  //                     ),
  //                   ),
  //                 ),
  //                 anyPerson == true
  //                     ? Container(
  //                         padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
  //                         width: double.maxFinite,
  //                         child: Text(
  //                           'INVITE',
  //                           style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
  //                           textAlign: TextAlign.start,
  //                         ))
  //                     : Padding(
  //                         padding: const EdgeInsets.only(top: 10),
  //                         child: Text(
  //                           'No Viewers',
  //                           style: TextStyle(color: Colors.grey[400]),
  //                         ),
  //                       ),
  //                 Expanded(
  //                   child: ListView(shrinkWrap: true, scrollDirection: Axis.vertical, children: getUserStories()),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Align(
  //             alignment: Alignment.bottomCenter,
  //             child: GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   personBool = !personBool;
  //                 });
  //               },
  //               child: Container(
  //                 color: Colors.grey[850],
  //                 alignment: Alignment.bottomCenter,
  //                 height: 50,
  //                 child: Stack(
  //                   children: <Widget>[
  //                     Container(
  //                         height: double.maxFinite,
  //                         alignment: Alignment.center,
  //                         child: Text(
  //                           'Cancel',
  //                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  //                         )),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  List<Widget> getUserStories() {
    List<Widget> stories = [];
    for (User users in _chatUsers) {
      stories.add(getStory(users));
    }
    return stories;
  }

  Widget getStory(User users) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 7.5),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () async {
              setState(() {
                waiting = true;
              });
              await _rtmChannel.sendMessage(AgoraRtmMessage.fromText('d1a2v3i4s5h6 ${users.username}'));
            },
            child: Container(
                padding: EdgeInsets.only(left: 15),
                color: Colors.grey[850],
                child: Row(
                  children: <Widget>[
                    CachedNetworkImage(
                      imageUrl: users.image,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        children: <Widget>[
                          Text(
                            users.username,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            users.name,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget stopSharing() {
    return Container(
      height: MediaQuery.of(context).size.height / 2 + 40,
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: MaterialButton(
          minWidth: 0,
          onPressed: () async {
            stopFunction();
            await _rtmChannel.sendMessage(AgoraRtmMessage.fromText('E1m2I3l4i5E6 stoping'));
          },
          child: Icon(
            Icons.clear,
            color: Colors.white,
            size: 15.0,
          ),
          shape: CircleBorder(),
          elevation: 2.0,
          color: Colors.blue[400],
          padding: const EdgeInsets.all(5.0),
        ),
      ),
    );
  }

  Widget messageList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return null;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: (_infoStrings[index].type == 'sys')
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            CachedNetworkImage(
                              imageUrl: _infoStrings[index].image,
                              imageBuilder: (context, imageProvider) => Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '${_infoStrings[index].user} ${_infoStrings[index].message}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : (_infoStrings[index].type == 'message')
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                CachedNetworkImage(
                                  imageUrl: _infoStrings[index].image,
                                  imageBuilder: (context, imageProvider) => Container(
                                    width: 32.0,
                                    height: 32.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        _infoStrings[index].user,
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        _infoStrings[index].message,
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        : null,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _willPopCallback() async {
    if (personBool == true) {
      setState(() {
        personBool = false;
      });
    } else {
      setState(() {
        tryingToEnd = !tryingToEnd;
      });
    }
    return false; // return true if the route to be popped
  }

  void popUp() async {
    setState(() {
      heart = true;
    });

    _timer = Timer.periodic(Duration(milliseconds: 125), (Timer t) {
      setState(() {
        height += _random.nextInt(20);
      });
    });

    Timer(
        Duration(seconds: 4),
        () => {
              _timer.cancel(),
              setState(() {
                heart = false;
              })
            });
  }

  // Widget heartPop() {
  //   final size = MediaQuery.of(context).size;
  //   final confetti = <Widget>[];
  //   for (var i = 0; i < _numConfetti; i++) {
  //     final height = _random.nextInt(size.height.floor());
  //     final width = 20;
  //     confetti.add(HeartAnim(height % 200.0, width.toDouble(), 0.5));
  //   }
  //
  //   return Container(
  //     child: Padding(
  //       padding: const EdgeInsets.only(bottom: 20),
  //       child: Align(
  //         alignment: Alignment.bottomRight,
  //         child: Container(
  //           height: 400,
  //           width: 200,
  //           child: Stack(
  //             children: confetti,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _endCall() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            child: GestureDetector(
              onTap: () {
                if (personBool == true) {
                  setState(() {
                    personBool = false;
                  });
                }
                setState(() {
                  if (waiting == true) {
                    waiting = false;
                  }
                  tryingToEnd = true;
                });
              },
              child: Text(
                'END',
                style: TextStyle(color: Colors.indigo, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topLiveText() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            InkWell(
              // onTap: () async => await Api.createAcquire(channelName: widget.channelName, userId: userId),
              onTap: () async {
                while (sid == null) {
                  sid = await Api.startRecording(channelName: widget.channelName, userId: userId, rtcToken: rtcToken, resourceId: resourceId);
                }
                print(sid);
                print('-------------START RECORDING!---------------');
              },
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Colors.indigo, Colors.blue],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(4.0))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                  child: Text(
                    'LIVE',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 10),
              child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.6), borderRadius: BorderRadius.all(Radius.circular(4.0))),
                  height: 28,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          FontAwesomeIcons.eye,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          '$viewersNumber',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget endLive() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(
                'Are you sure you want to end your live video?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 8.0, bottom: 8.0),
                    child: RaisedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'End Video',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      elevation: 2.0,
                      color: Colors.blue,
                      onPressed: () async {
                        await Wakelock.disable();
                        _logoutRtmClient();
                        _leaveRtmChannel();
                        _rtcEngine.leaveChannel();
                        _rtcEngine.destroy();
                        FireStoreClass.deleteUser(username: widget.channelName);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 8.0, top: 8.0, bottom: 8.0),
                    child: RaisedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      elevation: 2.0,
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          tryingToEnd = false;
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget guestWaiting() {
    return Container(
      alignment: Alignment.bottomRight,
      child: Container(
          height: 100,
          width: double.maxFinite,
          alignment: Alignment.center,
          color: Colors.black,
          child: Wrap(
            children: <Widget>[
              Text(
                'Waiting for the user to accept...',
                style: TextStyle(color: Colors.white, fontSize: 20),
              )
            ],
          )),
    );
  }

  void _addPerson() {
    // setState(() {
    //   personBool = !personBool;
    // });
  }

  void stopFunction() {
    setState(() {
      accepted = false;
    });
  }

  Widget _bottomBar() {
    if (!_isLogin || !_isInChannel) {
      return Container();
    }
    return Container(
      alignment: Alignment.bottomRight,
      child: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 5, right: 8, bottom: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            new Expanded(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 0, 0, 0),
              child: TextField(
                  cursorColor: Colors.blue,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  style: TextStyle(color: Colors.white),
                  controller: _channelMessageController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Comment',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0), borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0), borderSide: BorderSide(color: Colors.white)),
                  )),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
              child: MaterialButton(
                minWidth: 0,
                onPressed: _toggleSendChannelMessage,
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                color: Colors.blue[400],
                padding: const EdgeInsets.all(12.0),
              ),
            ),
            if (accepted == false)
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
                child: MaterialButton(
                  minWidth: 0,
                  onPressed: _addPerson,
                  child: Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  color: Colors.blue[400],
                  padding: const EdgeInsets.all(12.0),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
              child: MaterialButton(
                minWidth: 0,
                onPressed: () => _rtcEngine.switchCamera(),
                child: Icon(
                  Icons.switch_camera,
                  color: Colors.blue[400],
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            )
          ]),
        ),
      ),
    );
  }

  void _sendMessage(text) async {
    if (text.isEmpty) {
      return;
    }
    try {
      _channelMessageController.clear();
      await _rtmChannel.sendMessage(AgoraRtmMessage.fromText(text));
      _log(user: widget.channelName, info: text, type: 'message');
    } catch (errorCode) {
      _log(info: 'Send channel message error: ' + errorCode.toString(), type: 'sys');
    }
  }

  void _logoutRtmClient() async {
    try {
      await _rtmClient.logout();
      _log(info: 'Logout success.', type: 'sys');
    } catch (errorCode) {
      _log(info: 'Logout error: ' + errorCode.toString(), type: 'sys');
    }
  }

  void _leaveRtmChannel() async {
    try {
      await _rtmChannel.leave();
      _log(info: 'Leave channel success.', type: 'sys');
      _rtmClient.releaseChannel(_rtmChannel.channelId);
      _channelMessageController.text = null;
    } catch (errorCode) {
      _log(info: 'Leave channel error: ' + errorCode.toString(), type: 'sys');
    }
  }

  void _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      return;
    }
    try {
      _channelMessageController.clear();
      await _rtmChannel.sendMessage(AgoraRtmMessage.fromText(text));
      _log(user: widget.channelName, info: text, type: 'message');
    } catch (errorCode) {
      _log(info: 'Send channel message error: ' + errorCode.toString(), type: 'sys');
    }
  }

  void _log({String info, String type, String user}) {
    if (type == 'message' && info.contains('m1x2y3z4p5t6l7k8')) {
      popUp();
    } else if (type == 'message' && info.contains('k1r2i3s4t5i6e7')) {
      setState(() {
        accepted = true;
        personBool = false;
        waiting = false;
      });
    } else if (type == 'message' && info.contains('E1m2I3l4i5E6')) {
      stopFunction();
    } else if (type == 'message' && info.contains('R1e2j3e4c5t6i7o8n9e0d')) {
      setState(() {
        waiting = false;
      });
      /*FlutterToast.showToast(
          msg: "Guest Declined",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0
      );*/

    } else {
      var image = myUserImage[user];
      Message m = Message(
          message: info,
          type: type,
          user: user,
          image: type == 'sys' ? 'https://icons-for-free.com/iconfiles/png/512/Robot-1320568045013231116.png' : image);
      setState(() {
        _infoStrings.insert(0, m);
      });
    }
  }

  @override
  void dispose() async {
    // String recorded;
    // while (recorded == null) {
    //   recorded = await Api.stopRecording(channelName: widget.channelName, userId: userId, resourceId: resourceId, sid: sid);
    // }
    // print(recorded);
    // print(recorded);
    _users.clear();
    _chatUsers.clear();
    _rtcEngine.leaveChannel();
    _rtcEngine.destroy();
    super.dispose();
  }
}
