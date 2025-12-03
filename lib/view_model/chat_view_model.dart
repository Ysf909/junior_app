// lib/view_model/chat_view_model.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final ImagePicker picker;

  final String userId;
  final String roomId;

  ChatViewModel({
    required this.userId,
    required this.roomId,
    FirebaseFirestore? firestoreInstance,
    FirebaseStorage? storageInstance,
    ImagePicker? imagePicker,
  })  : firestore = firestoreInstance ?? FirebaseFirestore.instance,
        storage = storageInstance ?? FirebaseStorage.instance,
        picker = imagePicker ?? ImagePicker();

  // other user info
  String displayOtherUserId = "";
  String displayOtherUsername = "User";
  String displayOtherAvatar = "";

  // selection
  bool selectionMode = false;
  final Set<String> selectedMessageIds = {};

  // presence
  Timer? presenceTimer;

  // typing
  Timer? _typingTimer;
  bool _isTyping = false;

  // search
  bool searching = false;
  String searchQuery = "";

  // === INIT / DISPOSE ===

  Future<void> init() async {
    await _setupRoom();
    await _setPresence(true);

    // keep presence updated
    presenceTimer?.cancel();
    presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setPresence(true);
    });
  }

  @override
  void dispose() {
    _setPresence(false);
    presenceTimer?.cancel();
    _typingTimer?.cancel();
    _setTyping(false);
    super.dispose();
  }

  // === FIRESTORE STREAMS (for the View to consume) ===

  Stream<QuerySnapshot<Map<String, dynamic>>> get messagesStream =>
      firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('time')
          .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> get roomDocStream =>
      firestore.collection('rooms').doc(roomId).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>>? get otherStatusStream {
    if (displayOtherUserId.isEmpty) return null;
    return firestore
        .collection('rooms')
        .doc(roomId)
        .collection('membersStatus')
        .doc(displayOtherUserId)
        .snapshots();
  }

  // === ROOM SETUP & OTHER USER ===

  Future<void> _setupRoom() async {
    final roomRef = firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    List members = [];
    if (!roomDoc.exists) {
      await roomRef.set({'members': [userId]});
      members = [userId];
    } else {
      members = List.from(roomDoc.data()?['members'] ?? []);
      if (!members.contains(userId)) {
        members.add(userId);
        await roomRef.update({'members': members});
      }
    }

    // other user in the room
    String other = "";
    if (members.length > 1) {
      for (var m in members) {
        if (m != userId) {
          other = m;
          break;
        }
      }
    }

    displayOtherUserId = other;
    notifyListeners();

    // fetch username and avatar
    if (displayOtherUserId.isNotEmpty) {
      final userDoc =
          await firestore.collection('users').doc(displayOtherUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        displayOtherUsername = data['username'] ?? 'User';
        displayOtherAvatar = data['avatarUrl'] ?? '';
        notifyListeners();
      }
    }

    // ensure presence doc exists
    await firestore
        .collection('rooms')
        .doc(roomId)
        .collection('membersStatus')
        .doc(userId)
        .set(
      {
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // === PRESENCE ===

  Future<void> _setPresence(bool online) async {
    try {
      await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('membersStatus')
          .doc(userId)
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

  // === TYPING ===

  Future<void> _setTyping(bool typing) async {
    if (_isTyping == typing) return;
    _isTyping = typing;
    try {
      await firestore.collection('rooms').doc(roomId).set(
        {
          'typing': {userId: typing}
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error setting typing: $e');
    }
  }

  void onTextChanged(String text) {
    _setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _setTyping(false);
    });
  }

  // === MESSAGES ===

  Future<void> sendMessage(String text, {String? imageUrl}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl == null) return;

    try {
      await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .add({
        'sender': userId,
        'message': trimmed,
        'imageUrl': imageUrl,
        'time': FieldValue.serverTimestamp(),
        'seen': false,
      });

      await _setPresence(true);

      _typingTimer?.cancel();
      _setTyping(false);
    } catch (e) {
      debugPrint("Error sendMessage: $e");
      rethrow;
    }
  }

  Future<void> pickAndSendImage(BuildContext context) async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = storage.ref().child('chat_images/$fileName');

      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        await ref.putData(bytes);
      } else {
        File file = File(pickedFile.path);
        await ref.putFile(file);
      }

      String imageUrl = await ref.getDownloadURL();
      await sendMessage('', imageUrl: imageUrl);
    } catch (e) {
      debugPrint("Error sending image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending image: $e")),
      );
    }
  }

  Future<void> markMessagesAsSeen() async {
    try {
      final query = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .where('seen', isEqualTo: false)
          .get();

      if (query.docs.isEmpty) return;

      WriteBatch batch = firestore.batch();
      for (var doc in query.docs) {
        if (doc['sender'] != userId) {
          batch.update(doc.reference, {'seen': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error markMessagesAsSeen: $e');
    }
  }

  Future<void> deleteSelectedMessages(BuildContext context) async {
    if (selectedMessageIds.isEmpty) return;

    try {
      WriteBatch batch = firestore.batch();
      for (var id in selectedMessageIds) {
        final ref = firestore
            .collection('rooms')
            .doc(roomId)
            .collection('messages')
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();

      selectedMessageIds.clear();
      selectionMode = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting selected messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting messages: $e")),
      );
    }
  }

  Future<void> deleteAllMessages(BuildContext context) async {
    try {
      final query = await firestore
          .collection('rooms')
          .doc(roomId)
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

  // === SELECTION & SEARCH ===

  void toggleSelection(String messageId) {
    if (selectedMessageIds.contains(messageId)) {
      selectedMessageIds.remove(messageId);
    } else {
      selectedMessageIds.add(messageId);
    }
    selectionMode = selectedMessageIds.isNotEmpty;
    notifyListeners();
  }

  void clearSelection() {
    selectedMessageIds.clear();
    selectionMode = false;
    notifyListeners();
  }

  void setSearching(bool value) {
    searching = value;
    if (!value) {
      searchQuery = "";
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query.trim();
    notifyListeners();
  }

  // === HELPERS ===

  String formatLastSeen(Timestamp? ts) {
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
}
