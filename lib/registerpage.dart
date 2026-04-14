import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final keyController = TextEditingController();

  void registerUser() async {
    String name = nameController.text.trim();
    String key = keyController.text.trim();

    if (name.isEmpty || key.length != 11 || !key.startsWith("0")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid input")),
      );
      return;
    }

    var query = await FirebaseFirestore.instance
        .collection("users")
        .where("uniqueKey", isEqualTo: key)
        .get();

    if (query.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Key already exists")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("users").add({
      "name": name,
      "uniqueKey": key,
      "createdAt": DateTime.now(),
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Registration successful")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: keyController,
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: "11-digit Key",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: registerUser,
                child: Text("Create Account"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
