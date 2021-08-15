import 'dart:convert';

import 'package:http/http.dart' as http;

class Api {
  static Future<Map<String, dynamic>> getTokens({String channelName, String userId}) async {
    try {
      final url = 'https://us-central1-agora-with-flutter-live-video.cloudfunctions.net/getAgoraTokens?channelName=$channelName&userId=$userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final rtcToken = jsonResponse['rtcToken'];
      final rtmToken = jsonResponse['rtmToken'];
      return {'rtcToken': rtcToken, 'rtmToken': rtmToken};
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<String> createAcquire({String channelName, String userId}) async {
    try {
      final acquireUrl = 'https://us-central1-agora-with-flutter-live-video.cloudfunctions.net/createAcquire?channelName=$channelName&userId=$userId';
      final acquireResponse = await http.get(Uri.parse(acquireUrl));
      if (acquireResponse.statusCode != 200) {
        print(acquireResponse.body);
        return null;
      }
      final String resourceId = jsonDecode(acquireResponse.body)['resourceId'];
      return resourceId;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<String> startRecording({String channelName, String userId, String rtcToken, String resourceId}) async {
    try {
      final startRecordingUrl =
          'https://us-central1-agora-with-flutter-live-video.cloudfunctions.net/startRecording?channelName=$channelName&userId=$userId&rtcToken=$rtcToken&resourceId=$resourceId';
      final startRecordingResponse = await http.get(Uri.parse(startRecordingUrl));
      if (startRecordingResponse.statusCode != 200) {
        print(startRecordingResponse.body);
        return null;
      }
      final String sid = jsonDecode(startRecordingResponse.body)['sid'];
      return sid;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<String> stopRecording({String channelName, String userId, String resourceId, String sid}) async {
    try {
      final url =
          'https://us-central1-agora-with-flutter-live-video.cloudfunctions.net/stopRecording?channelName=$channelName&userId=$userId&sid=$resourceId&resourceId=$sid';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        print(response.body);
        return null;
      }
      return response.body;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
