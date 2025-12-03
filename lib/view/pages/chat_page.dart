// lib/chat_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String roomId;

  const ChatPage({
    super.key,
    required this.userId,
    required this.roomId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController msgController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  String displayOtherUserId = "";
  String displayOtherUsername = "User";
  String displayOtherAvatar = "";
  bool selectionMode = false;
  final Set<String> selectedMessageIds = {};
  Timer? presenceTimer;

  // typing
  Timer? _typingTimer;
  bool _isTyping = false;

  // search
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  bool _invalidIds = false;

  @override
  void initState() {
    super.initState();

    print("🔥 ChatPage started");
    print("🔥 userId = '${widget.userId}'");
    print("🔥 roomId = '${widget.roomId}'");

    // basic validation to avoid .doc('') errors
    if (widget.userId.trim().isEmpty || widget.roomId.trim().isEmpty) {
      _invalidIds = true;
      return;
    }

    setupRoom();
    _setPresence(true);

    // update presence every 30 seconds
    presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setPresence(true);
    });

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  Future<void> setupRoom() async {
    final roomRef = firestore.collection('rooms').doc(widget.roomId);
    final roomDoc = await roomRef.get();

    List members = [];
    if (!roomDoc.exists) {
      await roomRef.set({'members': [widget.userId]});
      members = [widget.userId];
    } else {
      members = List.from(roomDoc.get('members') ?? []);
      if (!members.contains(widget.userId)) {
        members.add(widget.userId);
        await roomRef.update({'members': members});
      }
    }

    // get other user in room (first user != me)
    String other = "";
    if (members.length > 1) {
      for (var m in members) {
        if (m != widget.userId) {
          other = m;
          break;
        }
      }
    }

    setState(() => displayOtherUserId = other);

    // fetch username and avatar from users collection
    if (displayOtherUserId.isNotEmpty) {
      final userDoc =
          await firestore.collection('users').doc(displayOtherUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          displayOtherUsername = data['username'] ?? 'User';
          displayOtherAvatar = data['avatarUrl'] ?? '';
        });
      }
    }

    // ensure presence doc exists for me
    await firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('membersStatus')
        .doc(widget.userId)
        .set(
      {
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _setPresence(bool online) async {
    if (_invalidIds) return;
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('membersStatus')
          .doc(widget.userId)
          .set(
        {
          'online': online,
          'lastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error setting presence: $e');
    }
  }

  // typing indicator: set map entry under rooms/{roomId}.typing.{userId}
  Future<void> _setTyping(bool typing) async {
    if (_invalidIds) return;
    if (_isTyping == typing) return;
    _isTyping = typing;
    try {
      await firestore.collection('rooms').doc(widget.roomId).set(
        {
          'typing': {widget.userId: typing}
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error setting typing: $e');
    }
  }

  void _onTextChanged(String text) {
    // when user types: set typing true and debounce to false
    _setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _setTyping(false);
    });
  }

  Future<void> sendMessage({String? imageUrl}) async {
    if (_invalidIds) return;

    final text = msgController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'sender': widget.userId,
        'message': text,
        'imageUrl': imageUrl,
        'time': FieldValue.serverTimestamp(),
        'seen': false,
      });

      // keep presence online
      await _setPresence(true);

      // stop typing when message sent
      _typingTimer?.cancel();
      _setTyping(false);

      if (text.isNotEmpty) msgController.clear();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      debugPrint("Error sendMessage: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending message: $e")),
      );
    }
  }

  Future<void> pickAndSendImage() async {
    if (_invalidIds) return;

    try {
      final pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/$fileName');

      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        await ref.putData(bytes);
      } else {
        File file = File(pickedFile.path);
        await ref.putFile(file);
      }

      String imageUrl = await ref.getDownloadURL();
      await sendMessage(imageUrl: imageUrl);
    } catch (e) {
      debugPrint("Error sending image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending image: $e")),
      );
    }
  }

  Future<void> markMessagesAsSeen() async {
    if (_invalidIds) return;
    try {
      final query = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .where('seen', isEqualTo: false)
          .get();

      if (query.docs.isEmpty) return;

      WriteBatch batch = firestore.batch();
      for (var doc in query.docs) {
        if (doc['sender'] != widget.userId) {
          batch.update(doc.reference, {'seen': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error markMessagesAsSeen: $e');
    }
  }

  Future<void> deleteSelectedMessages() async {
    if (_invalidIds) return;
    if (selectedMessageIds.isEmpty) return;

    try {
      WriteBatch batch = firestore.batch();
      for (var id in selectedMessageIds) {
        final ref = firestore
            .collection('rooms')
            .doc(widget.roomId)
            .collection('messages')
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();

      setState(() {
        selectedMessageIds.clear();
        selectionMode = false;
      });
    } catch (e) {
      debugPrint('Error deleting selected messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting messages: $e")),
      );
    }
  }

  Future<void> deleteAllMessages() async {
    if (_invalidIds) return;

    try {
      final query = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .get();
      if (query.docs.isEmpty) return;

      WriteBatch batch = firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting all messages: $e")),
      );
    }
  }

  String _formatLastSeen(Timestamp? ts) {
    if (ts == null) return 'Last seen: unknown';
    final dt = ts.toDate().toLocal();
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Last seen: just now';
    if (diff.inMinutes < 60) return 'Last seen: ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen: ${diff.inHours}h ago';
    return 'Last seen: ${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    if (!_invalidIds) {
      _setPresence(false);
      _typingTimer?.cancel();
      _setTyping(false);
    }
    presenceTimer?.cancel();
    _searchController.dispose();
    msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (selectedMessageIds.contains(messageId)) {
        selectedMessageIds.remove(messageId);
      } else {
        selectedMessageIds.add(messageId);
      }
      selectionMode = selectedMessageIds.isNotEmpty;
    });
  }

  // Helper to render text with highlighted query
  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lcText = text.toLowerCase();
    final lcQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lcText.indexOf(lcQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style:
              const TextStyle(backgroundColor: Colors.yellow),
        ),
      );
      start = idx + query.length;
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 15),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if ids invalid, show friendly error instead of crashing
    if (_invalidIds) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Text(
            'Error: userId or roomId is empty.\n'
            'Check how you open ChatPage.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    final messagesStream = firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('time')
        .snapshots();
    final roomDocStream =
        firestore.collection('rooms').doc(widget.roomId).snapshots();

    Stream<DocumentSnapshot>? otherStatusStream;
    if (displayOtherUserId.isNotEmpty) {
      otherStatusStream = firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('membersStatus')
          .doc(displayOtherUserId)
          .snapshots();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              )
            : selectionMode
                ? Text('${selectedMessageIds.length} selected')
                : displayOtherUserId.isEmpty
                    ? const Text('Chat')
                    : StreamBuilder<DocumentSnapshot>(
                        stream: otherStatusStream,
                        builder: (context, snap) {
                          return Column(
                            children: [
                              Text(
                                displayOtherUsername,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // online / last seen
                                  Builder(builder: (context) {
                                    if (!snap.hasData ||
                                        !snap.data!.exists) {
                                      return const Text(
                                        'Loading...',
                                        style: TextStyle(fontSize: 12),
                                      );
                                    }
                                    final data = snap.data!.data()
                                            as Map<String, dynamic>? ??
                                        {};
                                    final online =
                                        data['online'] ?? false;
                                    final lastSeen =
                                        data['lastSeen'] as Timestamp?;
                                    return Text(
                                      online
                                          ? 'Online'
                                          : _formatLastSeen(lastSeen),
                                      style:
                                          const TextStyle(fontSize: 12),
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  // typing indicator from room doc
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: roomDocStream,
                                    builder: (context, roomSnap) {
                                      if (!roomSnap.hasData ||
                                          !roomSnap.data!.exists) {
                                        return const SizedBox.shrink();
                                      }
                                      final roomData = roomSnap.data!
                                              .data()
                                          as Map<String, dynamic>? ??
                                          {};
                                      final typing =
                                          (roomData['typing'] ?? {})
                                              as Map<String, dynamic>? ??
                                              {};
                                      final otherTyping =
                                          typing[displayOtherUserId] ??
                                              false;
                                      if (otherTyping == true) {
                                        return const Text(
                                          'typing...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle:
                                                FontStyle.italic,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
        actions: [
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _searching = true;
                  _searchQuery = "";
                  _searchController.clear();
                });
              },
            ),
          if (_searching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searching = false;
                  _searchQuery = "";
                  _searchController.clear();
                });
              },
            ),
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete selected messages?'),
                    content: const Text(
                        'This will permanently delete the selected messages.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) deleteSelectedMessages();
              },
            ),
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete all messages',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete all messages?'),
                    content: const Text(
                        'This will permanently delete all messages in this room.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) deleteAllMessages();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allMessages = snapshot.data!.docs;

                // mark incoming messages as seen
                markMessagesAsSeen();

                // filter locally using search query
                final visibleMessages = _searchQuery.isEmpty
                    ? allMessages
                    : allMessages.where((m) {
                        final text = (m.data()
                                as Map<String, dynamic>)['message'] ??
                            '';
                        return text
                            .toString()
                            .toLowerCase()
                            .contains(
                                _searchQuery.toLowerCase());
                      }).toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    final msgDoc = visibleMessages[index];
                    final data = msgDoc.data()
                        as Map<String, dynamic>;
                    final isMe =
                        data['sender'] == widget.userId;
                    final imageUrl = data['imageUrl'];
                    final seen = data['seen'] ?? false;
                    final messageId = msgDoc.id;
                    final messageText =
                        (data['message'] ?? '').toString();

                    return GestureDetector(
                      onLongPress: () => _toggleSelection(messageId),
                      onTap: () {
                        if (selectionMode) {
                          _toggleSelection(messageId);
                        }
                      },
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                    displayOtherAvatar
                                            .isNotEmpty
                                        ? NetworkImage(
                                            displayOtherAvatar)
                                        : const AssetImage(
                                                'assets/avatar.jpg')
                                            as ImageProvider,
                              ),
                            if (!isMe)
                              const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(
                                        vertical: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      selectedMessageIds
                                              .contains(
                                                  messageId)
                                          ? Colors.blue
                                              .withOpacity(
                                                  0.15)
                                          : (isMe
                                              ? Colors
                                                  .teal[100]
                                              : Colors
                                                  .white),
                                  borderRadius:
                                      BorderRadius.only(
                                    topLeft:
                                        const Radius.circular(
                                            12),
                                    topRight:
                                        const Radius.circular(
                                            12),
                                    bottomLeft:
                                        Radius.circular(
                                            isMe ? 12 : 0),
                                    bottomRight:
                                        Radius.circular(
                                            isMe ? 0 : 12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey
                                          .withOpacity(0.3),
                                      blurRadius: 4,
                                      offset:
                                          const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['sender'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            Colors.grey[700],
                                      ),
                                    ),
                                    if (imageUrl != null &&
                                        imageUrl.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                                top: 6),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      10),
                                          child:
                                              Image.network(
                                            imageUrl,
                                            width: 220,
                                            fit:
                                                BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    if (messageText.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                                top: 5),
                                        child: _highlightText(
                                          messageText,
                                          _searchQuery,
                                        ),
                                      ),
                                    if (isMe)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                                top: 6),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            Icon(
                                              seen
                                                  ? Icons
                                                      .done_all
                                                  : Icons
                                                      .check,
                                              size: 16,
                                              color: seen
                                                  ? Colors
                                                      .blue
                                                  : Colors
                                                      .grey,
                                            ),
                                            const SizedBox(
                                                width: 6),
                                            Text(
                                              seen
                                                  ? 'Seen'
                                                  : 'Sent',
                                              style:
                                                  const TextStyle(
                                                fontSize: 11,
                                                color: Colors
                                                    .grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe)
                              const SizedBox(width: 6),
                            if (isMe)
                              const CircleAvatar(
                                radius: 18,
                                backgroundImage: AssetImage(
                                    'assets/avatar.jpg'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image,
                        color: Colors.teal),
                    onPressed: pickAndSendImage,
                  ),
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius:
                            BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: msgController,
                        textInputAction:
                            TextInputAction.send,
                        onChanged: _onTextChanged,
                        onSubmitted: (_) =>
                            sendMessage(),
                        decoration:
                            const InputDecoration(
                          hintText:
                              "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.teal),
                    onPressed: () => sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
