import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mychat/chatpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginpage.dart';

class UserListPage extends StatefulWidget {
  final String currentUserId;
  const UserListPage({super.key, required this.currentUserId});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  StreamSubscription? _sessionSub;

  @override
  void initState() {
    super.initState();
    listenForSessionChange();
  }

  void listenForSessionChange() async {
    final prefs = await SharedPreferences.getInstance();
    final localDeviceId = prefs.getString("deviceId");

    _sessionSub = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;

      if (doc["activeDeviceId"] != localDeviceId) {
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      }
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserId)
        .update({"activeDeviceId": null});

    await prefs.clear();

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs
              .where((u) => u.id != widget.currentUserId)
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) {
              var user = users[index];
              return Container(
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 135, 54, 202),
                    border: Border.all(
                      width: 1,
                      color: Color(0xFF8313DF),
                    ),
                    borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(user['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          currentUserId: widget.currentUserId,
                          selectedUserId: user.id,
                          selectedUserName: user['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
