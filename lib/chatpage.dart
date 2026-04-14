import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mychat/encryption_helper.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String selectedUserId;
  final String selectedUserName;

  ChatPage({
    required this.currentUserId,
    required this.selectedUserId,
    required this.selectedUserName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String chatId;

  @override
  void initState() {
    super.initState();

    // create SAME chatId for both users
    chatId = widget.currentUserId.compareTo(widget.selectedUserId) < 0
        ? '${widget.currentUserId}_${widget.selectedUserId}'
        : '${widget.selectedUserId}_${widget.currentUserId}';
  }

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    final encryptedText = EncryptionHelper.encryptText(
      controller.text.trim(),
      chatId, // same key for both users
    );

    FirebaseFirestore.instance.collection("messages").add({
      "senderId": widget.currentUserId,
      "receiverId": widget.selectedUserId,
      "text": encryptedText,
      "timestamp": FieldValue.serverTimestamp(),
    });

    controller.clear();
    updateTyping(false);
    scrollToBottom();
  }

  void updateTyping(bool isTyping) {
    FirebaseFirestore.instance.collection("chats").doc(chatId).set({
      "typing": {
        widget.currentUserId: isTyping,
      }
    }, SetOptions(merge: true));
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.selectedUserName}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            const Color.fromARGB(255, 150, 65, 199), // New UI color
      ),
      body: Column(
        children: [
          /// Typing indicator
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("chats")
                .doc(chatId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return SizedBox();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final typing = data["typing"] ?? {};
              bool isOtherTyping = typing[widget.selectedUserId] ?? false;

              return isOtherTyping
                  ? Padding(
                      padding: EdgeInsets.all(6),
                      child: Text(
                        "Typing...",
                        style: TextStyle(
                            color: const Color.fromARGB(255, 241, 238, 241)),
                      ),
                    )
                  : SizedBox();
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .orderBy("timestamp")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var msgs = snapshot.data!.docs.where((msg) {
                  return (msg["senderId"] == widget.currentUserId &&
                          msg["receiverId"] == widget.selectedUserId) ||
                      (msg["senderId"] == widget.selectedUserId &&
                          msg["receiverId"] == widget.currentUserId);
                }).toList();
                scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(10),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    bool isMe = msgs[index]["senderId"] == widget.currentUserId;

                    String decryptedText = EncryptionHelper.decryptText(
                      msgs[index]["text"],
                      chatId,
                    );

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFF2E7D32) : Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 3)
                          ],
                        ),
                        child: Text(
                          decryptedText,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input Field
          Container(
            padding: EdgeInsets.all(8),
            color: const Color.fromARGB(255, 155, 113, 189),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (text) {
                      updateTyping(text.isNotEmpty);
                    },
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: const Color.fromARGB(255, 110, 46, 136),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 174, 87, 214),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    updateTyping(false);
    controller.dispose();
    super.dispose();
  }
}
