import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_services.dart';
import '../models/user_model.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreServices _fs = FirestoreServices();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _auth.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SMColors.blue,
        title: const Text('Konsultasi', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: _currentUser!.role == 'admin'
          ? _buildAdminView()
          : _buildUserView(),
    );
  }

  Widget _buildUserView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showSelectAdminDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMColors.blue,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Mulai Konsultasi', style: TextStyle(color: Colors.white)),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _fs.streamUserConversations(_currentUser!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print('Error: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final conversations = snapshot.data ?? [];

              if (conversations.isEmpty) {
                return const Center(
                  child: Text('Belum ada konsultasi. Mulai dengan tombol di atas!'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: conversations.length,
                itemBuilder: (context, i) {
                  final conv = conversations[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: SMColors.blue,
                        child: Text(
                          conv.adminName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(conv.adminName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        conv.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(conv.lastMessageTime),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(conversation: conv),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminView() {
    return StreamBuilder(
      stream: _fs.streamAdminConversations(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return const Center(
            child: Text('Tidak ada konsultasi masuk'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: conversations.length,
          itemBuilder: (context, i) {
            final conv = conversations[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: SMColors.lightBlue,
                  child: Text(
                    conv.userName[0].toUpperCase(),
                    style: const TextStyle(color: SMColors.blue),
                  ),
                ),
                title: Text(conv.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  conv.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (conv.unreadCount > 0)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Text(
                          conv.unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      )
                    else
                      Text(
                        _formatTime(conv.lastMessageTime),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(conversation: conv),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSelectAdminDialog() async {
    try {
      final admins = await _fs.getAllAdmins();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Guru Ahli'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: admins.length,
              itemBuilder: (context, i) {
                final admin = admins[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SMColors.blue,
                    child: Text(
                      admin.username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(admin.username),
                  subtitle: Text(admin.email),
                  onTap: () async {
                    final conversation = await _fs.getOrCreateConversation(
                      _currentUser!.id,
                      admin.id,
                      _currentUser!.username,
                      admin.username,
                    );
                    if (!mounted) return;
                    
                    Navigator.pop(context);
                    
                    if (conversation != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(conversation: conversation),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}