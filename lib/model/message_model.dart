class MessageModel {
  final String sender;
  final String text;
  final int timestamp;

  MessageModel({required this.sender, required this.text, required this.timestamp});

  factory MessageModel.fromMap(Map<dynamic, dynamic> map) {
    return MessageModel(
      sender: map['sender'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
