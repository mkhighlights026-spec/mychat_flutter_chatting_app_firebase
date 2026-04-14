import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mychat/loginpage.dart';
import 'package:mychat/userListPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  runApp(MyChatApp(initialUserId: userId));
}

class MyChatApp extends StatelessWidget {
  final String? initialUserId;
  const MyChatApp({super.key, this.initialUserId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color.fromARGB(255, 155, 113, 189),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 150, 65, 199),
          elevation: 1,
        ),
      ),
      home: initialUserId != null
          ? UserListPage(currentUserId: initialUserId!)
          : LoginPage(),
    );
  }
}
