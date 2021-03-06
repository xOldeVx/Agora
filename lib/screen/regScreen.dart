import 'dart:io';

import 'package:Goomtok/firebaseDB/auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegScreen extends StatefulWidget {
  @override
  _RegScreenState createState() => _RegScreenState();
}

class _RegScreenState extends State<RegScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();
  bool passwordVisible = false;
  PickedFile _image;
  File selectedImage;
  bool submitted = false;
  bool boolEmail = false, boolPass = false, boolName = false, boolUser = false, invalidError = false, passwordError = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height - 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => chooseFile(),
                      child: Container(
                        height: 150,
                        width: 150,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: _image == null ? AssetImage('assets/images/dummy.png') : FileImage(selectedImage),
                        ),
                      ),
                    ),
                    SizedBox(height: 13),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              fillColor: Colors.grey[700],
                              filled: true,
                              hintText: 'Email Address',
                              hintStyle: TextStyle(color: Colors.white, fontSize: 13),
                              errorText: invalidError ? 'Please enter a valid email' : null,
                              errorStyle: TextStyle(color: Colors.red, fontSize: 10),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(5)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(5)),
                              focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(5)),
                              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
                          child: TextField(
                            controller: _passController,
                            obscureText: !passwordVisible,
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              fillColor: Colors.grey[700],
                              filled: true,
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.white, fontSize: 13),
                              errorText: passwordError ? 'Week Password! Min 6 characters' : null,
                              errorStyle: TextStyle(color: Colors.red, fontSize: 10),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(4)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(4)),
                              focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(5)),
                              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(5)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: passwordVisible ? Colors.blue : Colors.grey,
                                ),
                                onPressed: () => setState(() => passwordVisible = !passwordVisible),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
                          child: TextField(
                            controller: _nameController,
                            cursorColor: Colors.white,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              fillColor: Colors.grey[700],
                              filled: true,
                              hintText: 'Full Name',
                              hintStyle: TextStyle(color: Colors.white, fontSize: 13),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(5)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
                          child: TextField(
                            controller: _usernameController,
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              fillColor: Colors.grey[700],
                              filled: true,
                              hintText: 'Username',
                              hintStyle: TextStyle(color: Colors.white, fontSize: 13),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(5)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                          child: FlatButton(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                            onPressed: (boolPass != false && boolEmail != false && boolName != false && boolUser != false) ? _submit : null,
                            color: Colors.blue,
                            disabledColor: Colors.blue[800],
                            disabledTextColor: Colors.white60,
                            textColor: Colors.white,
                            padding: EdgeInsets.all(15.0),
                            child: submitted
                                ? SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('Sign Up', style: TextStyle(fontSize: 13.0)),
                          ),
                        ),
                        SizedBox(height: 20.0),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Divider(color: Colors.white, height: 0),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Already have an account? ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('Log in.', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void usernameError() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey[800],
              ),
              height: 190,
              child: Column(
                children: [
                  Container(
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Text(
                            'Username Not Available',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 25, top: 15),
                          child: Text(
                            "The username you entered is not available.",
                            style: TextStyle(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 0,
                    height: 0,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Try Again',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  void imageDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey[800],
              ),
              height: 190,
              child: Column(
                children: [
                  Container(
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Text(
                            'Select Image',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 25, top: 15),
                          child: Text(
                            "Image is not selected for avatar.",
                            style: TextStyle(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 0,
                    height: 0,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Try Again',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  void emailExists() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey[800],
              ),
              height: 190,
              child: Column(
                children: [
                  Container(
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Text(
                            'This Email is on Another Account',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 25, top: 15),
                          child: Text(
                            "You can log into the account associated with that email.",
                            style: TextStyle(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 0,
                    height: 0,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FlatButton(
                      onPressed: () {
                        Navigator.popUntil(context, ModalRoute.withName('/HomeScreen'));
                      },
                      child: Text(
                        'Log in to Existing Account',
                        style: TextStyle(color: Colors.lightBlue[400]),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(setEmail);
    _passController.addListener(setPass);
    _nameController.addListener(setName);
    _usernameController.addListener(setUser);
  }

  void setEmail() {
    if (_emailController.text.toString().trim() == '') {
      setState(() {
        boolEmail = false;
      });
    } else
      setState(() {
        boolEmail = true;
      });
  }

  void setPass() {
    if (_passController.text.toString().trim().isEmpty) {
      setState(() => boolPass = false);
    } else {
      setState(() => boolPass = true);
    }
  }

  void setName() {
    if (_nameController.text.toString().trim().isEmpty) {
      setState(() => boolName = false);
    } else {
      setState(() => boolName = true);
    }
  }

  void setUser() {
    if (_usernameController.text.toString().trim().isEmpty) {
      setState(() => boolUser = false);
    } else {
      setState(() => boolUser = true);
    }
  }

  Future chooseFile() async {
    PickedFile pickedImage = await imagePicker.getImage(source: ImageSource.gallery);
    if (pickedImage == null) return;
    _image = pickedImage;
    setState(() => selectedImage = File(pickedImage.path));
  }

  void _submit() async {
    if (_image == null) {
      imageDialog();
      return;
    }

    setState(() => submitted = true);
    passwordError = false;
    invalidError = false;
    //existsError=false;
    final pass = _passController.text.toString().trim();
    final email = _emailController.text.toString().trim();
    final name = _nameController.text.toString().trim();
    final username = _usernameController.text.toString().trim();

    final result = await registerUser(email: email, name: name, username: username, pass: pass, image: _image);
    switch (result) {
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/HomeScreen', (Route<dynamic> route) => false);
        break;
      case -1:
        usernameError();
        setState(() => submitted = false);
        break;
      case -2:
        setState(() {
          invalidError = true;
          submitted = false;
        });
        break;
      case -3:
        setState(() {
          emailExists();
          submitted = false;
        });
        break;
      case -4:
        setState(() {
          passwordError = true;
          submitted = false;
        });
        break;
    }
  }
}
