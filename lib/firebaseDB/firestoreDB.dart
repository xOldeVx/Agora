import 'dart:convert';
import 'dart:io';

import 'package:Goomtok/models/user.dart';
import 'package:Goomtok/utils/sp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'package:shared_preferences/shared_preferences.dart';

class FireStoreClass {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final liveCollection = 'liveuser';
  static final userCollection = 'users';
  static final emailCollection = 'user_email';

  static void createLiveUser({name, id, time, image}) async {
    final snapShot = await _db.collection(liveCollection).doc(name).get();
    if (snapShot.exists) {
      await _db.collection(liveCollection).doc(name).update({'name': name, 'channel': id, 'time': time, 'image': image});
    } else {
      await _db.collection(liveCollection).doc(name).set({'name': name, 'channel': id, 'time': time, 'image': image});
    }
  }

  static Future<String> getImage({username}) async {
    final snapShot = await _db.collection(userCollection).doc(username).get();
    return snapShot.data()['image'];
  }

  static Future<String> getName({username}) async {
    final snapShot = await _db.collection(userCollection).doc(username).get();
    return snapShot.data()['name'];
  }

  static Future<bool> checkUsername({username}) async {
    final snapShot = await _db.collection(userCollection).doc(username).get();
    //print('Xperion ${snapShot.exists} $username');
    if (snapShot.exists) {
      return false;
    }
    return true;
  }

  static Future<void> regUser({name, email, username, image}) async {
    FirebaseStorage storageReference = FirebaseStorage.instance;
    File file = File(image.path);
    try {
      await storageReference.ref('$email/${Path.basename(image.path)}').putFile(file);
      // To fetch the uploaded data's url
      await storageReference.ref('$email/${Path.basename(image.path)}').getDownloadURL().then((imgUrl) async {
        User user = User(name:name, username:username, mail:email, image: imgUrl);
        await _db.collection(userCollection).doc(username).set(user.toJson());
        await _db.collection(emailCollection).doc(email).set(user.toJson());
        Sp.sharedPref.setString('user', jsonEncode(user.toJson()));
        return true;
      });
    } on FirebaseException catch (e) {
      print(e);
      // e.g, e.code == 'canceled'
    }
  }

  static void deleteUser({username}) async {
    await _db.collection(liveCollection).doc(username).delete();
  }

  static Future<void> initUserDetails({email}) async {
    final doc = await FirebaseFirestore.instance.doc('user_email/$email').get();
    if (!doc.exists) return;
    await Sp.sharedPref.setString('user', jsonEncode(doc.data()));
  }
}
