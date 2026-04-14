import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mychat/registerpage.dart';
import 'package:mychat/userListPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController keyController = TextEditingController();
  String? errorText;

  void login() async {
    String key = keyController.text.trim();

    var query = await FirebaseFirestore.instance
        .collection("users")
        .where("uniqueKey", isEqualTo: key)
        .get();

    if (query.docs.isNotEmpty) {
      String userId = query.docs.first.id;

      final prefs = await SharedPreferences.getInstance();

      // 🔐 device id
      String? deviceId = prefs.getString("deviceId");
      deviceId ??= DeviceHelper.generateDeviceId();
      await prefs.setString("deviceId", deviceId);

      // 🔐 save active device
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "activeDeviceId": deviceId,
      });

      await prefs.setString('userId', userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserListPage(currentUserId: userId),
        ),
      );
    } else {
      setState(() => errorText = "Invalid Key");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 6,
          margin: EdgeInsets.all(20),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("MyChat",
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextField(
                  controller: keyController,
                  maxLength: 11,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Key",
                    errorText: errorText,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(onPressed: login, child: Text("Login")),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPage()),
                    );
                  },
                  child: Text("Create New Account"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
