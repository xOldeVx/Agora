import 'dart:async';
import 'dart:math' as math;

import 'package:Goomtok/firebaseDB/api.dart';
import 'package:Goomtok/firebaseDB/firestoreDB.dart';
import 'package:Goomtok/models/message.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wakelock/wakelock.dart';

import '../../utils/setting.dart';
import '../HearAnim.dart';

class JoinPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;
  final int channelId;
  final String username;
  final String hostImage;
  final String userImage;

  /// Creates a call page with given channel name.
  const JoinPage({Key key, this.channelName, this.channelId, this.username, this.hostImage, this.userImage}) : super(key: key);

  @override
  _JoinPageState createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  List<int> _users = [];

  bool completed = false; // unique to join
  bool muted = true; // unique to join
  int viewersNumber = 0;
  Map userMap;

  bool heart = false;
  bool requested = false;

  bool _isLogin = true;
  bool _isInChannel = true;

  final _channelMessageController = TextEditingController();

  final _infoStrings = <Message>[];

  RtcEngine _rtcEngine;
  AgoraRtmClient _rtmClient;
  AgoraRtmChannel _rtmChannel;

  //Love animation
  final _random = math.Random();
  Timer _timer;
  double height = 0.0;
  int _numConfetti = 10;
  var len;
  bool accepted = false;
  bool stop = false;
  // Map<String, dynamic> tokens;

  @override
  void initState() {
    super.initState();
    userMap = {widget.username: widget.userImage};
    initialize();
  }

  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // configuration.dimensions = VideoDimensions(height: 1920, width: 1080);
    await _rtcEngine.setVideoEncoderConfiguration(configuration);

    Api.getTokens(channelName: widget.channelName, userId: widget.username).then((value) {
      _rtcEngine.joinChannel(value['rtcToken'], widget.channelName, null, 0);
      _createRtmClient(value['rtmToken']);
    });
    // await _rtcEngine.joinChannel(
    //     '006d219fee717034a0a9ebb69b0aeb71b0bIAAtGMhR7Fx5/6jx9o5P9D3m4nS/tYc29pLgWgy1ck+gDfxVPA4AAAAAEAC4541ohQnwYAEAAQCFCfBg', 'am', null, 0);
    // _createRtmClient();
  }

  Future<void> _initAgoraRtcEngine() async {
    _rtcEngine = await RtcEngine.create(APP_ID);
    await _rtcEngine.enableVideo();
    await _rtcEngine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _rtcEngine.setClientRole(ClientRole.Broadcaster);
  }

  void _addAgoraEventHandlers() {
    _rtcEngine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        _log(info: 'onError: $code');
      });
    }, joinChannelSuccess: (channel, uid, elapsed) async {
      await Wakelock.enable();
    }, userJoined: (uid, elapsed) {
      _users.add(uid);
      setState(() => _log(user: uid.toString(), info: 'joined', type: 'sys'));
    }, userOffline: (uid, reason) {
      if (uid == widget.channelId) {
        setState(() {
          completed = true;
          Future.delayed(const Duration(milliseconds: 1500), () async {
            await Wakelock.disable();
            Navigator.pop(context);
          });
        });
      }
      _users.remove(uid);
    }));
  }


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

  void popUp() async {
    setState(() {
      heart = true;
    });
    Timer(
        Duration(seconds: 4),
        () => {
              _timer.cancel(),
              setState(() {
                heart = false;
              })
            });
    _timer = Timer.periodic(Duration(milliseconds: 125), (Timer t) {
      setState(() {
        height += _random.nextInt(20);
      });
    });
  }

  Widget heartPop() {
    final size = MediaQuery.of(context).size;
    final confetti = <Widget>[];
    for (var i = 0; i < _numConfetti; i++) {
      final height = _random.nextInt(size.height.floor());
      final width = 20;
      confetti.add(HeartAnim(height % 200.0, width.toDouble(), 1));
    }

    return Container(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: 400,
            width: 200,
            child: Stack(
              children: confetti,
            ),
          ),
        ),
      ),
    );
  }

  /// Info panel to show logs
  Widget _messageList() {
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
                                '${_infoStrings[index].user} joined',
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
    await Wakelock.disable();
    _leaveChannel();
    _logout();
    _rtcEngine.leaveChannel();
    _rtcEngine.destroy();
    return true;
    // return true if the route to be popped
  }

  Widget _ending() {
    return Container(
      color: Colors.black.withOpacity(.7),
      child: Center(
          child: Container(
        width: double.infinity,
        color: Colors.grey[700],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(
            'The Live has ended',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      )),
    );
  }

  Widget _liveText() {
    return Container(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
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
              Padding(
                padding: const EdgeInsets.only(left: 5),
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
      ),
    );
  }

  Widget _username() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: widget.hostImage,
              imageBuilder: (context, imageProvider) => Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
              child: Text(
                '${widget.channelName}',
                style: TextStyle(shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black,
                    offset: Offset(0, 1.3),
                  ),
                ], color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget requestedWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.center,
          spacing: 0,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(
                top: 20,
              ),
              width: 130,
              alignment: Alignment.center,
              child: Stack(
                children: <Widget>[
                  Container(
                    width: 130,
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      alignment: Alignment(0, 0),
                      children: <Widget>[
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        CachedNetworkImage(
                          imageUrl: widget.hostImage,
                          imageBuilder: (context, imageProvider) => Container(
                            width: 70.0,
                            height: 70.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 130,
                    alignment: Alignment.centerRight,
                    child: Stack(
                      alignment: Alignment(0, 0),
                      children: <Widget>[
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        CachedNetworkImage(
                          imageUrl: widget.userImage,
                          imageBuilder: (context, imageProvider) => Container(
                            width: 70.0,
                            height: 70.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '${widget.channelName} Wants You To Be In This Live Video.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                top: 0,
                bottom: 20,
                right: 20,
              ),
              child: Text(
                'Anyone can watch, and some of your followers may get notified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              width: double.maxFinite,
              child: RaisedButton(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Go Live with ${widget.channelName}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                elevation: 2.0,
                color: Colors.blue[400],
                onPressed: () async {
                  await _rtcEngine.enableLocalVideo(true);
                  await _rtcEngine.enableLocalAudio(true);
                  await _rtmChannel.sendMessage(AgoraRtmMessage.fromText('k1r2i3s4t5i6e7 confirming'));
                  setState(() {
                    accepted = true;
                    requested = false;
                  });
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              width: double.maxFinite,
              child: RaisedButton(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Decline',
                    style: TextStyle(color: Colors.pink[300]),
                  ),
                ),
                elevation: 2.0,
                color: Colors.transparent,
                onPressed: () async {
                  await _rtmChannel.sendMessage(AgoraRtmMessage.fromText('R1e2j3e4c5t6i7o8n9e0d Rejected'));
                  setState(() {
                    requested = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void stopFunction() async {
    await _rtcEngine.enableLocalVideo(!muted);
    await _rtcEngine.enableLocalAudio(!muted);
    setState(() {
      accepted = false;
    });
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
            await _rtmChannel.sendMessage(AgoraRtmMessage.fromText('E1m2I3l4i5E6 stoping'));
            stopFunction();
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: SafeArea(
          child: Scaffold(
            body: Container(
              color: Colors.black,
              child: Center(
                child: (completed == true)
                    ? _ending()
                    : Stack(
                        children: <Widget>[
                          _viewRows(),
                          if (completed == false) _bottomBar(),
                          _username(),
                          _liveText(),
                          if (completed == false) _messageList(),
                          if (heart == true && completed == false) heartPop(),
                          if (requested == true) requestedWidget(),
                          if (accepted == true) stopSharing(),
                          //_ending()
                        ],
                      ),
              ),
            ),
          ),
        ),
        onWillPop: _willPopCallback);
  }

  // Agora RTM

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
              child: new TextField(
                  cursorColor: Colors.blue,
                  textInputAction: TextInputAction.go,
                  onSubmitted: _sendMessage,
                  style: TextStyle(
                    color: Colors.white,
                  ),
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
              padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: MaterialButton(
                minWidth: 0,
                onPressed: () async {
                  popUp();
                  await _rtmChannel.sendMessage(AgoraRtmMessage.fromText('m1x2y3z4p5t6l7k8'));
                },
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 30.0,
                ),
                padding: const EdgeInsets.all(12.0),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _logout() async {
    try {
      await _rtmClient.logout();
      // _log('Logout success.');
    } catch (errorCode) {
      //_log('Logout error: ' + errorCode.toString());
    }
  }

  void _leaveChannel() async {
    try {
      await _rtmChannel.leave();
      //_log('Leave channel success.');
      _rtmClient.releaseChannel(_rtmChannel.channelId);
      _channelMessageController.text = null;
    } catch (errorCode) {
      //_log('Leave channel error: ' + errorCode.toString());
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
      _log(user: widget.username, info: text, type: 'message');
    } catch (errorCode) {
      _log(info: 'Send channel message error: ' + errorCode.toString(), type: 'sys');
    }
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

  void _createRtmClient(String rtmToken) async {
    _rtmClient = await AgoraRtmClient.createInstance(APP_ID);
    _rtmClient.onMessageReceived = (AgoraRtmMessage message, String peerId) async {
      var img = await FireStoreClass.getImage(username: peerId);
      userMap.putIfAbsent(peerId, () => img);
      _log(user: peerId, info: message.text, type: 'message');
    };
    _rtmClient.onConnectionStateChanged = (int state, int reason) {
      _log(type: 'sys', user: widget.channelName, info: '$state $reason');
      if (state == 5) {
        _rtmClient.logout();
        _log(type: 'sys', user: widget.username, info: 'Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };
    try {
      _rtmChannel = await _createChannel(widget.channelName);
      await _rtmClient.login(rtmToken, widget.username);
      await _rtmChannel.join();
    } catch (e) {
      print('-----$e-----');
    }
    var len;
    _rtmChannel.getMembers().then((value) {
      len = value.length;
      setState(() {
        viewersNumber = len;
      });
    });
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _rtmClient.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) async {
      var img = await FireStoreClass.getImage(username: member.userId);
      userMap.putIfAbsent(member.userId, () => img);

      _rtmChannel.getMembers().then((value) {
        len = value.length;
        setState(() {
          viewersNumber = len;
        });
      });

      _log(info: 'Member joined: ', user: member.userId, type: 'join');
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      var len;
      _rtmChannel.getMembers().then((value) {
        len = value.length;
        setState(() {
          viewersNumber = len;
        });
      });
    };
    channel.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) async {
      var img = await FireStoreClass.getImage(username: member.userId);
      userMap.putIfAbsent(member.userId, () => img);
      _log(user: member.userId, info: message.text, type: 'message');
    };
    return channel;
  }

  void _log({String info, String type, String user}) {
    if (type == 'message' && info.contains('m1x2y3z4p5t6l7k8')) {
      popUp();
    } else if (type == 'message' && info.contains('E1m2I3l4i5E6')) {
      stopFunction();
    } else {
      Message m;
      var image = userMap[user];
      if (info.contains('d1a2v3i4s5h6')) {
        var mess = info.split(' ');
        if (mess[1] == widget.username) {
          /*m = new Message(
              message: 'working', type: type, user: user, image: image);*/
          setState(() {
            //_infoStrings.insert(0, m);
            requested = true;
          });
        }
      } else {
        m = Message(
            message: info,
            type: type,
            user: user,
            image: type == 'sys' ? 'https://icons-for-free.com/iconfiles/png/512/Robot-1320568045013231116.png' : image);
        setState(() {
          _infoStrings.insert(0, m);
        });
      }
    }
  }

  @override
  void dispose() {
    _users.clear();
    _rtcEngine.leaveChannel();
    _rtcEngine.destroy();
    super.dispose();
  }
}
