class ConversationModel {
  final String id;
  final String userId; 
  final String adminId; 
  final String userName;
  final String adminName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.adminId,
    required this.userName,
    required this.adminName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) {
    return ConversationModel(
      id: id,
      userId: map['user_id'] ?? '',
      adminId: map['admin_id'] ?? '',
      userName: map['user_name'] ?? '',
      adminName: map['admin_name'] ?? '',
      lastMessage: map['last_message'] ?? '',
      lastMessageTime: (map['last_message_time'] as dynamic)?.toDate() ?? DateTime.now(),
      unreadCount: map['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'admin_id': adminId,
      'user_name': userName,
      'admin_name': adminName,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
    };
  }
}