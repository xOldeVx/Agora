import 'dart:async';

import 'package:Goomtok/utils/sp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firestoreDB.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<String> signInWithGoogle() async {
  final googleSignInAccount = await googleSignIn.signIn();
  final googleSignInAuthentication = await googleSignInAccount.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final authResult = await _auth.signInWithCredential(credential);
  final user = authResult.user;
  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);
  final currentUser = _auth.currentUser;
  assert(user.uid == currentUser.uid);

  return 'signInWithGoogle succeeded: $user';
}

void signOutGoogle() async {
  await googleSignIn.signOut();
  print('User Sign Out');
}

Future<int> registerUser({email, name, pass, username, image}) async {
  var _auth = FirebaseAuth.instance;
  try {
    var userNameExists = await FireStoreClass.checkUsername(username: username);
    if (!userNameExists) return -1;

    final result = await _auth.createUserWithEmailAndPassword(email: email, password: pass);
    final user = result.user;
    await user.updateDisplayName(name);
    await user.updatePhotoURL('/');
    await user.updateEmail(email);
    await user.updatePassword(pass);
    await FireStoreClass.regUser(name: name, email: email, username: username, image: image);
    return 1;
  } catch (e) {
    switch (e.code) {
      case 'invalid-email':
        return -2;
        break;
      case 'email-already-in-use':
        return -3;
        break;
      case 'weak-password':
        return -4;
        break;
    }
    return 0;
  }
}

Future<void> logout(context) async {
  Sp.sharedPref.clear();
  FirebaseAuth.instance.signOut();
  Navigator.pushNamedAndRemoveUntil(context, '/HomeScreen', (Route<dynamic> route) => false);
}

Future<int> loginFirebase(String mail, String pass) async {
  final _auth = FirebaseAuth.instance;
  try {
    final result = await _auth.signInWithEmailAndPassword(email: mail, password: pass);
    if (result.user == null) return null;
    await FireStoreClass.initUserDetails(email: mail);
    return 1;
  } catch (e) {
    switch (e.code) {
      case 'wrong-password':
        return -1;
      case 'invalid-email':
        return -2;
      case 'user-not-found':
        return -3;
    }
    return null;
  }
}
